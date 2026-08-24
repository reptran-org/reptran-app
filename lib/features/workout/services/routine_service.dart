import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';

class RoutineService {
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

  /// GET /routines?includeArchived=true|false
Future<Map<String, dynamic>> getMyRoutines({bool includeArchived = false}) async {
  await _attachToken();

  final res = await _dio.get(
    '/routines',
    queryParameters: {
      'includeArchived': includeArchived,
    },
  );

  final data = res.data as Map<String, dynamic>;
  return data['result'] as Map<String, dynamic>;
}

Future<void> setActiveRoutine(String routineId) async {
  await _attachToken();

  await _dio.patch('/routines/$routineId/set-active');
}

Future<void> skipRoutine(String routineId) async {
  await _attachToken();
  await _dio.post('/routines/$routineId/skip');
}

Future<void> realignRoutine(String routineId, int dayIndex) async {
  await _attachToken();

  await _dio.post(
    '/routines/$routineId/realign',
    data: {"dayIndex": dayIndex},
  );
}

Future<void> pauseRoutine(String routineId) async {
  await _attachToken();
  await _dio.post('/routines/$routineId/pause');
}

Future<void> resumeRoutine(String routineId) async {
  await _attachToken();
  await _dio.post('/routines/$routineId/resume');
}

  /// GET /routines/:id
  Future<Map<String, dynamic>> getRoutineById({
    required String routineId,
  }) async {
    await _attachToken();

    final res = await _dio.get('/routines/$routineId');
    final data = res.data as Map<String, dynamic>;

    return Map<String, dynamic>.from(data['result'] as Map);
  }

  /// PATCH /routines/:id/archive  (soft delete)
  Future<void> archiveRoutine({required String routineId}) async {
    await _attachToken();
    await _dio.patch('/routines/$routineId/archive');
  }

  /// PATCH /routines/:id/unarchive
  Future<void> unarchiveRoutine({required String routineId}) async {
    await _attachToken();
    await _dio.patch('/routines/$routineId/unarchive');
  }

  /// DELETE /routines/:id (permanent delete)
  Future<void> deleteRoutinePermanently({required String routineId}) async {
    await _attachToken();
    await _dio.delete('/routines/$routineId');
  }
}
