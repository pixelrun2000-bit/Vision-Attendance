// src/routes/rooms.routes.js
const router = require("express").Router();
const ctrl   = require("../controllers/rooms.controller");
const { authenticate, requireAdmin, requireSuperAdmin } = require("../middleware/auth");

router.use(authenticate);

router.get("/",                    ctrl.getRooms);                           // any authenticated user
router.get("/by-code/:code",       ctrl.getRoomByCode);                      // mobile check-in
router.get("/:id",                 ctrl.getRoomById);
router.get("/:id/live",            ctrl.getRoomLive);                        // real-time attendees
router.get("/:id/stats",           requireAdmin,       ctrl.getRoomStats);   // admin + manager
router.post("/",                   requireSuperAdmin,  ctrl.createRoom);     // admin only
router.put("/:id",                 requireSuperAdmin,  ctrl.updateRoom);     // admin only
router.delete("/:id",              requireSuperAdmin,  ctrl.deleteRoom);     // admin only

module.exports = router;
