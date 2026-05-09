// src/controllers/notifications.controller.js
const { pool } = require("../config/db");

// GET /api/notifications  ← Flutter (my notifications)
const getMyNotifications = async (req, res, next) => {
  try {
    const [notifications] = await pool.execute(
      `SELECT id, title, body, type, is_read, created_at
       FROM notifications WHERE user_id = ?
       ORDER BY created_at DESC LIMIT 50`,
      [req.user.id]
    );

    const [[{ unread }]] = await pool.execute(
      "SELECT COUNT(*) as unread FROM notifications WHERE user_id = ? AND is_read = 0",
      [req.user.id]
    );

    res.json({ success: true, notifications, unread });
  } catch (err) {
    next(err);
  }
};

// PUT /api/notifications/:id/read  ← Flutter
const markRead = async (req, res, next) => {
  try {
    await pool.execute(
      "UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?",
      [req.params.id, req.user.id]
    );
    res.json({ success: true, message: "Notification marked as read" });
  } catch (err) {
    next(err);
  }
};

// PUT /api/notifications/read-all  ← Flutter
const markAllRead = async (req, res, next) => {
  try {
    await pool.execute(
      "UPDATE notifications SET is_read = 1 WHERE user_id = ?",
      [req.user.id]
    );
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (err) {
    next(err);
  }
};

module.exports = { getMyNotifications, markRead, markAllRead };
