// src/routes/ai.routes.js
const router = require("express").Router();
const ctrl = require("../controllers/ai.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");
const upload = require("../middleware/upload");

router.get("/status",                           ctrl.getAiStatus);
router.post("/recognize",  authenticate,        upload.single("image"), ctrl.recognize);
router.post("/enroll",     authenticate, requireAdmin, upload.single("image"), ctrl.enroll);
router.post("/quality",    authenticate,        upload.single("image"), ctrl.checkQuality);
router.post("/liveness",   authenticate,        upload.single("image"), ctrl.checkLiveness);

module.exports = router;
