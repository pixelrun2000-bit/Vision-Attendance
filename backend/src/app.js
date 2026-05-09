// src/app.js
const express = require("express");
const cors    = require("cors");
const path = require("path");
require("dotenv").config();

const app = express();

// ── CORS: allow React Dashboard (3001) and Flutter (any origin) ───────────────
app.use(cors({
  origin: true,
  credentials: true,
}));

// ── Body parsers ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: "20mb" }));
app.use(express.urlencoded({ extended: true, limit: "20mb" }));
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

// ── Health check ──────────────────────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.json({
    success: true,
    service: "Vision Attendance Backend",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
  });
});

// ── Routes ───────────────────────────────────────────────────────────────────
app.use("/api/auth",           require("./routes/auth.routes"));
app.use("/api/users",          require("./routes/users.routes"));
app.use("/api/attendance",     require("./routes/attendance.routes"));
app.use("/api/rooms",          require("./routes/rooms.routes"));
app.use("/api/vacations",      require("./routes/vacations.routes"));
app.use("/api/dashboard",      require("./routes/dashboard.routes"));
app.use("/api/ai",             require("./routes/ai.routes"));
app.use("/api/notifications",  require("./routes/notifications.routes"));
app.use("/api/settings",       require("./routes/settings.routes"));
app.use("/api/payments",       require("./routes/payments.routes"));

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use(require("./middleware/errorHandler"));

module.exports = app;
