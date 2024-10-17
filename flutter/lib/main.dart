import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'example_app.dart';

void main() async {

try {
   await dotenv.load();
print('AUTH0_DOMAIN: ${dotenv.env['AUTH0_DOMAIN']}');
    print('AUTH0_CLIENT_ID: ${dotenv.env['AUTH0_CLIENT_ID']}');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  runApp(const ExampleApp());
}

