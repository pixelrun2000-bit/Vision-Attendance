// src/routes/settings.routes.js
const router = require("express").Router();
const ctrl = require("../controllers/settings.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");

router.use(authenticate);

router.get("/",         requireAdmin, ctrl.getSettings);
router.put("/",         requireAdmin, ctrl.updateSettings);
router.put("/profile",               ctrl.updateAdminProfile);

module.exports = router;
