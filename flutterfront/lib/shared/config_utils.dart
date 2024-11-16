import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigUtils {
  static String? _baseUrl;
  static Map<String, String>? _config;

  static Future<Map<String, String>> _loadConfig() async {
    if (_config != null) return _config!;

    final String jsonString =
        await rootBundle.loadString('lib/shared/config.json');
    _config = Map<String, String>.from(json.decode(jsonString));
    return _config!;
  }

  static Future<String> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;

    final config = await _loadConfig();
    _baseUrl = config['url'];
    print('Base URL: $_baseUrl');
    return _baseUrl!;
  }

  static Future<String> getWebSocketUrl() async {
    final config = await _loadConfig();
    final wsUrl = config['WEBSOCKET_API_DOMAIN'];
    final stage = config['WEBSOCKET_API_STAGE'];
    if (wsUrl == null || stage == null) {
      throw Exception('Missing WebSocket configuration');
    }
    final url = 'wss://$wsUrl/$stage';
    print('WebSocket URL: wss://$wsUrl/$stage');
    return url;
  }
}
