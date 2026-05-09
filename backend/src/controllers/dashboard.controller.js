// src/controllers/dashboard.controller.js
// ─── Enhanced Dashboard Controller with Real-time Support ────────────────────
const { pool } = require("../config/db");

/* ─── emit helper ─────────────────────────────────────────────────────────── */
function emitDashboardUpdate(io) {
  if (!io) return;
  // Trigger all connected clients to refetch dashboard stats
  io.emit("dashboard:update", { timestamp: new Date().toISOString() });
}

/* ─── GET /api/dashboard/stats ───────────────────────────────────────────── */
const getStats = async (req, res, next) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const orgId = req.user && req.user.org_id ? req.user.org_id : null;
    const orgFilterUser = orgId ? `AND org_id = ${orgId}` : "AND org_id IS NULL";
    const orgFilterUserAlias = orgId ? `AND u.org_id = ${orgId}` : "AND u.org_id IS NULL";
    const orgFilterRoom = orgId ? `AND r.org_id = ${orgId}` : "AND r.org_id IS NULL";

    // ── Today's attendance ─────────────────────────────────────────────────
    const [[todayStats]] = await pool.execute(
      `SELECT
         COUNT(*)                                             AS total_checkins,
         SUM(CASE WHEN status='present' THEN 1 ELSE 0 END)  AS present,
         SUM(CASE WHEN status='late'    THEN 1 ELSE 0 END)  AS late,
         AVG(ai_similarity)                                  AS avg_confidence,
         SUM(CASE WHEN method='face'    THEN 1 ELSE 0 END)  AS face_checkins,
         SUM(CASE WHEN method='qr_code' THEN 1 ELSE 0 END)  AS qr_checkins
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       WHERE DATE(a.checkin_time) = ? ${orgFilterUserAlias}`,
      [today]
    );

    // ── Total users by role ────────────────────────────────────────────────
    const [userStats] = await pool.execute(
      `SELECT role, COUNT(*) as count FROM users WHERE is_active=1 ${orgFilterUser} GROUP BY role`
    );

    // ── Total registered users (not admin) ────────────────────────────────
    const [[{ total_users, total_employees, total_students }]] = await pool.execute(
      `SELECT
         COUNT(*) AS total_users,
         SUM(CASE WHEN role='employee' THEN 1 ELSE 0 END) AS total_employees,
         SUM(CASE WHEN role='student'  THEN 1 ELSE 0 END) AS total_students
       FROM users WHERE is_active=1 AND role != 'admin' ${orgFilterUser}`
    );

    // ── Absent today (registered but no check-in) ─────────────────────────
    const [[{ absent_today }]] = await pool.execute(
      `SELECT COUNT(*) AS absent_today
       FROM users u
       WHERE u.is_active = 1 AND u.role != 'admin' ${orgFilterUserAlias}
         AND NOT EXISTS (
           SELECT 1 FROM attendance a
           WHERE a.user_id = u.id AND DATE(a.checkin_time) = ?
         )`,
      [today]
    );

    // ── Pending vacation requests ──────────────────────────────────────────
    const [[{ pending_vacations }]] = await pool.execute(
      `SELECT COUNT(*) as pending_vacations FROM vacation_requests v 
       JOIN users u ON v.user_id = u.id
       WHERE v.status='pending' ${orgFilterUserAlias}`
    );

    // ── Face enrollment rate ───────────────────────────────────────────────
    const [[enrollStats]] = await pool.execute(
      `SELECT
         COUNT(*) as total_users,
         SUM(is_face_enrolled) as enrolled
       FROM users WHERE is_active=1 AND role != 'admin' ${orgFilterUser}`
    );

    // ── Last 7 days trend ──────────────────────────────────────────────────
    const [weekTrend] = await pool.execute(
      `SELECT DATE(a.checkin_time) as date,
              COUNT(*) as total,
              SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END) as present,
              SUM(CASE WHEN a.status='late'    THEN 1 ELSE 0 END) as late
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       WHERE a.checkin_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ${orgFilterUserAlias}
       GROUP BY DATE(a.checkin_time)
       ORDER BY date ASC`
    );

    // ── Attendance by room (today) ─────────────────────────────────────────
    const [roomStats] = await pool.execute(
      `SELECT r.id, r.name, r.room_code, r.capacity,
              COUNT(a.id) AS checkins
       FROM rooms r
       LEFT JOIN attendance a
         ON a.room_id = r.id AND DATE(a.checkin_time) = ?
       WHERE r.is_active = 1 ${orgFilterRoom}
       GROUP BY r.id
       ORDER BY checkins DESC`,
      [today]
    );

    // ── Recent check-ins (last 15) ─────────────────────────────────────────
    const [recentCheckins] = await pool.execute(
      `SELECT a.id, a.checkin_time, a.checkout_time, a.status, a.ai_similarity,
              a.method, a.ai_spoof_passed, a.ai_liveness_ok,
              u.id AS user_id, u.full_name_en, u.full_name_ar, u.department,
              u.role, u.photo_url, u.employee_id,
              r.name AS room_name, r.room_code
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       LEFT JOIN rooms r ON a.room_id = r.id
       WHERE 1=1 ${orgFilterUserAlias}
       ORDER BY a.checkin_time DESC LIMIT 15`
    );

    // ── AI alerts (fraud / spoof, last 24h) ────────────────────────────────
    const [alerts] = await pool.execute(
      `SELECT a.id, a.checkin_time, a.ai_fraud_risk, a.ai_spoof_passed,
              u.full_name_en, u.department
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       WHERE a.checkin_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
         AND (a.ai_fraud_risk > 0.5 OR a.ai_spoof_passed = 0)
         ${orgFilterUserAlias}
       ORDER BY a.checkin_time DESC LIMIT 5`
    );

    res.json({
      success: true,
      today: {
        date: today,
        ...todayStats,
        absent: absent_today,
        attendance_rate: total_users
          ? Math.round(((todayStats.present + todayStats.late) / total_users) * 100)
          : 0,
      },
      users: {
        by_role:         userStats,
        total:           total_users,
        total_employees,
        total_students,
        enrolled:        enrollStats.enrolled,
        enrollment_rate: enrollStats.total_users
          ? Math.round((enrollStats.enrolled / enrollStats.total_users) * 100)
          : 0,
      },
      pending_vacations,
      week_trend:      weekTrend,
      room_stats:      roomStats,
      recent_checkins: recentCheckins,
      alerts,
    });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/dashboard/person/:id ─────────────────────────────────────── */
/**
 * Full attendance history + stats for a specific person.
 * Used by the "View Details" panel in the web Add Person page.
 */
const getPersonDetail = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const { month } = req.query;
    const monthFilter = month || new Date().toISOString().slice(0, 7);

    // Basic user info
    const [[user]] = await pool.execute(
      `SELECT id, full_name_en, full_name_ar, username, email, phone,
              role, department, employee_id, photo_url,
              is_face_enrolled, created_at
       FROM users WHERE id = ? AND is_active = 1`,
      [userId]
    );
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    // Monthly summary
    const [[summary]] = await pool.execute(
      `SELECT
         COUNT(*)                                             AS total_sessions,
         SUM(CASE WHEN status='present' THEN 1 ELSE 0 END)  AS present,
         SUM(CASE WHEN status='late'    THEN 1 ELSE 0 END)  AS late,
         SUM(CASE WHEN status='absent'  THEN 1 ELSE 0 END)  AS absent,
         AVG(ai_similarity)                                  AS avg_confidence,
         MAX(checkin_time)                                   AS last_checkin
       FROM attendance
       WHERE user_id = ? AND DATE_FORMAT(checkin_time,'%Y-%m') = ?`,
      [userId, monthFilter]
    );

    // All-time total
    const [[{ all_time_total }]] = await pool.execute(
      "SELECT COUNT(*) AS all_time_total FROM attendance WHERE user_id = ?",
      [userId]
    );

    // Recent 20 attendance records
    const [records] = await pool.execute(
      `SELECT a.id, a.checkin_time, a.checkout_time, a.status, a.method,
              a.ai_similarity, a.ai_spoof_passed, a.ai_liveness_ok,
              r.name AS room_name, r.room_code
       FROM attendance a
       LEFT JOIN rooms r ON a.room_id = r.id
       WHERE a.user_id = ?
       ORDER BY a.checkin_time DESC LIMIT 20`,
      [userId]
    );

    res.json({
      success: true,
      user,
      month: monthFilter,
      summary: { ...summary, all_time_total },
      records,
    });
  } catch (err) {
    next(err);
  }
};

/* ─── GET /api/dashboard/reports ─────────────────────────────────────────── */
const getReports = async (req, res, next) => {
  try {
    const { from, to, department, role } = req.query;
    const fromDate = from || new Date(new Date().setDate(1)).toISOString().slice(0, 10);
    const toDate   = to   || new Date().toISOString().slice(0, 10);

    const where  = ["DATE(a.checkin_time) BETWEEN ? AND ?"];
    const params = [fromDate, toDate];

    if (department) { where.push("u.department = ?"); params.push(department); }
    if (role)       { where.push("u.role = ?");       params.push(role); }
    if (req.user && req.user.org_id) {
      where.push("u.org_id = ?");
      params.push(req.user.org_id);
    } else {
      where.push("u.org_id IS NULL");
    }

    const [report] = await pool.execute(
      `SELECT u.id, u.full_name_en, u.full_name_ar, u.department, u.role,
              u.employee_id, u.photo_url,
              COUNT(*) as total_days,
              SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END) as present,
              SUM(CASE WHEN a.status='late'    THEN 1 ELSE 0 END) as late,
              AVG(a.ai_similarity) as avg_confidence
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       WHERE ${where.join(" AND ")}
       GROUP BY u.id, u.full_name_en, u.full_name_ar, u.department, u.role,
                u.employee_id, u.photo_url
       ORDER BY u.department, u.full_name_en`,
      params
    );

    res.json({ success: true, from: fromDate, to: toDate, report });
  } catch (err) {
    next(err);
  }
};

module.exports = { getStats, getPersonDetail, getReports, emitDashboardUpdate };
