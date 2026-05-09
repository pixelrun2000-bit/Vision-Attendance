// src/controllers/attendance.controller.js
// ─── Attendance Controller ─────────────────────────────────────────────────
// Handles check-in via:
//   1. Face recognition (AI pipeline)          → POST /api/attendance/checkin
//   2. Room code / QR token (mobile entry)     → POST /api/attendance/checkin-by-room
//   3. Checkout                                → POST /api/attendance/checkout
// Also: logs, today's status, admin delete
// ──────────────────────────────────────────────────────────────────────────
const { pool } = require("../config/db");

/* ─── helpers ────────────────────────────────────────────────────────────── */

/** Emit real-time attendance update to all WS clients */
function emitAttendanceUpdate(io, roomId) {
  if (!io || !roomId) return;
  io.emit("attendance:update", { room_id: roomId, timestamp: new Date().toISOString() });
}

/** Validate user GPS against room GPS (radius in metres) */
function gpsDistance(lat1, lon1, lat2, lon2) {
  const R = 6_371_000; // Earth radius in metres
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/* ─── GET /api/attendance ─────────────────────────────────────────────────── */
const getAttendance = async (req, res, next) => {
  try {
    const { user_id, room_id, date, status, page = 1, limit = 30 } = req.query;
    const offset = (page - 1) * limit;
    const where  = [];
    const params = [];

    if (user_id) { where.push("a.user_id = ?");            params.push(user_id); }
    if (room_id) { where.push("a.room_id = ?");            params.push(room_id); }
    if (date)    { where.push("DATE(a.checkin_time) = ?"); params.push(date); }
    if (status)  { where.push("a.status = ?");             params.push(status); }
    
    if (req.user && req.user.org_id) {
      where.push("u.org_id = ?");
      params.push(req.user.org_id);
    } else {
      where.push("u.org_id IS NULL");
    }

    const whereStr = where.length ? "WHERE " + where.join(" AND ") : "";

        const [records] = await pool.execute(
      `SELECT a.id, a.user_id, a.room_id, a.checkin_time, a.checkout_time,
              a.method, a.ai_matched, a.ai_similarity, a.status, a.failure_reason,
              a.ai_spoof_passed, a.ai_liveness_ok, a.ai_fraud_risk, a.ai_quality_grade,
              u.full_name_en, u.full_name_ar, u.department, u.role, u.photo_url,
              r.name AS room_name, r.room_code
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       LEFT JOIN rooms r ON a.room_id = r.id
       ${whereStr}
       ORDER BY a.checkin_time DESC LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), parseInt(offset)]
    );

    const [[{ total }]] = await pool.execute(
      `SELECT COUNT(*) AS total FROM attendance a ${whereStr}`,
      params
    );

    res.json({ success: true, records, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/attendance/my-logs ─────────────────────────────────────────── */
const getMyLogs = async (req, res, next) => {
  try {
    const { month } = req.query;
    const monthFilter = month || new Date().toISOString().slice(0, 7);

    const [records] = await pool.execute(
      `SELECT a.id, a.checkin_time, a.checkout_time, a.method, a.status, a.failure_reason,
              a.ai_similarity, r.name AS room_name, r.room_code
       FROM attendance a
       LEFT JOIN rooms r ON a.room_id = r.id
       WHERE a.user_id = ? AND DATE_FORMAT(a.checkin_time, '%Y-%m') = ?
       ORDER BY a.checkin_time DESC`,
      [req.user.id, monthFilter]
    );

    const [[summary]] = await pool.execute(
      `SELECT
         COUNT(*) AS total_days,
         SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) AS present,
         SUM(CASE WHEN status='late'    THEN 1 ELSE 0 END) AS late,
         SUM(CASE WHEN status='absent'  THEN 1 ELSE 0 END) AS absent
       FROM attendance WHERE user_id = ? AND DATE_FORMAT(checkin_time,'%Y-%m') = ?`,
      [req.user.id, monthFilter]
    );

    res.json({ success: true, month: monthFilter, records, summary });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/attendance/today ───────────────────────────────────────────── */
const getTodayStatus = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT a.id, a.checkin_time, a.checkout_time, a.status,
              r.name AS room_name, r.room_code
       FROM attendance a
       LEFT JOIN rooms r ON a.room_id = r.id
       WHERE a.user_id = ? AND DATE(a.checkin_time) = CURDATE()
       ORDER BY a.checkin_time DESC LIMIT 1`,
      [req.user.id]
    );

    res.json({
      success: true,
      today: rows[0] || null,
      is_checked_in: rows.length > 0 && !rows[0].checkout_time,
    });
  } catch (err) {
    next(err);
  }
};

/* ─── POST /api/attendance/checkin-by-room ───────────────────────────────── */
/**
 * Room-code / QR check-in (used by mobile app).
 *
 * Body (JSON):
 *   room_code  {string}  — either the short "RM-001" code OR the UUID qr_token
 *   user_lat   {number}  — user's GPS latitude  (optional but recommended)
 *   user_lng   {number}  — user's GPS longitude (optional but recommended)
 *   gps_radius {number}  — allowed radius in metres (default: 200)
 *
 * Flow:
 *   1. Look up the room by room_code OR qr_token
 *   2. GPS distance check (if room has GPS set AND user sent coords)
 *   3. Prevent double check-in on same day
 *   4. Insert attendance record
 *   5. Emit real-time WS event
 */
const checkinByRoom = async (req, res, next) => {
  try {
    const { room_code, user_lat, user_lng, gps_radius = 200, is_failed, failure_reason } = req.body;
    const userId = req.user.id;

    if (!room_code) {
      return res.status(400).json({ success: false, message: "room_code is required" });
    }

    // ── 1. Find room ──────────────────────────────────────────────────────────
    const [rooms] = await pool.execute(
      "SELECT * FROM rooms WHERE (room_code = ? OR qr_token = ?) AND is_active = 1 LIMIT 1",
      [room_code, room_code]
    );
    if (!rooms.length) {
      return res.status(404).json({ success: false, message: "Room not found for this code" });
    }
    const room = rooms[0];

    // ── 2. GPS check ──────────────────────────────────────────────────────────
    if (room.latitude && room.longitude && user_lat && user_lng) {
      const dist = gpsDistance(
        parseFloat(user_lat), parseFloat(user_lng),
        parseFloat(room.latitude), parseFloat(room.longitude)
      );
      if (dist > gps_radius) {
        return res.status(403).json({
          success: false,
          message: `You are ${Math.round(dist)}m from the room. Must be within ${gps_radius}m.`,
          distance_m: Math.round(dist),
          allowed_radius_m: gps_radius,
        });
      }
    }

    // ── 3. Duplicate check ────────────────────────────────────────────────────
    const [existing] = await pool.execute(
      `SELECT id FROM attendance
       WHERE user_id = ? AND room_id = ? AND DATE(checkin_time) = CURDATE() AND checkout_time IS NULL
       LIMIT 1`,
      [userId, room.id]
    );
    if (existing.length) {
      return res.status(409).json({
        success: false,
        message: "Already checked in to this room today",
        attendance_id: existing[0].id,
      });
    }

    // ── 4. Determine status ───────────────────────────────────────────────────
    let status = "present";
    if (is_failed) {
      status = "failed";
    } else {
      const nowHour = new Date().getHours();
      status = nowHour >= 9 ? "late" : "present";   // 09:00 cutoff
    }

    // ── 5. Insert ─────────────────────────────────────────────────────────────
    const [result] = await pool.execute(
      `INSERT INTO attendance (user_id, room_id, method, status, failure_reason)
       VALUES (?, ?, 'qr_code', ?, ?)`,
      [userId, room.id, status, failure_reason || null]
    );

    // ── 6. Fetch inserted record ──────────────────────────────────────────────
    const [[record]] = await pool.execute(
      `SELECT a.*, r.name AS room_name, r.room_code,
              u.full_name_en, u.employee_id
       FROM attendance a
       JOIN rooms r ON r.id = a.room_id
       JOIN users u ON u.id = a.user_id
       WHERE a.id = ?`,
      [result.insertId]
    );

    // ── 7. Real-time push ─────────────────────────────────────────────────────
    const io = req.app.get("io");
    emitAttendanceUpdate(io, room.id);

    if (is_failed) {
      return res.status(201).json({ success: false, message: "Check-in failed recorded", attendance: record });
    }

    res.status(201).json({ success: true, attendance: record });
  } catch (err) {
    next(err);
  }
};

/* ─── POST /api/attendance/checkout ──────────────────────────────────────── */
const checkout = async (req, res, next) => {
  try {
    const { attendance_id } = req.body;
    const userId = req.user.id;

    const [rows] = await pool.execute(
      "SELECT * FROM attendance WHERE id = ? AND user_id = ? AND checkout_time IS NULL",
      [attendance_id, userId]
    );
    if (!rows.length) {
      return res.status(404).json({ success: false, message: "Active attendance record not found" });
    }

    await pool.execute(
      "UPDATE attendance SET checkout_time = NOW() WHERE id = ?",
      [attendance_id]
    );

    const io = req.app.get("io");
    emitAttendanceUpdate(io, rows[0].room_id);

    res.json({ success: true, message: "Checked out successfully", checked_out_at: new Date().toISOString() });
  } catch (err) {
    next(err);
  }
};

/* ─── DELETE /api/attendance/:id ─────────────────────────────────────────── */
const deleteRecord = async (req, res, next) => {
  try {
    await pool.execute("DELETE FROM attendance WHERE id = ?", [req.params.id]);
    res.json({ success: true, message: "Record deleted" });
  } catch (err) {
    next(err);
  }
};

module.exports = { getAttendance, getMyLogs, getTodayStatus, checkinByRoom, checkout, deleteRecord };
