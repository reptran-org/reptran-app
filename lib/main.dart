import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reptran_app/core/services/theme_controller.dart';
import 'package:reptran_app/shared/services/timezone_service.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

import 'features/notifications/services/device_service.dart';
import 'features/notifications/services/local_notification_service.dart';
import 'features/notifications/notification_listener.dart';
import 'package:provider/provider.dart';
import 'features/workout/presentation/state/active_workout_controller.dart';
import 'features/workout/presentation/widgets/active_workout_bar.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

/// 🔴 Background handler (TOP LEVEL — REQUIRED)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalNotificationService.init();

  final data = message.data;

  final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
    2147483647,
  );

  final type = data['type'];

  if (type == 'trigger.workout_nudge') {
    await LocalNotificationService.showWorkoutNudge(
      id: notificationId,
      title: data['title'] ?? 'Workout time',
      body: data['body'] ?? '',
      payload: data,
    );
  } else {
    // 🔥 reaction + future notifications
    await LocalNotificationService.showSimpleNotification(
      id: notificationId,
      title: data['title'] ?? 'New notification',
      body: data['body'] ?? '',
      payload: data,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TimezoneService.init();

  /// 🌱 ENV
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  /// 🔥 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  /// 🔔 Permissions
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (_) {}

  /// 🔔 Local notifications
  try {
    await LocalNotificationService.init();
  } catch (_) {}

  /// 🔔 Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  /// 🔄 Token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      await DeviceService().registerDevice(
        source: "token_refresh",
        fcmToken: newToken,
      );
    } catch (_) {}
  });

  /// 🧠 Stabilize startup (optional)
  await Future.delayed(const Duration(milliseconds: 100));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => ActiveWorkoutController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.mode, // ✅ LIVE
            routerConfig: appRouter,
            // builder: (context, child) {
            //   return NotificationListenerWidget(
            //     child: Stack(
            //       children: [
            //         child ?? const SizedBox.shrink(),
            //         const ActiveWorkoutBar(),
            //       ],
            //     ),
            //   );
            // },
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);

              // ✅ Clamp system font scaling (NEW API)
              final clampedMediaQuery = mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.15,
                ),
              );

              return MediaQuery(
                data: clampedMediaQuery,
                child: NotificationListenerWidget(
                  child: Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const ActiveWorkoutBar(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
