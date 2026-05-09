// src/controllers/settings.controller.js
const bcrypt = require("bcryptjs");
const { pool } = require("../config/db");

// GET /api/settings  ← React Dashboard
const getSettings = async (req, res, next) => {
  try {
    const [[settings]] = await pool.execute("SELECT * FROM settings WHERE id = 1");
    res.json({ success: true, settings });
  } catch (err) {
    next(err);
  }
};

// PUT /api/settings  ← React Dashboard (save settings)
const updateSettings = async (req, res, next) => {
  try {
    const {
      attendance_method, discount_enabled, discount_category,
      discount_percentage, face_recognition_threshold,
    } = req.body;

    await pool.execute(
      `UPDATE settings SET
         attendance_method = ?,
         discount_enabled = ?,
         discount_category = ?,
         discount_percentage = ?,
         face_recognition_threshold = ?
       WHERE id = 1`,
      [
        attendance_method || "face",
        discount_enabled ? 1 : 0,
        discount_category || "both",
        discount_percentage || 10,
        face_recognition_threshold || 0.60,
      ]
    );

    const [[updated]] = await pool.execute("SELECT * FROM settings WHERE id = 1");
    res.json({ success: true, settings: updated });
  } catch (err) {
    next(err);
  }
};

// PUT /api/settings/profile  ← React Dashboard admin profile
const updateAdminProfile = async (req, res, next) => {
  try {
    const { full_name_en, full_name_ar, email, phone, organization } = req.body;

    await pool.execute(
      "UPDATE users SET full_name_en=?, full_name_ar=?, email=?, phone=? WHERE id=?",
      [full_name_en, full_name_ar || full_name_en, email, phone || null, req.user.id]
    );

    const [[user]] = await pool.execute(
      "SELECT id, full_name_en, full_name_ar, email, phone, role FROM users WHERE id=?",
      [req.user.id]
    );

    res.json({ success: true, user });
  } catch (err) {
    next(err);
  }
};

module.exports = { getSettings, updateSettings, updateAdminProfile };
