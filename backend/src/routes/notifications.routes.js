// src/routes/notifications.routes.js
const router = require("express").Router();
const ctrl = require("../controllers/notifications.controller");
const { authenticate } = require("../middleware/auth");

router.use(authenticate);

router.get("/",              ctrl.getMyNotifications);
router.put("/read-all",      ctrl.markAllRead);
router.put("/:id/read",      ctrl.markRead);

module.exports = router;
