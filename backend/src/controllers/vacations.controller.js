// src/controllers/vacations.controller.js
const { pool } = require("../config/db");
const { createAndNotify } = require("../utils/notification.helper");

// GET /api/vacations  ← React Dashboard (all requests)
const getVacations = async (req, res, next) => {
  try {
    const { status, user_id, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const where = [];
    const params = [];

    if (status)  { where.push("v.status = ?");   params.push(status); }
    if (user_id) { where.push("v.user_id = ?");  params.push(user_id); }

    const whereStr = where.length ? "WHERE " + where.join(" AND ") : "";

    const [vacations] = await pool.execute(
      `SELECT v.*, u.full_name_en, u.full_name_ar, u.department, u.role,
              r.full_name_en as reviewer_name
       FROM vacation_requests v
       JOIN users u ON v.user_id = u.id
       LEFT JOIN users r ON v.reviewed_by = r.id
       ${whereStr}
       ORDER BY v.created_at DESC LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), parseInt(offset)]
    );

    const [[{ total }]] = await pool.execute(
      `SELECT COUNT(*) as total FROM vacation_requests v ${whereStr}`,
      params
    );

    res.json({ success: true, vacations, total, page: parseInt(page) });
  } catch (err) {
    next(err);
  }
};

// GET /api/vacations/my-requests  ← Flutter (current user)
const getMyVacations = async (req, res, next) => {
  try {
    const [vacations] = await pool.execute(
      `SELECT v.*, r.full_name_en as reviewer_name
       FROM vacation_requests v
       LEFT JOIN users r ON v.reviewed_by = r.id
       WHERE v.user_id = ?
       ORDER BY v.created_at DESC`,
      [req.user.id]
    );
    res.json({ success: true, vacations });
  } catch (err) {
    next(err);
  }
};

// POST /api/vacations  ← Flutter (submit request)
const createVacation = async (req, res, next) => {
  try {
    if (req.user.role === "student") {
      return res.status(403).json({
        success: false,
        message: "Students are not allowed to create vacation requests.",
      });
    }

    const { type, start_date, end_date, reason } = req.body;
    if (!type || !start_date || !end_date)
      return res.status(400).json({ success: false, message: "type, start_date, end_date are required" });

    const start = new Date(start_date);
    const end = new Date(end_date);
    const days_count = Math.ceil((end - start) / (1000 * 60 * 60 * 24)) + 1;

    const [result] = await pool.execute(
      `INSERT INTO vacation_requests (user_id, type, start_date, end_date, days_count, reason)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.user.id, type, start_date, end_date, days_count, reason || null]
    );

    // Notify admins
    const [admins] = await pool.execute("SELECT id FROM users WHERE role IN ('admin','manager') AND is_active=1");
    const io = req.app.get("io");
    for (const admin of admins) {
      await createAndNotify(
        req.app,
        admin.id,
        "New Vacation Request",
        `${req.user.full_name_en} submitted a ${type} vacation request`,
        "vacation"
      );
      // Emit real-time event for the dashboard/admin
      if (io) io.to(`user:${admin.id}`).emit("vacation:new", { user_id: req.user.id });
    }

    const [newReq] = await pool.execute("SELECT * FROM vacation_requests WHERE id = ?", [result.insertId]);
    res.status(201).json({ success: true, vacation: newReq[0] });
  } catch (err) {
    next(err);
  }
};

// PUT /api/vacations/:id/review  ← React Dashboard (approve/reject)
const reviewVacation = async (req, res, next) => {
  try {
    const { status, review_notes } = req.body;
    if (!["approved", "rejected"].includes(status))
      return res.status(400).json({ success: false, message: "status must be 'approved' or 'rejected'" });

    const [existing] = await pool.execute("SELECT * FROM vacation_requests WHERE id = ?", [req.params.id]);
    if (!existing.length)
      return res.status(404).json({ success: false, message: "Vacation request not found" });

    await pool.execute(
      `UPDATE vacation_requests SET status=?, reviewed_by=?, reviewed_at=NOW(), review_notes=? WHERE id=?`,
      [status, req.user.id, review_notes || null, req.params.id]
    );

    // Notify the employee
    await createAndNotify(
      req.app,
      existing[0].user_id,
      `Vacation Request ${status.charAt(0).toUpperCase() + status.slice(1)}`,
      `Your vacation request from ${existing[0].start_date} to ${existing[0].end_date} has been ${status}.`,
      "vacation"
    );

    // Emit real-time event for the user
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${existing[0].user_id}`).emit("vacation:update", { status });
      // Also notify admins if any dashboard is open
      io.emit("vacation:refresh", { id: req.params.id }); 
    }

    const [updated] = await pool.execute("SELECT * FROM vacation_requests WHERE id = ?", [req.params.id]);
    res.json({ success: true, vacation: updated[0] });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/vacations/:id  ← Flutter (cancel pending request)
const cancelVacation = async (req, res, next) => {
  try {
    if (req.user.role === "student") {
      return res.status(403).json({
        success: false,
        message: "Students are not allowed to manage vacation requests.",
      });
    }

    const [rows] = await pool.execute(
      "SELECT * FROM vacation_requests WHERE id = ? AND user_id = ?",
      [req.params.id, req.user.id]
    );
    if (!rows.length)
      return res.status(404).json({ success: false, message: "Request not found" });
    if (rows[0].status !== "pending")
      return res.status(400).json({ success: false, message: "Cannot cancel a reviewed request" });

    await pool.execute("DELETE FROM vacation_requests WHERE id = ?", [req.params.id]);
    res.json({ success: true, message: "Request cancelled" });
  } catch (err) {
    next(err);
  }
};

module.exports = { getVacations, getMyVacations, createVacation, reviewVacation, cancelVacation };
