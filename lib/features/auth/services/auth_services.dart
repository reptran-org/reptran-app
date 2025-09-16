import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reptran_app/core/network/api_client.dart';

final _secureStorage = const FlutterSecureStorage();
final Dio _dio = ApiClient().dio;

class AuthServices {
  /// Call server to revoke/clear refresh token(s) for this device/user.
  /// If your server has a dedicated endpoint, call it with the current refresh token
  /// or authorization header. If not available, still clear client-side tokens.
  static Future<void> logout({bool callServer = true}) async {
    try {
      final refresh = await _secureStorage.read(key: 'refresh_token');

      if (callServer && refresh != null) {
        // try to revoke on server (best-effort)
        try {
          await _dio.post('/auth/logout', data: {'refreshToken': refresh});
        } catch (e) {
          // ignore server errors — still clear locally
        }
      }

      await clearLocalAuth();
    } catch (_) {
      await clearLocalAuth();
    }
  }

  /// clear local tokens, draft and any auth-related flags
  static Future<void> clearLocalAuth() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    // if you want to clear onboarding draft on logout, uncomment:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('onboarding_draft_v1');

    // keep a small flag that user has an account (if you want)
    // await prefs.setBool('has_account', true/false) — set elsewhere
  }

  /// call this after signup/verify/login to mark device as having an account
  static Future<void> markHasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_account', true);
  }

  /// helper used by splash: returns whether device has account marker
  static Future<bool> hasAccountMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_account') ?? false;
  }
}
