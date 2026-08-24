import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:flutter/foundation.dart';

class RecoveryGoal {
  final String id;
  final String label;
  final int durationMin;
  final String? templateKey;
  final String? templateId;

  RecoveryGoal({
    required this.id,
    required this.label,
    required this.durationMin,
    this.templateKey,
    this.templateId,
  });

  factory RecoveryGoal.fromJson(Map<String, dynamic> json) {
    return RecoveryGoal(
      id: json['id'],
      label: json['label'],
      durationMin: json['durationMin'],
      templateKey: json['templateKey'],
      templateId: json['templateId'],
    );
  }
}

class RecoveryData {
  final String id;
  final List<RecoveryGoal> goals;

  RecoveryData({required this.id, required this.goals});

  factory RecoveryData.fromJson(Map<String, dynamic> json) {
    return RecoveryData(
      id: json['id'],
      goals: (json['microGoals'] as List)
          .map((e) => RecoveryGoal.fromJson(e))
          .toList(),
    );
  }
}

class RecoveryService {
  final Dio _dio = ApiClient().dio;
  static const _kAuthTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

    // Future<RecoveryData?> fetchCurrentRecovery() async {
    //   await _attachToken();

    //   final res = await _dio.get('/recovery/current');

    //   final result = res.data['result'];

    //   if (result == null) return null;

    //   return RecoveryData.fromJson(result);
    // }

Future<RecoveryData?> fetchCurrentRecovery() async {
  await _attachToken();

  final res = await _dio.get('/recovery/current');


  final result = res.data['result'];

  if (result == null) {
    return null;
  }


  return RecoveryData.fromJson(result);
}

  }

