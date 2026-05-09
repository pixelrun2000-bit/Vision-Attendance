// src/routes/attendance.routes.js
const router = require("express").Router();
const ctrl   = require("../controllers/attendance.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");

router.use(authenticate);

router.get("/",                   requireAdmin, ctrl.getAttendance);
router.get("/my-logs",            ctrl.getMyLogs);
router.get("/today",              ctrl.getTodayStatus);

// Mobile check-in via Room Code / QR token + GPS
router.post("/checkin-by-room",   ctrl.checkinByRoom);
// Checkout
router.post("/checkout",          ctrl.checkout);

router.delete("/:id",             requireAdmin, ctrl.deleteRecord);

module.exports = router;
