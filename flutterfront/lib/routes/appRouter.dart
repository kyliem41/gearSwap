import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sample/logIn/resetPass.dart';
import 'package:sample/logIn/updatePass.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/reset-password',  // Changed to a simpler path for the form
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: '/users/password/:userId',  // Match the path from the email link
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        final userId = state.params['userId'];
        
        if (token == null || userId == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid reset link')),
          );
        }
        
        return UpdatePasswordPage(token: token, userId: userId);
      },
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Route not found')),
  ),
);