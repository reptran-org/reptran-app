import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:reptran_app/shared/services/timezone_service.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  static const _kAuthTokenKey = 'auth_token';
  static const _kRefreshTokenKey = 'refresh_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ---------------------
  // Token helpers
  // ---------------------
  Future<String?> getToken() => _storage.read(key: _kAuthTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshTokenKey);

  Future<void> setTokens({required String token, String? refreshToken}) async {
    await _storage.write(key: _kAuthTokenKey, value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _kAuthTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    _dio.options.headers.remove('Authorization');
  }

  // ---------------------
  // Refresh logic (handles response parsing + storage)
  // ---------------------
  /// Returns true if refresh succeeded and tokens were updated.
  Future<bool> refreshTokens() async {
    try {
      final refresh = await getRefreshToken();
      if (refresh == null) return false;

      final resp = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data as Map<String, dynamic>? ?? {};
        final newToken = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newToken != null) {
          await setTokens(token: newToken, refreshToken: newRefresh);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------
  // Optional helper: do a request and auto-retry once on 401
  // Use this when you want the call to transparently attempt refresh + retry.
  // Example usage:
  //   final resp = await authService.requestWithRefresh(() => authService._dio.post(...));
  // ---------------------
  Future<Response> requestWithRefresh(
    Future<Response> Function() request,
  ) async {
    try {
      final resp = await request();
      return resp;
    } on DioException catch (e) {
      // If unauthorized, try refresh once and retry
      final status = e.response?.statusCode;
      if (status == 401) {
        final refreshed = await refreshTokens();
        if (refreshed) {
          // retry the original request once
          return await request();
        }
      }
      rethrow;
    }
  }

  // ---------------------
  // API methods (unchanged semantics) — they just call endpoints and return the Response.
  // Call these directly if you want manual control, or wrap them with requestWithRefresh.
  // ---------------------
  Future<Response> signup({
    required String name,
    required String email,
    required String password,
  }) {
    return _dio.post(
      '/auth/signup',
      data: {'name': name, 'email': email, 'password': password,'timezone': TimezoneService.timezone,},
    );
  }

  Future<Response> login({required String email, required String password}) {
    return _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password,'timezone': TimezoneService.timezone,},
    );
  }

  Future<Response> forgotPassword({required String email}) {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Response> verifyOtp({
    required String email,
    required String purpose,
    required String otp,
  }) {
    return _dio.post(
      '/auth/verify-otp',
      data: {'email': email, 'purpose': purpose, 'otp': otp},
    );
  }

  Future<Response> resendOtp({required String email, required String purpose}) {
    return _dio.post(
      '/auth/resend-otp',
      data: {'email': email, 'purpose': purpose},
    );
  }

  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _dio.post(
      '/auth/reset-password',
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  Future<Response> submitOnboarding(Map<String, dynamic> draft) async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _dio.post('/auth/onboarding', data: draft);
  }
}
