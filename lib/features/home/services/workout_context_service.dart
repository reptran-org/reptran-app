import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';


class WorkoutContext {
  final String source;
  final String title;

  final String? routineId;
  final String? routineDayId;
  final String? userWorkoutId;
  final String? templateId;

  // ✅ NEW (for COMPLETED_TODAY)
  final String? sessionId;
  final int? durationMin;
  final int? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;

  WorkoutContext({
    required this.source,
    required this.title,
    this.routineId,
    this.routineDayId,
    this.userWorkoutId,
    this.templateId,

    // ✅ NEW
    this.sessionId,
    this.durationMin,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
  });

  factory WorkoutContext.fromJson(Map<String, dynamic> json) {
    return WorkoutContext(
      source: json['source'],
      title: json['title'],

      routineId: json['routineId'],
      routineDayId: json['routineDayId'],
      userWorkoutId: json['userWorkoutId'],
      templateId: json['templateId'],

      // ✅ NEW (safe parsing)
      sessionId: json['sessionId'],
      durationMin: json['durationMin'],
      totalVolumeKg: json['totalVolumeKg'],
      totalSets: json['totalSets'],
      totalReps: json['totalReps'],
    );
  }
}

class WorkoutContextService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _kAuthTokenKey = 'auth_token';

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<WorkoutContext?> fetchWorkoutContext() async {
    await _attachToken();

    final res = await _dio.get('/user/workout-context');
    final data = res.data['result'];

    if (data == null) return null;
    return WorkoutContext.fromJson(data);
  }
}
