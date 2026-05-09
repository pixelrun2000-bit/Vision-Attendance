// lib/services/api_client.dart
// ─── HTTP Client with timeout + retry + better error messages ────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // ── POST JSON ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body ?? {}),
        )
        .timeout(ApiConfig.timeout, onTimeout: () => _timeoutError());
    return _decode(response);
  }

  // ── GET JSON ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
  }) async {
    final response = await http
        .get(
          _uri(path),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout, onTimeout: () => _timeoutError());
    return _decode(response);
  }

  // ── PUT JSON ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await http
        .put(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout, onTimeout: () => _timeoutError());
    return _decode(response);
  }

  // ── MULTIPART ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamed = await request
        .send()
        .timeout(ApiConfig.timeout, onTimeout: () => throw Exception('Upload timed out'));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  // ── RESPONSE DECODER ───────────────────────────────────────────────────────
  Map<String, dynamic> _decode(http.Response response) {
    late Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      throw Exception('Server returned invalid response (status ${response.statusCode})');
    }

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed (${response.statusCode})');
    }

    return data;
  }

  // ── TIMEOUT PLACEHOLDER ────────────────────────────────────────────────────
  http.Response _timeoutError() => throw Exception(
      'Cannot reach server at $baseUrl\n'
      'Make sure the backend is running and your IP is correct in api_config.dart');
}