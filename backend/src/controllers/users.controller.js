// src/controllers/users.controller.js
const bcrypt = require("bcryptjs");
const { pool } = require("../config/db");
const fs = require("fs");
const path = require("path");

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

    if (!full_name_en || !username || !email || !password)
      return res.status(400).json({ success: false, message: "Required fields missing" });

    const hash = await bcrypt.hash(password || "changeme123", 10);
    const org_id = req.user ? req.user.org_id : null;

    const [result] = await pool.execute(
      `INSERT INTO users (full_name_ar, full_name_en, username, email, phone,
        password_hash, national_id, employee_id, gender, date_of_birth, role, department, org_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        full_name_ar || full_name_en, full_name_en, username, email, phone || null,
        hash, national_id || null, employee_id || null, gender || null,
        date_of_birth || null, role || "employee", department || null, org_id
      ]
    );

    const [newUser] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, employee_id, is_face_enrolled, photo_url, created_at
       FROM users WHERE id = ?`,
      [result.insertId]
    );

    // Real-time: broadcast to all web clients so the People list refreshes
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
