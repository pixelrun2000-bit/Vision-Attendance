// src/routes/attendance.routes.js
const router = require("express").Router();
const ctrl   = require("../controllers/attendance.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");
const upload = require("../middleware/upload");

router.use(authenticate);

router.get("/",                   requireAdmin, ctrl.getAttendance);
router.get("/my-logs",            ctrl.getMyLogs);
router.get("/today",              ctrl.getTodayStatus);

// Mobile check-in via Room Code / QR token + GPS
router.post("/checkin-by-room",   upload.single("image"), ctrl.checkinByRoom);
// Checkout
router.post("/checkout",          ctrl.checkout);
router.get("/force-checkout",     ctrl.forceCheckout);

router.delete("/:id",             requireAdmin, ctrl.deleteRecord);

module.exports = router;
