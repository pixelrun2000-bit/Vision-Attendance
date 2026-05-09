// src/routes/dashboard.routes.js
const router = require("express").Router();
const ctrl   = require("../controllers/dashboard.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");

router.use(authenticate, requireAdmin);

router.get("/stats",          ctrl.getStats);
router.get("/reports",        ctrl.getReports);
router.get("/person/:id",     ctrl.getPersonDetail);   // per-person attendance detail

module.exports = router;
