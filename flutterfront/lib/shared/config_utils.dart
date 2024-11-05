import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigUtils {
  static String? _baseUrl;
  
  static Future<String> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    
    final String jsonString = await rootBundle.loadString('lib/shared/config.json');
    final jsonMap = json.decode(jsonString);
    _baseUrl = jsonMap['url'];
    print('Base URL: $_baseUrl');
    return _baseUrl!;
  }
}
