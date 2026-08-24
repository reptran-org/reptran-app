import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';

class ExerciseService {
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

  Future<Map<String, dynamic>> getExerciseDetails(
  String exerciseId,
) async {
  await _attachToken();

  final res =
      await _dio.get('/exercises/$exerciseId/details');

  return res.data['result'];
}

Future<List<dynamic>> getExercises({
  String? search,
  String? category,
  String? equipment,
  List<String>? muscles,
}) async {
  await _attachToken();

  final res = await _dio.get(
    '/exercises',
    queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null) 'category': category,
      if (equipment != null) 'equipment': equipment,
      if (muscles != null && muscles.isNotEmpty)
        'muscles': muscles.join(','),
    },
  );

  return res.data['result'] as List<dynamic>;
}

}
