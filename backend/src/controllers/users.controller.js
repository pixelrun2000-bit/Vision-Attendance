// src/controllers/users.controller.js
const bcrypt = require("bcryptjs");
const { pool } = require("../config/db");
const fs = require("fs");
const path = require("path");
const { createAndNotify } = require("../utils/notification.helper");
const { sendWelcomeEmail } = require("../utils/email.helper");
const { forwardToAI } = require("../utils/ai.helper");

// GET /api/users  ← React Dashboard (list all people)
const getUsers = async (req, res, next) => {
  try {
    const { role, department, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    let where = ["is_active = 1"];
    const params = [];

    // ── Multi-tenant Isolation ──
    if (req.user && req.user.org_id) {
      where.push("org_id = ?");
      params.push(req.user.org_id);
    } else {
      where.push("org_id IS NULL");
    }

    if (role) { where.push("role = ?"); params.push(role); }
    if (department) { where.push("department = ?"); params.push(department); }
    if (search) {
      where.push("(full_name_en LIKE ? OR email LIKE ? OR username LIKE ?)");
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    const whereStr = where.length ? "WHERE " + where.join(" AND ") : "";

    const [users] = await pool.query(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, employee_id, is_face_enrolled, photo_url, created_at
       FROM users ${whereStr}
       ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), parseInt(offset)]
    );

    const [[{ total }]] = await pool.execute(
      `SELECT COUNT(*) as total FROM users ${whereStr}`,
      params
    );

    res.json({ success: true, users, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    next(err);
  }
};

// GET /api/users/:id
const getUserById = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, employee_id, national_id, gender,
              date_of_birth, photo_url, is_face_enrolled, face_person_id, created_at
       FROM users WHERE id = ? AND is_active = 1`,
      [req.params.id]
    );
    if (!rows.length)
      return res.status(404).json({ success: false, message: "User not found" });
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    next(err);
  }
};

// POST /api/users  ← React Dashboard (admin adds person)
const createUser = async (req, res, next) => {
  try {
    const {
      full_name_ar, full_name_en, username, email, phone,
      password, national_id, employee_id, gender, date_of_birth,
      role, department,
    } = req.body;

    console.log("Create User Request Body:", req.body);
    console.log("Create User Request File:", req.file ? "Uploaded" : "No File");

    const final_full_name = (full_name_en || "").trim();
    const final_email = (email || "").trim();
    const final_username = (username || "").trim() || (final_full_name.toLowerCase().replace(/\s+/g, '.') + '.' + Date.now().toString().slice(-4));
    const final_password = (password || "").trim() || "Vision@123";

    if (!final_full_name || !final_email) {
      return res.status(400).json({ 
        success: false, 
        message: `Required fields missing: ${!final_full_name ? 'Full Name' : ''} ${!final_email ? 'Email' : ''}`.trim()
      });
    }

    const hash = await bcrypt.hash(final_password, 10);
    const org_id = req.user ? req.user.org_id : null;

    let photo_url = null;
    let is_face_enrolled = 0;
    let face_person_id = null;

    // Handle photo upload
    if (req.file) {
      const uploadsDir = path.join(process.cwd(), "uploads", "profiles");
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
      
      const fileName = `user_new_${Date.now()}_${req.file.originalname}`;
      const absolutePath = path.join(uploadsDir, fileName);
      fs.writeFileSync(absolutePath, req.file.buffer);
      photo_url = `/uploads/profiles/${fileName}`;
    }

    const [result] = await pool.execute(
      `INSERT INTO users (full_name_ar, full_name_en, username, email, phone,
        password_hash, national_id, employee_id, gender, date_of_birth, role, department, org_id, photo_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        full_name_ar || final_full_name, final_full_name, final_username, final_email, phone || null,
        hash, national_id || null, employee_id || null, gender || null,
        date_of_birth || null, role || "employee", department || null, org_id, photo_url
      ]
    );

    const userId = result.insertId;
    face_person_id = `user_${userId}`;

    // If photo uploaded -> Enroll in AI service
    if (req.file) {
      try {
        const aiResult = await forwardToAI(
          "/api/v1/enroll",
          req.file.buffer,
          req.file.originalname,
          { person_id: face_person_id, name: full_name_en }
        );
        if (aiResult.success) {
          is_face_enrolled = 1;
          await pool.execute(
            "UPDATE users SET face_person_id = ?, is_face_enrolled = 1 WHERE id = ?",
            [face_person_id, userId]
          );
        }
      } catch (aiErr) {
        console.error("Auto AI Enrollment failed:", aiErr.message);
      }
    }

    const [newUser] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, employee_id, is_face_enrolled, photo_url, created_at
       FROM users WHERE id = ?`,
      [result.insertId]
    );

    // ── Real-time & Email ────────────────────────────────────────────────────
    const adminName = req.user?.full_name_en || "System Admin";
    
    // 1. Send Real-time Notification
    await createAndNotify(
      req.app,
      result.insertId,
      `مرحباً بك في منظمة ${adminName}`,
      `تم إنشاء حسابك بنجاح. الأدمن المسؤول: ${adminName}. كلمة المرور الافتراضية هي Vision@123`,
      "system"
    );

    // 2. Send Welcome Email
    await sendWelcomeEmail(email, full_name_en, username, password || "Vision@123", adminName);

    // 3. Broadcast to web dashboard (for the list to refresh)
    const io = req.app.get("io");
    if (io) io.emit("users:update", { user: newUser[0], timestamp: new Date().toISOString() });

    res.status(201).json({ success: true, user: newUser[0] });
  } catch (err) {
    next(err);
  }
};

// PUT /api/users/:id  ← React Dashboard (edit person)
const updateUser = async (req, res, next) => {
  try {
    const { full_name_ar, full_name_en, email, phone, department, role, employee_id } = req.body;

    await pool.execute(
      `UPDATE users SET full_name_ar=?, full_name_en=?, email=?, phone=?,
              department=?, role=?, employee_id=? WHERE id=?`,
      [
        full_name_ar, full_name_en, email, phone || null,
        department || null, role, employee_id || null, req.params.id,
      ]
    );

    const [updated] = await pool.execute(
      "SELECT id, full_name_ar, full_name_en, email, phone, department, role, employee_id FROM users WHERE id=?",
      [req.params.id]
    );

    res.json({ success: true, user: updated[0] });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/users/:id  ← soft delete
const deleteUser = async (req, res, next) => {
  try {
    await pool.execute("UPDATE users SET is_active = 0 WHERE id = ?", [req.params.id]);
    res.json({ success: true, message: "User deactivated successfully" });
  } catch (err) {
    next(err);
  }
};

// GET /api/users/:id/attendance-summary  ← Flutter profile screen
const getUserAttendanceSummary = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const month = req.query.month || new Date().toISOString().slice(0, 7); // YYYY-MM

    const [[summary]] = await pool.execute(
      `SELECT
         COUNT(*) as total_days,
         SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
         SUM(CASE WHEN status = 'late'    THEN 1 ELSE 0 END) as late,
         SUM(CASE WHEN status = 'absent'  THEN 1 ELSE 0 END) as absent,
         AVG(ai_similarity) as avg_confidence
       FROM attendance
       WHERE user_id = ? AND DATE_FORMAT(checkin_time, '%Y-%m') = ?`,
      [userId, month]
    );

    res.json({ success: true, month, summary });
  } catch (err) {
    next(err);
  }
};

// PUT /api/users/me/profile
const updateMyProfile = async (req, res, next) => {
  try {
    const { full_name_ar, full_name_en, phone, gender, date_of_birth, photo_url } = req.body;
    await pool.execute(
      `UPDATE users
       SET full_name_ar = COALESCE(?, full_name_ar),
           full_name_en = COALESCE(?, full_name_en),
           phone = COALESCE(?, phone),
           gender = COALESCE(?, gender),
           date_of_birth = COALESCE(?, date_of_birth),
           photo_url = COALESCE(?, photo_url)
       WHERE id = ?`,
      [full_name_ar, full_name_en, phone, gender, date_of_birth, photo_url, req.user.id]
    );
    const [rows] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, gender, date_of_birth, photo_url
       FROM users WHERE id = ?`,
      [req.user.id]
    );
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    next(err);
  }
};

// POST /api/users/me/profile-photo
const uploadMyProfilePhoto = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "Image file required" });
    }
    const uploadsDir = path.join(process.cwd(), "uploads", "profiles");
    fs.mkdirSync(uploadsDir, { recursive: true });
    const extension = (req.file.originalname.split(".").pop() || "jpg").toLowerCase();
    const fileName = `user_${req.user.id}_${Date.now()}.${extension}`;
    const absolutePath = path.join(uploadsDir, fileName);
    fs.writeFileSync(absolutePath, req.file.buffer);
    const photoPath = `/uploads/profiles/${fileName}`;
    await pool.execute("UPDATE users SET photo_url = ? WHERE id = ?", [photoPath, req.user.id]);
    res.json({ success: true, photo_url: photoPath });
  } catch (err) {
    next(err);
  }
};

// POST /api/users/me/location
const upsertMyLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;
    if (typeof latitude !== "number" || typeof longitude !== "number") {
      return res.status(400).json({ success: false, message: "latitude and longitude must be numbers" });
    }
    await pool.execute(
      `INSERT INTO user_locations (user_id, latitude, longitude, captured_at)
       VALUES (?, ?, ?, NOW())`,
      [req.user.id, latitude, longitude]
    );
    res.json({ success: true, message: "Location saved" });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getUserAttendanceSummary,
  updateMyProfile,
  uploadMyProfilePhoto,
  upsertMyLocation,
};
