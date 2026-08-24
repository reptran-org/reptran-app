import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/features/auth/services/auth_flow_service.dart';
import 'package:reptran_app/shared/services/timezone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reptran_app/core/services/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reptran_app/core/network/api_client.dart';

class SocialAuthService {
  static final Dio _dio = ApiClient().dio;

  static const _secureStorage = FlutterSecureStorage();

  static Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      // Initialize Google Sign-In with your web client ID

      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);

      // Ensure platform supports authenticate()
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        logger.i('⚠️ This platform needs a custom sign-in UI');
      }

      // Open Google account chooser
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Fetch authentication details
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        logger.i('❌ Missing Google ID Token');
      }

   

      // Send token to backend for verification
      final resp = await _dio.post(
        '/auth/social-login',
        data: {'provider': 'google', 'providerToken': idToken,'timezone': TimezoneService.timezone,},
      );

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
        }
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_account', true);

        if (user != null) {
          await prefs.setString('me_user', jsonEncode(user));
        }

        if (context.mounted) {
          await AuthFlowService.decideAndRoute(context);
        }
      } else {
        logger.i('❌ Server error: ${resp.statusCode}');
      }
    } catch (e) {
      logger.i('❌ Google Sign-In error: $e');
    }
  }
}
