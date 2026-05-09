// src/routes/vacations.routes.js
const router = require("express").Router();
const ctrl = require("../controllers/vacations.controller");
const { authenticate, requireAdmin } = require("../middleware/auth");

router.use(authenticate);

router.get("/",                  requireAdmin,  ctrl.getVacations);
router.get("/my-requests",                      ctrl.getMyVacations);
router.post("/",                                ctrl.createVacation);
router.put("/:id/review",        requireAdmin,  ctrl.reviewVacation);
router.delete("/:id",                           ctrl.cancelVacation);

module.exports = router;
