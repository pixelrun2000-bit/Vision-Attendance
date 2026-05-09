// src/routes/users.routes.js
const router = require("express").Router();
const ctrl = require("../controllers/users.controller");
const { authenticate, requireManagerOrAdmin, requireSuperAdmin } = require("../middleware/auth");
const upload = require("../middleware/upload");

router.use(authenticate);

router.get("/",                        requireManagerOrAdmin, ctrl.getUsers);   // admin+manager
router.put("/me/profile",              ctrl.updateMyProfile);
router.post("/me/profile-photo",       upload.single("image"), ctrl.uploadMyProfilePhoto);
router.post("/me/location",            ctrl.upsertMyLocation);
router.get("/:id",                     requireManagerOrAdmin, ctrl.getUserById);
router.get("/:id/attendance-summary",  requireManagerOrAdmin, ctrl.getUserAttendanceSummary);
router.post("/",                       requireManagerOrAdmin, ctrl.createUser);  // admin+manager
router.put("/:id",                     requireSuperAdmin,     ctrl.updateUser);  // admin only
router.delete("/:id",                  requireSuperAdmin,     ctrl.deleteUser);  // admin only

module.exports = router;
