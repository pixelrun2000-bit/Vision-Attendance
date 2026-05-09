// src/controllers/ai.controller.js
// This is the BRIDGE between Node.js backend and Python face_app AI
const axios = require("axios");
const FormData = require("form-data");
const { pool } = require("../config/db");

const AI_BASE = process.env.AI_BASE_URL || "http://localhost:5000";

// ── Helper: forward image buffer to Python AI ─────────────────────────────────
const forwardToAI = async (endpoint, imageBuffer, originalname, extraFields = {}) => {
  const form = new FormData();
  form.append("image", imageBuffer, { filename: originalname || "frame.jpg", contentType: "image/jpeg" });
  Object.entries(extraFields).forEach(([k, v]) => form.append(k, String(v)));

  const response = await axios.post(`${AI_BASE}${endpoint}`, form, {
    headers: form.getHeaders(),
    timeout: 30000,
  });
  return response.data;
};

// POST /api/ai/recognize  ← Flutter face check-in
// Sends image to Python, saves attendance record, returns result
const recognize = async (req, res, next) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: "Image file required" });

    // Get settings for threshold
    const [[settings]] = await pool.execute("SELECT * FROM settings WHERE id = 1");
    const threshold = settings?.face_recognition_threshold || 0.60;

    // Forward to Python AI
    const aiResult = await forwardToAI(
      "/api/v1/recognize",
      req.file.buffer,
      req.file.originalname,
      { threshold }
    );

    // If matched → find user by face_person_id and log attendance
    let attendanceRecord = null;
    if (aiResult.matched && aiResult.person_id) {
      const [users] = await pool.execute(
        "SELECT id, full_name_en, full_name_ar, department, role FROM users WHERE face_person_id = ? AND is_active = 1",
        [aiResult.person_id]
      );

      if (users.length) {
        const user = users[0];
        const room_id = req.body.room_id || null;

        // Check if already checked in today (no checkout yet)
        const [existing] = await pool.execute(
          `SELECT id, checkin_time FROM attendance
           WHERE user_id = ? AND DATE(checkin_time) = CURDATE() AND checkout_time IS NULL
           ORDER BY checkin_time DESC LIMIT 1`,
          [user.id]
        );

        if (existing.length) {
          // → Checkout
          await pool.execute(
            "UPDATE attendance SET checkout_time = NOW(), ai_similarity = ? WHERE id = ?",
            [aiResult.similarity || 0, existing[0].id]
          );
          attendanceRecord = { type: "checkout", user, checkin_time: existing[0].checkin_time };
        } else {
          // → Check-in
          const isLate = new Date().getHours() >= 9; // customize your late threshold
          const [ins] = await pool.execute(
            `INSERT INTO attendance
               (user_id, room_id, method, ai_matched, ai_similarity,
                ai_spoof_passed, ai_liveness_ok, ai_fraud_risk, ai_quality_grade, status)
             VALUES (?, ?, 'face', 1, ?, ?, ?, ?, ?, ?)`,
            [
              user.id, room_id,
              aiResult.similarity || 0,
              aiResult.spoof_passed ? 1 : 0,
              aiResult.liveness_ok ? 1 : 0,
              aiResult.fraud_risk || 0,
              aiResult.quality_grade || "good",
              isLate ? "late" : "present",
            ]
          );
          attendanceRecord = { type: "checkin", id: ins.insertId, user, status: isLate ? "late" : "present" };

          // Create notification for late check-in
          if (isLate) {
            await pool.execute(
              "INSERT INTO notifications (user_id, title, body, type) VALUES (?, ?, ?, 'attendance')",
              [user.id, "Late Check-in", `You checked in late today at ${new Date().toLocaleTimeString()}`]
            );
          }
        }
      }
    }

    res.json({
      success: true,
      ai_result: aiResult,
      attendance: attendanceRecord,
    });
  } catch (err) {
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable. Make sure face_app is running on port 5000." });
    }
    next(err);
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

    if (aiResult.success) {
      await pool.execute(
        "UPDATE users SET face_person_id = ?, is_face_enrolled = 1 WHERE id = ?",
        [personId, user_id]
      );
    }

    res.json({ success: aiResult.success, person_id: personId, ai_result: aiResult });
  } catch (err) {
    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({ success: false, message: "AI service is unavailable." });
    }
    next(err);
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
    const response = await axios.get(`${AI_BASE}/health`, { timeout: 5000 });
    res.json({ success: true, ai_online: true, details: response.data });
  } catch {
    res.json({ success: true, ai_online: false, message: "face_app is not reachable" });
  }
};

module.exports = { recognize, enroll, checkQuality, checkLiveness, getAiStatus };
