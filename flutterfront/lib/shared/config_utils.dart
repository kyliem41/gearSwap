import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigUtils {
  static String? _baseUrl;
  
  static Future<String> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    
    final String jsonString = await rootBundle.loadString('lib/shared/config.json');
    final jsonMap = json.decode(jsonString);
    _baseUrl = jsonMap['url'] as String;
    return _baseUrl!;
  }
}
