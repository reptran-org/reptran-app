import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'dart:io';


class ProfileService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kAuthTokenKey = 'auth_token';

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

Future<Map<String, dynamic>> getUserEmail() async {
  await _attachToken();

  final response = await _dio.get('/user/email');

  return response.data['result'];
}

Future<void> updateEmail({
  required String newEmail,
}) async {
  await _attachToken();

  await _dio.put(
    '/user/email',
    data: {
      'newEmail': newEmail,
    },
  );
}

Future<void> updatePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  await _attachToken();

  await _dio.put(
    '/user/password',
    data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );
}

  Future<List<dynamic>> getBadges() async {
    await _attachToken();

    final response = await _dio.get('/badges');


    return response.data['result']['badges'];
  }

  Future<Map<String, dynamic>> getProfileProgress() async {
    await _attachToken();

    final response = await _dio.get('/progress/profile-progress');

    return response.data['result'];
  }

  Future<void> reportUser({
    required String targetUserId,
    required String reason,
  }) async {
    await _attachToken();

    await _dio.post(
      '/user/report',
      data: {'targetUserId': targetUserId, 'type': 'user', 'reason': reason},
    );
  }

  Future<void> blockUser({required String blockedUserId}) async {
    await _attachToken();

    await _dio.post('/user/block', data: {'blockedUserId': blockedUserId});
  }

  Future<void> unblockUser({required String blockedUserId}) async {
    await _attachToken();

    await _dio.post('/user/unblock', data: {'blockedUserId': blockedUserId});
  }

  Future<String> uploadAvatar(
    File file, {
    Function(int, int)? onSendProgress,
  }) async {
    await _attachToken();

    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });

    final res = await _dio.post(
      '/user/avatar',
      data: formData,

      // 👇 INTERCEPT + LOG
      onSendProgress: (sent, total) {

        if (total != 0) {
          final percent = (sent / total) * 100;
        }

        // 👇 still forward to UI
        if (onSendProgress != null) {
          onSendProgress(sent, total);
        }
      },
    );

    final data = res.data as Map<String, dynamic>;
    final avatarUrl = data['avatarUrl'] as String;


    return avatarUrl;
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    String? avatarUrl,
  }) async {
    await _attachToken();

    final payload = {
      'name': name,
      'username': username,
      'avatarUrl': avatarUrl,
    };

    payload.removeWhere((key, value) => value == null);

    final res = await _dio.patch('/user/profile', data: payload);
  }

  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    await _attachToken();

    final res = await _dio.get('/user/$username');

    final data = res.data as Map<String, dynamic>;
    return data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMeSummary() async {
    await _attachToken();

    final res = await _dio.get('/user/me/summary');

    final data = res.data as Map<String, dynamic>;
    return data['user'] as Map<String, dynamic>;
  }
}
