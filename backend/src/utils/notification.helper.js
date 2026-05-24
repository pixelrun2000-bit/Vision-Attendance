// src/utils/notification.helper.js
const { pool } = require("../config/db");

/**
 * Creates a notification in the database and emits a real-time event via Socket.IO
 * @param {Object} app - The Express app instance (to get 'io')
 * @param {number} userId - ID of the user to notify
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {string} type - Notification type (e.g., 'vacation', 'attendance', 'system')
 */
const createAndNotify = async (app, userId, title, body, type = "system") => {
  try {
    // 1. Insert into database
    const [result] = await pool.execute(
      "INSERT INTO notifications (user_id, title, body, type, is_read) VALUES (?, ?, ?, ?, 0)",
      [userId, title, body, type]
    );

    const notificationId = result.insertId;

    // 2. Fetch the created notification to have consistent data
    const [rows] = await pool.execute(
      "SELECT id, title, body, type, is_read, created_at FROM notifications WHERE id = ?",
      [notificationId]
    );
    const notification = rows[0];

    // 3. Emit via Socket.IO if available
    const io = app.get("io");
    if (io) {
      // Send to the user's specific room
      io.to(`user:${userId}`).emit("notification:new", notification);
      console.log(`[WS] Notification emitted to user:${userId}`);
    }

    return notification;
  } catch (err) {
    console.error("Error creating notification:", err);
    throw err;
  }
};

module.exports = { createAndNotify };
