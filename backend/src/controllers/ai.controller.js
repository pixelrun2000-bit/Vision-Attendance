// src/controllers/ai.controller.js
// This is the BRIDGE between Node.js backend and Python face_app AI
const axios = require("axios");
const FormData = require("form-data");
const { pool } = require("../config/db");
const { createAndNotify } = require("../utils/notification.helper");
const { forwardToAI } = require("../utils/ai.helper");
const fs = require("fs");
const path = require("path");

const AI_BASE = process.env.AI_BASE_URL || "http://localhost:5000";

// POST /api/ai/recognize  ← Flutter face check-in
// Sends image to Python, saves attendance record, returns result
const recognize = async (req, res, next) => {
  console.log("DEBUG: /api/ai/recognize - Request received");
  try {
    if (!req.file) {
      console.log("DEBUG: /api/ai/recognize - No file in request");
      return res.status(400).json({ success: false, message: "Image file required" });
    }

    // 1. Get settings and threshold
    const [[settings]] = await pool.execute("SELECT * FROM settings WHERE id = 1");
    const threshold = settings?.face_recognition_threshold || 0.55;

    // 2. Identify User from Token (Security first)
    const userId = req.user?.id;
    const { lat, lng, room_id } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized: User session missing." });
    }

    // 3. Get User and Room Data from DB
    const [[user]] = await pool.execute("SELECT * FROM users WHERE id = ?", [userId]);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found." });
    }

    let room = null;
    if (room_id) {
      const [[foundRoom]] = await pool.execute("SELECT * FROM rooms WHERE id = ?", [room_id]);
      room = foundRoom;
    }

    // 4. Geofencing Check (Strict)
    if (room && lat && lng) {
      const distance = calculateDistance(parseFloat(lat), parseFloat(lng), room.latitude, room.longitude);
      const maxDistance = room.radius || 200;

      if (distance > maxDistance) {
        return res.status(403).json({
          success: false,
          message: `Location Error: You are ${Math.round(distance)}m away from "${room.name}". (Limit: ${maxDistance}m)`
        });
      }
    }

    // 5. Forward to Python AI for Identification
    const aiResult = await forwardToAI(
      "/api/v1/recognize",
      req.file.buffer,
      req.file.originalname,
      { threshold }
    );

    const aiData = aiResult.status === "success" ? aiResult.data : null;
    if (!aiData || !aiData.faces || aiData.faces.length === 0) {
      return res.status(422).json({
        success: false,
        message: aiResult.message || "No face detected. Please try again with better lighting."
      });
    }

    // 6. Identity Match Check
    console.log(`DEBUG: Matching for user_id=${user.id}, expected face_person_id=${user.face_person_id}`);
    
    // Log all detected faces for debugging
    aiData.faces.forEach((f, idx) => {
      console.log(`DEBUG: Face #${idx} - detected person_id=${f.person_id}, matched=${f.matched}, similarity=${f.similarity}`);
    });

    const matchedFace = aiData.faces.find(f => f.matched && f.person_id === user.face_person_id);
    if (!matchedFace) {
      console.log("DEBUG: No face matched the user's profile ID.");
      return res.status(401).json({
        success: false,
        message: "Identity Mismatch: The detected face does not match your profile."
      });
    }

    // 7. Security/Liveness Check
    const isLive = matchedFace.spoof?.is_live !== false && matchedFace.liveness?.is_live !== false;
    if (!isLive) {
      const failReason = matchedFace.spoof?.is_live === false ? "Spoofing detected" : "Liveness check failed";
      await pool.execute(
        "INSERT INTO attendance (user_id, room_id, method, status, failure_reason) VALUES (?, ?, 'face', 'failed', ?)",
        [user.id, room_id || null, failReason]
      );
      return res.status(403).json({ success: false, message: `Security Alert: ${failReason}.` });
    }

    // 8. Process Attendance (Check-in or Check-out)
    const [existing] = await pool.execute(
      "SELECT id, checkin_time FROM attendance WHERE user_id = ? AND DATE(checkin_time) = CURDATE() AND checkout_time IS NULL ORDER BY checkin_time DESC LIMIT 1",
      [user.id]
    );

    let type = "checkin";
    if (existing.length) {
      // Perform Check-out
      await pool.execute(
        "UPDATE attendance SET checkout_time = NOW(), ai_similarity = ? WHERE id = ?",
        [matchedFace.similarity, existing[0].id]
      );
      type = "checkout";
    } else {
      // Perform Check-in
      const isLate = new Date().getHours() >= 9; // Placeholder for late threshold
      await pool.execute(
        "INSERT INTO attendance (user_id, room_id, method, ai_matched, ai_similarity, status) VALUES (?, ?, 'face', 1, ?, ?)",
        [user.id, room_id || null, matchedFace.similarity, isLate ? "late" : "present"]
      );
    }

    // 9. Notifications & Socket Emit
    try {
      const io = req.app.get("io");
      io?.to(`user:${user.id}`).emit("attendance_update", { success: true, type });
      await createAndNotify(req.app, user.id, `Face ${type === 'checkin' ? 'Check-in' : 'Check-out'} Confirmed`, `Verified successfully via AI.`, "attendance");
    } catch (err) {
      console.error("Socket/Notify Error:", err);
    }

    res.json({
      success: true,
      message: `Attendance ${type} recorded successfully.`,
      type
    });

  } catch (err) {
    console.error("❌ Recognize Error:", err);
    res.status(500).json({ success: false, message: err.message || "Internal server error" });
  }
};

// POST /api/ai/enroll  ← React Dashboard (admin enrolls a user's face)
const enroll = async (req, res, next) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    const { user_id } = req.body;
    if (!user_id)
      return res.status(400).json({ success: false, message: "user_id required" });

    const [users] = await pool.execute("SELECT id, full_name_en FROM users WHERE id = ?", [user_id]);
    if (!users.length)
      return res.status(404).json({ success: false, message: "User not found" });

    const personId = `user_${user_id}`;

    // Forward to Python AI /enroll
    const aiResult = await forwardToAI(
      "/api/v1/enroll",
      req.file.buffer,
      req.file.originalname,
      { person_id: personId, name: users[0].full_name_en }
    );

    const isSuccess = aiResult.status === "success";
    if (isSuccess) {
      await pool.execute(
        "UPDATE users SET face_person_id = ?, is_face_enrolled = 1 WHERE id = ?",
        [personId, user_id]
      );
    }

    res.json({ 
      success: isSuccess, 
      person_id: personId, 
      ai_result: aiResult.data || aiResult,
      message: isSuccess ? "Enrolled successfully" : (aiResult.message || "AI Enrollment failed")
    });
  } catch (err) {
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable." });
    }
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/ai/enroll-self  ← Flutter (user enrolls their own face during onboarding)
const enrollSelf = async (req, res, next) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    const user_id = req.user.id;
    const [users] = await pool.execute("SELECT id, full_name_en, is_face_enrolled FROM users WHERE id = ?", [user_id]);
    
    if (!users.length)
      return res.status(404).json({ success: false, message: "User not found" });

    // Allow multiple enrollments (e.g. 3 photos) even if already partially enrolled
    // The mobile app will call this 3 times
    const personId = `user_${user_id}`;

    // Forward to Python AI /enroll
    const aiResult = await forwardToAI(
      "/api/v1/enroll",
      req.file.buffer,
      req.file.originalname,
      { person_id: personId, name: users[0].full_name_en }
    );

    const isSuccess = aiResult.status === "success";
    if (isSuccess) {
      // 1. Save photo locally to uploads/profiles so it can be seen in dashboard
      const uploadsDir = path.join(process.cwd(), "uploads", "profiles");
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
      
      const fileName = `user_${user_id}_enroll_${Date.now()}.jpg`;
      fs.writeFileSync(path.join(uploadsDir, fileName), req.file.buffer);
      const photoUrl = `/uploads/profiles/${fileName}`;

      // 2. Update DB with person_id and photo_url
      await pool.execute(
        "UPDATE users SET face_person_id = ?, is_face_enrolled = 1, photo_url = ? WHERE id = ?",
        [personId, photoUrl, user_id]
      );
    }

    res.json({ 
      success: isSuccess, 
      person_id: personId, 
      ai_result: aiResult.data || aiResult,
      message: isSuccess ? "Self-enrollment successful" : (aiResult.message || "AI Enrollment failed")
    });
  } catch (err) {
    console.error("❌ [ENROLL-SELF] Error:", err.stack || err);
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable." });
    }
    res.status(500).json({ 
      success: false, 
      message: err.message || "Internal server error in enrollment bridge" 
    });
  }
};

// Add enrollUserById (Admin function to enroll specific user by ID)
const enrollUserById = async (req, res, next) => {
  try {
    const userId = req.params.id;
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    const [users] = await pool.execute("SELECT id, full_name_en FROM users WHERE id = ?", [userId]);
    if (!users.length)
      return res.status(404).json({ success: false, message: "User not found" });

    // 1. Save photo locally
    const uploadsDir = path.join(process.cwd(), "uploads", "profiles");
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
    const fileName = `admin_enrolled_${userId}_${Date.now()}.jpg`;
    fs.writeFileSync(path.join(uploadsDir, fileName), req.file.buffer);
    const photoUrl = `/uploads/profiles/${fileName}`;

    const personId = `user_${userId}`;
    const aiResult = await forwardToAI(
      "/api/v1/enroll",
      req.file.buffer,
      req.file.originalname,
      { person_id: personId, name: users[0].full_name_en }
    );

    const isSuccess = aiResult.status === "success";
    if (isSuccess) {
      await pool.execute(
        "UPDATE users SET face_person_id = ?, is_face_enrolled = 1, photo_url = ? WHERE id = ?",
        [personId, photoUrl, userId]
      );
    }
    res.json({ 
      success: isSuccess, 
      ai_result: aiResult.data || aiResult,
      message: isSuccess ? "User enrolled successfully by admin" : (aiResult.message || "AI Enrollment failed")
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/ai/quality  ← Flutter (check image quality before capture)
const checkQuality = async (req, res, next) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    const aiResult = await forwardToAI("/api/v1/quality", req.file.buffer, req.file.originalname);
    res.json({ success: true, quality: aiResult });
  } catch (err) {
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable." });
    }
    next(err);
  }
};

// POST /api/ai/liveness  ← Flutter (liveness check)
const checkLiveness = async (req, res, next) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    const aiResult = await forwardToAI("/api/v1/liveness", req.file.buffer, req.file.originalname);
    res.json({ success: true, liveness: aiResult });
  } catch (err) {
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable." });
    }
    next(err);
  }
};

// GET /api/ai/status  ← health check for Python AI
const getAiStatus = async (req, res) => {
  try {
    const response = await axios.get(`${AI_BASE}/api/v1/health`, { timeout: 5000 });
    res.json({ success: true, ai_online: true, details: response.data });
  } catch {
    res.json({ success: true, ai_online: false, message: "face_app is not reachable" });
  }
};

/**
 * Calculates the Haversine distance between two points in meters
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ1) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
};

module.exports = { recognize, enroll, enrollSelf, enrollUserById, checkQuality, checkLiveness, getAiStatus };
