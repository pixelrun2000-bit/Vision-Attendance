// lib/config/api_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// 🔧 IMPORTANT — Change baseUrl to your computer's local IP before testing:
//
//   Android Emulator  → http://10.0.2.2:3001
//   Real Device       → http://192.168.X.X:3001   ← your PC's WiFi IP
//   iOS Simulator     → http://127.0.0.1:3001
//
// Run in terminal to find your IP:
//   Windows → ipconfig  (look for "IPv4 Address" under Wi-Fi)
//   Mac/Linux → ifconfig | grep "inet "
// ─────────────────────────────────────────────────────────────────────────────
class ApiConfig {
  // ← Change this to your PC's IP address
  static const String baseUrl = "http://192.168.1.2:3001";

  static const Duration timeout = Duration(seconds: 15);
}