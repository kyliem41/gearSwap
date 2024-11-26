import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigUtils {
  static String? _baseUrl;
  static Map<String, String>? _config;
  static String? _passwordResetUrl;

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

  static Future<String> getPasswordResetUrl() async {
    if (_passwordResetUrl != null) return _passwordResetUrl!;

    final config = await _loadConfig();
    final baseUrl = config['url'];
    if (baseUrl == null) {
      throw Exception('Missing API URL configuration');
    }
    
    // Remove trailing slash if present
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    _passwordResetUrl = cleanBaseUrl;
    return _passwordResetUrl!;
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
