import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';

class WorkoutPlanBuilderService {
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

  Future<Map<String, dynamic>> getTemplatesRaw({
    int take = 20,
    int skip = 0,
  }) async {
    await _attachToken();

    final res = await _dio.get(
      '/templates',
      queryParameters: {'take': take, 'skip': skip},
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getMyWorkoutsRaw() async {
    await _attachToken();

    final res = await _dio.get('/workouts');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Optional: use later if you want template exercise preview
  Future<Map<String, dynamic>> getTemplateByIdRaw(String templateId) async {
    await _attachToken();

    final res = await _dio.get('/templates/$templateId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createRoutineRaw({
    required Map<String, dynamic> payload,
  }) async {
    await _attachToken();

    final res = await _dio.post('/routines', data: payload);
    final data = res.data as Map<String, dynamic>;

    return Map<String, dynamic>.from(data['result'] as Map);
  }

  Future<Map<String, dynamic>> updateRoutineRaw({
    required String routineId,
    required Map<String, dynamic> payload,
  }) async {
    await _attachToken();

    final res = await _dio.put('/routines/$routineId', data: payload);
    final data = res.data as Map<String, dynamic>;

    return Map<String, dynamic>.from(data['result'] as Map);
  }
}
