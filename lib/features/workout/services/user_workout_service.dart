import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'dart:convert';

class UserWorkoutService {
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

  Future<Map<String, dynamic>> getSessionHistoryDetails(
  String sessionId,
) async {
  await _attachToken();

  final res = await _dio.get('/sessions/history/$sessionId');

  return res.data['result'];
}

  Future<Map<String, dynamic>> getWorkoutHistory({
  Map<String, dynamic>? cursor,
}) async {
  await _attachToken();


  final response = await _dio.get(
    '/sessions/history',
    queryParameters: {
      if (cursor != null) 'cursor': jsonEncode(cursor),
      'limit': 10,
    },
  );

  return response.data['result'];
}

  Future<Map<String, dynamic>> createWorkout({
    String? title,
    String? description,
    bool isPublic = false,
  }) async {
    await _attachToken();

    final data = {
  if (title != null) "title": title,
  if (description != null) "description": description,
  "isPublic": isPublic,
};

  final res = await _dio.post(
  '/workouts',
  data: data,
);

    return res.data['result'];
  }

  Future<void> saveWorkout({
  required String workoutId,
  required Map<String, dynamic> payload,
}) async {
  await _attachToken();

  await _dio.put(
    '/workouts/$workoutId',
    data: payload,
  );
}

  Future<Map<String, dynamic>> getWorkout(String workoutId) async {
    await _attachToken();
    final res = await _dio.get('/workouts/$workoutId');
    return res.data['result'];
  }

  Future<Map<String, dynamic>> updateWorkout({
    required String workoutId,
    required String title,
  }) async {
    await _attachToken();
    final res = await _dio.patch(
      '/workouts/$workoutId',
      data: {"title": title},
    );
    return res.data['result'];
  }

  Future<Map<String, dynamic>> addSet({
    required String workoutId,
    required String workoutExerciseId,
  }) async {
    await _attachToken();
   
    final res = await _dio.post(
      '/workouts/$workoutId/exercises/$workoutExerciseId/sets',
    );
    return res.data['result'];
  }

  Future<Map<String, dynamic>> updateSet({
    required String workoutId,
    required String workoutExerciseId,
    required String setId,
    double? weightKg,
    int? reps,
  }) async {
    await _attachToken();

    final res = await _dio.patch(
      '/workouts/$workoutId/exercises/$workoutExerciseId/sets/$setId',
      data: {"weightKg": weightKg, "reps": reps},
    );

    return res.data['result'];
  }

  Future<void> deleteSet({
    required String workoutId,
    required String workoutExerciseId,
    required String setId,
  }) async {
    await _attachToken();
    await _dio.delete(
      '/workouts/$workoutId/exercises/$workoutExerciseId/sets/$setId',
    );
  }

  Future<void> removeExercise({
    required String workoutId,
    required String workoutExerciseId,
  }) async {
    await _attachToken();
    await _dio.delete('/workouts/$workoutId/exercises/$workoutExerciseId');
  }

  Future<Map<String, dynamic>> addExercisesToWorkout({
    required String workoutId,
    required List<String> exerciseIds,
  }) async {
    await _attachToken();

    final res = await _dio.post(
      '/workouts/$workoutId/exercises',
      data: {"exerciseIds": exerciseIds},
    );

    return res.data['result'];
  }

  Future<List<dynamic>> getMyWorkouts() async {
    await _attachToken();
    final res = await _dio.get('/workouts');
    return (res.data['result'] ?? []) as List<dynamic>;
  }

  Future<void> deleteWorkout({required String workoutId}) async {
  await _attachToken();
  await _dio.delete('/workouts/$workoutId');
}

}
