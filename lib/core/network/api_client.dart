import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isRefreshing = false;

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(

        /// Attach token to every request
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        /// Handle expired tokens
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final requestOptions = error.requestOptions;

          /// Prevent retry loop
          if (requestOptions.extra['retry'] == true) {
            return handler.next(error);
          }

          final refreshToken = await _storage.read(key: 'refresh_token');

          if (refreshToken == null) {
            return handler.next(error);
          }

          try {
            final newToken = await _refreshToken(refreshToken);

            if (newToken == null) {
              return handler.next(error);
            }

            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            requestOptions.extra['retry'] = true;

            final response = await dio.fetch(requestOptions);

            return handler.resolve(response);
          } catch (_) {
            return handler.next(error);
          }
        },
      ),
    );
  }

  Future<String?> _refreshToken(String refreshToken) async {
    /// Prevent multiple refresh calls
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
      return await _storage.read(key: 'auth_token');
    }

    _isRefreshing = true;

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newToken = response.data['token'];
      final newRefresh = response.data['refreshToken'];

      if (newToken != null) {
        await _storage.write(key: 'auth_token', value: newToken);
      }

      if (newRefresh != null) {
        await _storage.write(key: 'refresh_token', value: newRefresh);
      }

      return newToken;
    } catch (_) {
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}





// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class ApiClient {
//   static final ApiClient _instance = ApiClient._internal();
//   late final Dio dio;

//   factory ApiClient() => _instance;

//   ApiClient._internal() {
//     final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//         connectTimeout: const Duration(seconds: 30),
//         receiveTimeout: const Duration(seconds: 30),
//         headers: {'Content-Type': 'application/json'},
//       ),
//     );
//     // add interceptors once here if needed
//   }
// }
