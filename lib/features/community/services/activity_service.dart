import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/core/network/api_client.dart';





class ActivityService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kAuthTokenKey = 'auth_token';

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }


  
Future<Map<String, dynamic>> getNotifications() async {
  await _attachToken();

  final res = await _dio.get('/notifications');

  final data = res.data as Map<String, dynamic>;
  return data['result']; // 👈 return full result
}

Future<void> markAllRead() async {
  await _attachToken();

  await _dio.post('/notifications/read-all');
}

 Future<void> markAsRead(String id) async {
    await _attachToken();
    await _dio.patch('/notifications/$id/read');
  }


  Future<Map<String, dynamic>> getCommunityStats() async {
  await _attachToken();

  final res = await _dio.get('/activity/community-stats');

  final data = res.data as Map<String, dynamic>;
  return data['result'] as Map<String, dynamic>;
}

  Future<List<dynamic>> getFeed() async {
    await _attachToken();

    final res = await _dio.get('/activity/feed');

    final data = res.data as Map<String, dynamic>;
    return data['result']['activities'] as List<dynamic>;
  }

 Future<Map<String, dynamic>> toggleFollow(String userId) async {
  await _attachToken();

  final res = await _dio.post('/user/follow/$userId');

  return res.data['result']; // 👈 IMPORTANT
}

Future<Map<String, dynamic>> getFollowStats() async {
  await _attachToken();

  final res = await _dio.get('/user/follow-stats');

 

  return res.data['result'];
}

Future<List<Map<String, dynamic>>> getFollowersFollowing(
    String type) async {
  await _attachToken();

  final res = await _dio.get(
    '/user/followers-following',
    queryParameters: {'type': type},
  );

  final List data = res.data['result'];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  await _attachToken();

  final res = await _dio.get(
    '/user/search',
    queryParameters: {'q': query},
  );

  final List data = res.data['result'];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<List<dynamic>> getSuggestedUsers() async {
  await _attachToken();


  final res = await _dio.get('/user/suggested');

  return res.data['result'];
}

  Future<Map<String, dynamic>> react({
  required String activityId,
  required String emoji,
}) async {
  await _attachToken();

  final res = await _dio.post(
    '/activity/$activityId/react',
    data: {'emoji': emoji},
  );

  return Map<String, dynamic>.from(res.data['result']);
}
}