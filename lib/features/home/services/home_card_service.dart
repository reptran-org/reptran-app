import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';


class HomeCardData {
  final String? name;
  final String? futureSelf;
  final String? avatarUrl;
  final int weeklyCount;
  final int weeklyIntent;
  final int streakDays;
  final bool shouldShowIntentModal; // ✅ NEW

  HomeCardData({
    this.name,
    this.futureSelf,
    this.avatarUrl,
    required this.weeklyCount,
    required this.weeklyIntent,
    required this.streakDays,
    required this.shouldShowIntentModal, // ✅
  });

  factory HomeCardData.fromJson(Map<String, dynamic> json) {
    return HomeCardData(
      name: json['name'],
      futureSelf: json['futureSelf'],
      avatarUrl: json['avatarUrl'],
      weeklyCount: json['weeklyCount'] ?? 0,
      weeklyIntent: json['weeklyIntent'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      shouldShowIntentModal: json['shouldShowIntentModal'] ?? false, // ✅
    );
  }
}


class HomeCardService {
  final Dio _dio = ApiClient().dio;
  static const _kAuthTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<HomeCardData> fetchHomeCardData() async {
    await _attachToken();

    final res = await _dio.get('/user/homecard-data');

    final data = res.data['result'];
    return HomeCardData.fromJson(data);
  }

  Future<void> updateWeeklyIntent(int weeklyIntent) async {
  await _attachToken();

  await _dio.post(
    '/identity/weekly-intent',
    data: {
      'weeklyIntent': weeklyIntent,
    },
  );
}
}
