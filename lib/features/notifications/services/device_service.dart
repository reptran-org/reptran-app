import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';

class DeviceService {
  final Dio _dio = ApiClient().dio;

  static const _kAuthTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _kAuthTokenKey);

  Future<void> _attachToken() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

 Future<void> registerDevice({String source = "auth_flow", String? fcmToken}) async {
  await _attachToken();

  final auth = _dio.options.headers['Authorization'];
  if (auth == null) return;

  await FirebaseMessaging.instance.requestPermission();

  final token = fcmToken ?? await FirebaseMessaging.instance.getToken();
  if (token == null || token.isEmpty) return;

  final platform = Platform.isAndroid ? "android" : "ios";

  await _dio.post('/devices/register', data: {
    "provider": "fcm",
    "token": token,
    "platform": platform,
    "meta": {"source": source},
  });
}

}
