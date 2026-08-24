import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimezoneService {
  static String _timezone = 'UTC';

  static String get timezone => _timezone;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Try getting fresh timezone from device
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      _timezone = tzInfo.identifier;

      // 2. Save it locally
      await prefs.setString('timezone', _timezone);
    } catch (_) {
      // 3. Fallback → use cached value
      _timezone = prefs.getString('timezone') ?? 'UTC';
    }
  }
}