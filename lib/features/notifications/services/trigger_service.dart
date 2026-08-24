import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';

class TriggerService {
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

  /// ⏳ Snooze or Skip the current trigger
  ///
  /// Backend expects:
  /// {
  ///   minutes: number,
  ///   overrideWindows?: boolean,
  ///   source?: "NUDGE" | "SKIP"
  /// }
  Future<Map<String, dynamic>> snoozeMyTrigger({
    required int minutes,
    bool overrideWindows = false,
    String source = 'NUDGE', // or 'SKIP'
  }) async {
    await _attachToken();

    final res = await _dio.post(
      '/triggers/me/snooze',
      data: {
        'minutes': minutes,
        'overrideWindows': overrideWindows,
        'source': source,
      },
    );

    return res.data['result'] as Map<String, dynamic>;
  }
}
