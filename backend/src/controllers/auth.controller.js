// src/controllers/auth.controller.js
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { pool } = require("../config/db");

const generateToken = (user) =>
  jwt.sign({ id: user.id, role: user.role, org_id: user.org_id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  });

// POST /api/auth/login  ← Flutter + React Dashboard
const login = async (req, res, next) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ success: false, message: "Username and password required" });

    const [rows] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone, password_hash,
              role, department, photo_url, face_person_id, is_face_enrolled, is_active, org_id
       FROM users WHERE username = ? OR email = ? LIMIT 1`,
      [username, username]
    );

    if (!rows.length)
      return res.status(401).json({ success: false, message: "Invalid credentials" });

    const user = rows[0];
    if (!user.is_active)
      return res.status(403).json({ success: false, message: "Account is deactivated" });

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match)
      return res.status(401).json({ success: false, message: "Invalid credentials" });

    const token = generateToken(user);
    delete user.password_hash;

    res.json({ success: true, token, user });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/register  ← Flutter mobile
const register = async (req, res, next) => {
  try {
    const {
      full_name_ar, full_name_en, username, email, phone,
      password, national_id, gender, date_of_birth, role, department, photo_url, plan
    } = req.body;

    if (!full_name_en || !username || !email || !password)
      return res.status(400).json({ success: false, message: "Required fields missing" });

    // Mobile app → only employee/student. Web register → admin/manager allowed.
    const ALLOWED_ROLES = ["employee", "student", "manager", "admin"];
    const safeRole = ALLOWED_ROLES.includes(role) ? role : "employee";
    const hash = await bcrypt.hash(password, 10);

    let org_id = req.user ? req.user.org_id : null; // If created by logged-in admin

    // If mobile user registers without auth, try to inherit org_id from department
    if (!org_id && department) {
      const [depRows] = await pool.execute(
        "SELECT org_id FROM users WHERE department = ? AND role IN ('admin', 'manager') AND org_id IS NOT NULL LIMIT 1",
        [department]
      );
      if (depRows.length > 0) org_id = depRows[0].org_id;
    }

    const [result] = await pool.execute(
      `INSERT INTO users (full_name_ar, full_name_en, username, email, phone,
        password_hash, national_id, gender, date_of_birth, role, department, photo_url, subscription_plan, org_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        full_name_ar || full_name_en, full_name_en, username, email, phone || null,
        hash, national_id || null, gender || null, date_of_birth || null,
        safeRole, department || null, photo_url || null, plan || 'Free', org_id
      ]
    );

    // If an Admin/Manager registers themselves (e.g. from the web), they create their own org.
    if (!org_id && ['admin', 'manager'].includes(safeRole)) {
      org_id = result.insertId;
      await pool.execute('UPDATE users SET org_id = ? WHERE id = ?', [org_id, result.insertId]);
    }

    const [newUser] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, employee_id, national_id, gender,
              date_of_birth, photo_url, is_face_enrolled, subscription_plan, org_id, created_at
       FROM users WHERE id = ?`,
      [result.insertId]
    );

    const token = generateToken(newUser[0]);

    // ── Notify web dashboard in real-time ────────────────────────────────────
    const io = req.app.get("io");
    if (io) io.emit("users:update", { action: "register", user: newUser[0] });

    res.status(201).json({ success: true, token, user: newUser[0] });
  } catch (err) {
    next(err);
  }
};

// GET /api/auth/me
const getMe = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, full_name_ar, full_name_en, username, email, phone,
              role, department, gender, date_of_birth, photo_url,
              is_face_enrolled, national_id, employee_id, subscription_plan, org_id, created_at
       FROM users WHERE id = ?`,
      [req.user.id]
    );
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/change-password
const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;
    const [rows] = await pool.execute(
      "SELECT password_hash FROM users WHERE id = ?",
      [req.user.id]
    );
    const match = await bcrypt.compare(current_password, rows[0].password_hash);
    if (!match)
      return res.status(400).json({ success: false, message: "Current password is incorrect" });

    const hash = await bcrypt.hash(new_password, 10);
    await pool.execute("UPDATE users SET password_hash = ? WHERE id = ?", [hash, req.user.id]);
    res.json({ success: true, message: "Password changed successfully" });
  } catch (err) {
    next(err);
  }
};

module.exports = { login, register, getMe, changePassword };
