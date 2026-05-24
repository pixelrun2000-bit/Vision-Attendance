// src/controllers/rooms.controller.js
const { pool } = require("../config/db");
const { v4: uuidv4 } = require("uuid");

/* ─── helpers ────────────────────────────────────────────────────────────── */

/** Generate a short human-readable room code: RM-001, RM-002 … */
async function generateRoomCode() {
  const [[{ maxCode }]] = await pool.execute(
    "SELECT MAX(CAST(SUBSTRING(room_code, 4) AS UNSIGNED)) AS maxCode FROM rooms WHERE room_code LIKE 'RM-%'"
  );
  const next = (maxCode || 0) + 1;
  return `RM-${String(next).padStart(3, "0")}`;
}

/** Emit a real-time rooms-list update to all connected clients */
function emitRoomsUpdate(io) {
  if (!io) return;
  pool
    .execute(
      `SELECT r.id, r.name, r.description, r.capacity, r.room_code, r.qr_token,
              r.latitude, r.longitude, r.created_at,
              COUNT(a.id) AS current_occupancy
       FROM rooms r
       LEFT JOIN attendance a
         ON a.room_id = r.id AND DATE(a.checkin_time) = CURDATE()
            AND a.checkout_time IS NULL
       WHERE r.is_active = 1
       GROUP BY r.id
       ORDER BY r.name ASC`
    )
    .then(([rows]) => {
      io.emit("rooms:update", { rooms: rows, timestamp: new Date().toISOString() });
    })
    .catch(() => {});
}

/* ─── GET /api/rooms ─────────────────────────────────────────────────────── */
const getRooms = async (req, res, next) => {
  try {
    const orgId = req.user ? req.user.org_id : null;
    const [rooms] = await pool.execute(
      `SELECT r.id, r.name, r.description, r.capacity, r.room_code, r.qr_token,
              r.latitude, r.longitude, r.created_at,
              COUNT(a.id) AS current_occupancy
       FROM rooms r
       LEFT JOIN attendance a
         ON a.room_id = r.id AND DATE(a.checkin_time) = CURDATE()
            AND a.checkout_time IS NULL
       WHERE r.is_active = 1 AND (r.org_id = ? OR (? IS NULL AND r.org_id IS NULL))
       GROUP BY r.id
       ORDER BY r.name ASC`,
      [orgId, orgId]
    );
    res.json({ success: true, rooms });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/rooms/:id ─────────────────────────────────────────────────── */
const getRoomById = async (req, res, next) => {
  try {
    const orgId = req.user ? req.user.org_id : null;
    const [rows] = await pool.execute(
      `SELECT r.*, COUNT(a.id) AS current_occupancy
       FROM rooms r
       LEFT JOIN attendance a
         ON a.room_id = r.id AND DATE(a.checkin_time) = CURDATE()
            AND a.checkout_time IS NULL
       WHERE r.id = ? AND r.is_active = 1 AND (r.org_id = ? OR (? IS NULL AND r.org_id IS NULL))
       GROUP BY r.id`,
      [req.params.id, orgId, orgId]
    );
    if (!rows.length)
      return res.status(404).json({ success: false, message: "Room not found" });
    res.json({ success: true, room: rows[0] });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/rooms/by-code/:code ──────────────────────────────────────── */
/** Used by mobile: look up a room by its short room_code (from QR / manual entry) */
const getRoomByCode = async (req, res, next) => {
  try {
    // Note: Mobile might not have req.user depending on authentication
    const orgId = req.user ? req.user.org_id : null;
    const [rows] = await pool.execute(
      `SELECT r.*, COUNT(a.id) AS current_occupancy
       FROM rooms r
       LEFT JOIN attendance a
         ON a.room_id = r.id AND DATE(a.checkin_time) = CURDATE()
            AND a.checkout_time IS NULL
       WHERE (r.room_code = ? OR r.qr_token = ?) AND r.is_active = 1 
         AND (r.org_id = ? OR (? IS NULL AND r.org_id IS NULL))
       GROUP BY r.id`,
      [req.params.code, req.params.code, orgId, orgId]
    );
    if (!rows.length)
      return res.status(404).json({ success: false, message: "Room not found for this code" });
    res.json({ success: true, room: rows[0] });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/rooms/:id/live ────────────────────────────────────────────── */
/** Real-time attendees list currently inside this room today */
const getRoomLive = async (req, res, next) => {
  try {
    const orgId = req.user ? req.user.org_id : null;
    const [attendees] = await pool.execute(
      `SELECT a.id AS attendance_id, u.id AS user_id,
              u.full_name_en, u.full_name_ar, u.employee_id,
              u.photo_url, a.checkin_time, a.status
       FROM attendance a
       JOIN users u ON u.id = a.user_id
       JOIN rooms r ON r.id = a.room_id
       WHERE a.room_id = ?
         AND DATE(a.checkin_time) = CURDATE()
         AND a.checkout_time IS NULL
         AND (r.org_id = ? OR (? IS NULL AND r.org_id IS NULL))
       ORDER BY a.checkin_time DESC`,
      [req.params.id, orgId, orgId]
    );
    res.json({
      success: true,
      room_id: req.params.id,
      count: attendees.length,
      attendees,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    next(err);
  }
};

/* ─── POST /api/rooms ────────────────────────────────────────────────────── */
const createRoom = async (req, res, next) => {
  try {
    const { name, description, capacity, latitude, longitude } = req.body;
    if (!name || !capacity)
      return res.status(400).json({ success: false, message: "Name and capacity are required" });

    const room_code = await generateRoomCode();
    const qr_token  = uuidv4();
    const orgId = req.user ? req.user.org_id : null;

    const [result] = await pool.execute(
      `INSERT INTO rooms (name, description, capacity, room_code, qr_token, latitude, longitude, org_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [name, description || null, capacity, room_code, qr_token,
       latitude || null, longitude || null, orgId]
    );

    const [newRoom] = await pool.execute("SELECT * FROM rooms WHERE id = ?", [result.insertId]);

    // broadcast update
    const io = req.app.get("io");
    emitRoomsUpdate(io);

    res.status(201).json({ success: true, room: newRoom[0] });
  } catch (err) {
    next(err);
  }
};

/* ─── PUT /api/rooms/:id ─────────────────────────────────────────────────── */
const updateRoom = async (req, res, next) => {
  try {
    const { name, description, capacity, latitude, longitude } = req.body;
    const orgId = req.user ? req.user.org_id : null;
    const [result] = await pool.execute(
      `UPDATE rooms
       SET name=?, description=?, capacity=?, latitude=?, longitude=?
       WHERE id=? AND (org_id = ? OR (? IS NULL AND org_id IS NULL))`,
      [name, description || null, capacity, latitude || null, longitude || null, req.params.id, orgId, orgId]
    );
    if (result.affectedRows === 0) {
      return res.status(403).json({ success: false, message: "Room not found or access denied" });
    }
    const [updated] = await pool.execute("SELECT * FROM rooms WHERE id=?", [req.params.id]);

    const io = req.app.get("io");
    emitRoomsUpdate(io);

    res.json({ success: true, room: updated[0] });
  } catch (err) {
    next(err);
  }
};

/* ─── DELETE /api/rooms/:id ──────────────────────────────────────────────── */
const deleteRoom = async (req, res, next) => {
  try {
    const orgId = req.user ? req.user.org_id : null;
    const [result] = await pool.execute(
      "UPDATE rooms SET is_active = 0 WHERE id = ? AND (org_id = ? OR (? IS NULL AND org_id IS NULL))",
      [req.params.id, orgId, orgId]
    );
    if (result.affectedRows === 0) {
      return res.status(403).json({ success: false, message: "Room not found or access denied" });
    }

    const io = req.app.get("io");
    emitRoomsUpdate(io);

    res.json({ success: true, message: "Room deactivated" });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/rooms/:id/stats ───────────────────────────────────────────── */
const getRoomStats = async (req, res, next) => {
  try {
    const { date } = req.query;
    const dateFilter = date || new Date().toISOString().slice(0, 10);

    const [[stats]] = await pool.execute(
      `SELECT COUNT(*) AS total_checkins,
              SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) AS present,
              SUM(CASE WHEN status='late'    THEN 1 ELSE 0 END) AS late,
              AVG(ai_similarity) AS avg_confidence
       FROM attendance WHERE room_id = ? AND DATE(checkin_time) = ?`,
      [req.params.id, dateFilter]
    );

    res.json({ success: true, date: dateFilter, stats });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getRooms, getRoomById, getRoomByCode,
  getRoomLive, createRoom, updateRoom,
  deleteRoom, getRoomStats,
};
