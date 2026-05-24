// server.js — Vision Attendance Backend with Socket.IO real-time support
require("dotenv").config();
const http = require("http");
const { Server } = require("socket.io");
const os = require("os");
const fs = require("fs");
const path = require("path");
const app = require("./src/app");
const { testConnection } = require("./src/config/db");

// ── Auto-detect Local IP ──────────────────────────────────────────────────
let localIp = "127.0.0.1";
const interfaces = os.networkInterfaces();
for (const name of Object.keys(interfaces)) {
  for (const iface of interfaces[name]) {
    if (iface.family === "IPv4" && !iface.internal) {
      localIp = iface.address; // Grab the last external IPv4 (usually WiFi/Ethernet)
    }
  }
}

// ── Auto-update Flutter api_config.dart ──────────────────────────────────
try {
  const configPath = path.join(__dirname, "..", "vision_attendance", "lib", "config", "api_config.dart");
  if (fs.existsSync(configPath)) {
    let content = fs.readFileSync(configPath, "utf8");
    const updated = content.replace(/baseUrl\s*=\s*"http:\/\/[0-9\.]+:\d+"/g, `baseUrl = "http://${localIp}:3001"`);
    if (content !== updated) {
      fs.writeFileSync(configPath, updated);
      console.log(`✅ Auto-updated Flutter App IP to: http://${localIp}:3001`);
    }
  }
} catch (e) {
  console.log("⚠️ Could not auto-update Flutter config:", e.message);
}

const PORT = process.env.PORT || 3001;

(async () => {
  try {
    await testConnection();

    // ── Wrap express with http server for Socket.IO ───────────────────────────
    const httpServer = http.createServer(app);
    const io = new Server(httpServer, {
      cors: { origin: "*", methods: ["GET", "POST"] },
    });

    // Make io accessible from every controller via req.app.get("io")
    app.set("io", io);

    // ── Socket.IO events ──────────────────────────────────────────────────────
    io.on("connection", (socket) => {
      console.log(`[WS] Client connected: ${socket.id}`);

      // Client joins their personal room for notifications
      socket.on("user:join", (userId) => {
        socket.join(`user:${userId}`);
        console.log(`[WS] ${socket.id} joined user:${userId}`);
      });

      socket.on("room:join", (roomId) => {
        socket.join(`room:${roomId}`);
        console.log(`[WS] ${socket.id} joined room:${roomId}`);
      });

      socket.on("room:leave", (roomId) => {
        socket.leave(`room:${roomId}`);
      });

      socket.on("disconnect", () => {
        console.log(`[WS] Client disconnected: ${socket.id}`);
      });
    });

    // ── Start ─────────────────────────────────────────────────────────────────
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log("");
      console.log("╔══════════════════════════════════════════════════╗");
      console.log("║       Vision Attendance Backend 🚀              ║");
      console.log("╠══════════════════════════════════════════════════╣");
      console.log(`║  HTTP     →  http://0.0.0.0:${PORT}              ║`);
      console.log(`║  WS/IO    →  ws://0.0.0.0:${PORT}                ║`);
      console.log(`║  Network  →  http://${localIp}:${PORT}          ║`);
      console.log(`║  AI proxy →  http://127.0.0.1:5000           ║`);
      console.log(`║  DB       →  ${process.env.DB_NAME}@${process.env.DB_HOST}          ║`);
      console.log("╠══════════════════════════════════════════════════╣");
      console.log("║  Real-time rooms enabled (Socket.IO)            ║");
      console.log("╚══════════════════════════════════════════════════╝");
      console.log("");
    });

  } catch (err) {
    console.error("❌ Failed to start server:", err);
  }
})();