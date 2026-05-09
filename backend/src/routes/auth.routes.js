// src/routes/auth.routes.js
const router = require("express").Router();
const { login, register, getMe, changePassword } = require("../controllers/auth.controller");
const { authenticate } = require("../middleware/auth");

router.post("/login",           login);
router.post("/register",        register);
router.get("/me",               authenticate, getMe);
router.put("/change-password",  authenticate, changePassword);

module.exports = router;
