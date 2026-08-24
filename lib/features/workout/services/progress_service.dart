import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

Map<String, String> getDefaultCalendarRange() {
  final now = DateTime.now();

  // Go 5 months back + current month = ~6 months
  final start = DateTime(now.year, now.month - 5, 1);

  // End = last day of current month
  final end = DateTime(now.year, now.month + 1, 0);

  return {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
}

class ProgressService {
  final Dio _dio = ApiClient().dio;

  static const _kAuthTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _kAuthTokenKey);

  Future<void> _attachToken() async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

Future<Map<String, dynamic>> getCalendarData({
  DateTime? start,
  DateTime? end,
}) async {
  await _attachToken();

  // ✅ Default to 6 months if not provided
  final range = (start == null || end == null)
      ? getDefaultCalendarRange()
      : {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        };

  final res = await _dio.get(
    '/progress/calendar',
    queryParameters: {
      'start': range['start'],
      'end': range['end'],
    },
  );

  final data = res.data as Map<String, dynamic>;
  final result = data['result'] ?? {};

  return result as Map<String, dynamic>;
}


Future<Map<String, dynamic>> getAnalytics({String range = '7d'}) async {
  await _attachToken();

  final res = await _dio.get(
    '/progress/analytics',
    queryParameters: {'range': range},
  );

  final data = res.data as Map<String, dynamic>;
  return (data['result'] ?? data['data'] ?? {}) as Map<String, dynamic>;
}

}