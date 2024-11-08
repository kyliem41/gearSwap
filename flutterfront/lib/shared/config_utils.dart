import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigUtils {
  static String? _baseUrl;
  static String? _ablyKey;
  static Map<String, String>? _config;
  
  static Future<Map<String, String>> _loadConfig() async {
    if (_config != null) return _config!;
    
    final String jsonString = await rootBundle.loadString('lib/shared/config.json');
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

  static Future<String> getAblyKey() async {
    if (_ablyKey != null) return _ablyKey!;
    
    final config = await _loadConfig();
    _ablyKey = config['ably_key'];
    print('Ably Key loaded');
    return _ablyKey!;
  }
}