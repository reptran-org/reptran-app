import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:reptran_app/features/workout/models/workout_template.dart';
import 'package:flutter/material.dart';


class SessionService {
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

  Future<Map<String, dynamic>?> getActiveSession() async {
  await _attachToken();

  final res = await _dio.get('/sessions/active');

  if (res.data['result'] == null) {
    return null;
  }

  return Map<String, dynamic>.from(res.data['result']);
}

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    await _attachToken();

    final res = await _dio.get('/sessions/$sessionId');

    return Map<String, dynamic>.from(res.data['result']);
  }

  Future<Map<String, dynamic>> startSession({
    String? userWorkoutId,
    String? templateId,
  }) async {
    await _attachToken();

    final res = await _dio.post(
      '/sessions/start',
      data: {
        if (userWorkoutId != null) "userWorkoutId": userWorkoutId,
        if (templateId != null) "templateId": templateId,
      },
    );

    return res.data['result'];
  }

  Future<void> updateExerciseNotes({
    required String sessionId,
    required String sessionExerciseId,
    required String notes,
  }) async {
    await _attachToken();

    await _dio.patch(
      '/sessions/$sessionId/exercises/$sessionExerciseId/notes',
      data: {"notes": notes},
    );
  }

  Future<void> updateRestTime({
    required String sessionId,
    required String sessionExerciseId,
    required int? restSeconds,
  }) async {
    await _attachToken();

    await _dio.patch(
      '/sessions/$sessionId/exercises/$sessionExerciseId/rest',
      data: {"restSeconds": restSeconds},
    );
  }

  Future<Map<String, dynamic>> addExercisesToSession({
    required String sessionId,
    required List<String> exerciseIds,
  }) async {
    await _attachToken();

    final res = await _dio.post(
      '/sessions/$sessionId/exercises',
      data: {"exerciseIds": exerciseIds},
    );

    return res.data['result'];
  }

  Future<List<dynamic>> getRecentSessions() async {
  await _attachToken();

  final res = await _dio.get('/sessions/recent');

  return List.from(res.data['result']);
}



  Future<Map<String, dynamic>> addSet({
    required String sessionId,
    required String sessionExerciseId,
  }) async {
    await _attachToken();

    final res = await _dio.post(
      '/sessions/$sessionId/exercises/$sessionExerciseId/sets',
    );

    return res.data['result'];
  }

Future<void> updateExerciseEffort({
  required String sessionId,
  required String sessionExerciseId,
  required int? howHard,
}) async {
  await _attachToken();



  await _dio.patch(
    '/sessions/$sessionId/exercises/$sessionExerciseId/effort',
    data: {
      "howHard": howHard,
    },
  );
}

Future<void> reorderExercises({
  required String sessionId,
  required List<String> exerciseIds,
}) async {
  await _attachToken();

  await _dio.patch(
    '/sessions/$sessionId/exercises/reorder',
    data: {
      "exerciseIds": exerciseIds,
    },
  );
}


  Future<Map<String, dynamic>> addDropSet({
  required String sessionId,
  required String sessionExerciseId,
  required String parentSetId,
}) async {
  await _attachToken();

  final res = await _dio.post(
    '/sessions/$sessionId/exercises/$sessionExerciseId/drop-set/$parentSetId',
  );

  return res.data['result'];
}

 Future<Map<String, dynamic>> updateSet({
  required String sessionId,
  required String sessionExerciseId,
  required String setId,
  double? weightKg,
  int? reps,
  int? durationSec, // ✅ ADD
  bool? completed,
}) async {
  await _attachToken();

  final body = <String, dynamic>{};

  if (weightKg != null) body['weightKg'] = weightKg;
  if (reps != null) body['reps'] = reps;
  if (durationSec != null) body['durationSec'] = durationSec; // ✅ ADD
  if (completed != null) body['completed'] = completed;

  final res = await _dio.put(
    '/sessions/$sessionId/exercises/$sessionExerciseId/sets/$setId',
    data: body,
  );

  return res.data['result'];
}


  Future<void> deleteSet({
    required String sessionId,
    required String sessionExerciseId,
    required String setId,
  }) async {
    await _attachToken();

    await _dio.delete(
      '/sessions/$sessionId/exercises/$sessionExerciseId/sets/$setId',
    );
  }

  Future<void> createSuperset({
  required String sessionId,
  required List<String> exerciseIds,
}) async {
  await _attachToken();

  await _dio.post(
    '/sessions/$sessionId/supersets',
    data: {
      "exerciseIds": exerciseIds,
    },
  );
}

Future<void> removeSuperset({
  required String sessionId,
  required String exerciseId,
}) async {
  await _attachToken();

  await _dio.delete(
    '/sessions/$sessionId/supersets/$exerciseId',
  );
}

Future<void> replaceExercise({
  required String sessionId,
  required String sessionExerciseId,
  required String exerciseId,
}) async {
  await _attachToken();

  await _dio.put(
    '/sessions/$sessionId/exercises/$sessionExerciseId/replace',
    data: {
      "exerciseId": exerciseId,
    },
  );
}

  Future<void> removeExercise({
    required String sessionId,
    required String sessionExerciseId,
  }) async {
    await _attachToken();

    await _dio.delete('/sessions/$sessionId/exercises/$sessionExerciseId');
  }

  Future<void> discardSession({required String sessionId}) async {
    await _attachToken();
    await _dio.delete('/sessions/$sessionId');
  }

  Future<Map<String, dynamic>> endSession({required String sessionId}) async {
    await _attachToken();

    final res = await _dio.post('/sessions/$sessionId/end');
    return res.data['result'];
  }

  Future<Map<String, dynamic>> getFeedbackScreenData({
    required String sessionId,
  }) async {
    await _attachToken();

    final res = await _dio.get('/sessions/$sessionId/feedback-screen');
    return res.data['result'];
  }

  Future<Map<String, dynamic>> submitSessionReflection({
    required String sessionId,
    String? mood,
    int? challengeRating, // 1..10
    String? note,
  }) async {
    await _attachToken();

    final data = <String, dynamic>{};

    if (mood != null) data["mood"] = mood;
    if (challengeRating != null) data["challengeRating"] = challengeRating;

    final cleanedNote = note?.trim();
    if (cleanedNote != null && cleanedNote.isNotEmpty) {
      data["note"] = cleanedNote;
    }

    final res = await _dio.post('/sessions/$sessionId/reflection', data: data);

    return res.data['result'];
  }

  Future<Map<String, dynamic>> getSessionRewards({
    required String sessionId,
  }) async {
    await _attachToken();

    final res = await _dio.get('/sessions/$sessionId/rewards');
    return res.data['result'];
  }

  Future<Map<String, dynamic>> getSessionSummary({
    required String sessionId,
  }) async {
    await _attachToken();

    final res = await _dio.get('/sessions/$sessionId/summary');
    return res.data['result'];
  }

  Future<List<WorkoutTemplateModel>> getTemplates({
    String? category, // STARTER / STANDARD / QUICK
    String? search,
    List<String>? tags,
  }) async {
    await _attachToken();

    final res = await _dio.get(
      '/templates',
      queryParameters: {
        if (category != null) 'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );

    final result = res.data['result'];

    final list = (result['templates'] as List<dynamic>? ?? []);
    return list
        .map((e) => WorkoutTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutTemplateDetailsModel> getTemplateDetails(
    String templateId,
  ) async {
    await _attachToken();

    final res = await _dio.get('/templates/$templateId');
    return WorkoutTemplateDetailsModel.fromJson(res.data['result']);
  }
}
