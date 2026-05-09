// src/middleware/auth.js
// ─── Auth Middleware + RBAC ────────────────────────────────────────────────────
const jwt = require("jsonwebtoken");
const { pool } = require("../config/db");

// ── Token verification ─────────────────────────────────────────────────────────
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, message: "No token provided" });
    }
    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const [rows] = await pool.execute(
      "SELECT id, username, email, role, full_name_en, is_active, org_id FROM users WHERE id = ?",
      [decoded.id]
    );
    if (!rows.length || !rows[0].is_active) {
      return res.status(401).json({ success: false, message: "User not found or inactive" });
    }
    req.user = rows[0];
    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ success: false, message: "Token expired" });
    }
    return res.status(401).json({ success: false, message: "Invalid token" });
  }
};

// ── Role guards ────────────────────────────────────────────────────────────────

/** Admin OR Manager — can access dashboard stats, people list */
const requireAdmin = (req, res, next) => {
  if (!["admin", "manager"].includes(req.user.role)) {
    return res.status(403).json({ success: false, message: "Access denied" });
  }
  next();
};

/** Admin only — rooms, attendance records, settings, delete */
const requireSuperAdmin = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({
      success: false,
      message: "Admin access required. Managers cannot perform this action.",
    });
  }
  next();
};

/** Manager can only view/add people (GET+POST /api/users), not edit/delete */
const requireManagerOrAdmin = (req, res, next) => {
  if (!["admin", "manager"].includes(req.user.role)) {
    return res.status(403).json({ success: false, message: "Access denied" });
  }
  // Manager can only GET and POST — not PUT/PATCH/DELETE
  if (req.user.role === "manager" && !["GET", "POST"].includes(req.method)) {
    return res.status(403).json({
      success: false,
      message: "Managers can view and add people but cannot edit or delete.",
    });
  }
  next();
};

module.exports = { authenticate, requireAdmin, requireSuperAdmin, requireManagerOrAdmin };
