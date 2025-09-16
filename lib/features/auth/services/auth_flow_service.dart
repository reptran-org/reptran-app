import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reptran_app/features/welcome/routes.dart';
import 'package:reptran_app/features/auth/services/auth_services.dart';
import 'package:reptran_app/core/network/api_client.dart';

const String loginRoute = '/auth/login';
const String onboardingReasonRoute = '/onboarding/reason';
const String onboardingChallengesRoute = '/onboarding/challenges';
const String onboardingFutureSelfRoute = '/onboarding/future-self';
const String onboardingWorkoutLocationRoute = '/onboarding/workout-location';
const String onboardingMotivationRoute = '/onboarding/motivation';
const String onboardingProgressRoute = '/onboarding/progress-preference';
const String onboardingCompletionRoute = '/onboarding/completion';
const String homeRoute = '/home';

class AuthFlowService {
  static final _secureStorage = const FlutterSecureStorage();
  static final Dio _dio = ApiClient().dio;

  /// Entry point to decide where the user should go.
  static Future<void> decideAndRoute(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final access = await _secureStorage.read(key: 'auth_token');
      final refresh = await _secureStorage.read(key: 'refresh_token');

      if (access == null && refresh == null) {
        final hasAccount = await AuthServices.hasAccountMarker();
        if (hasAccount) {
          if (context.mounted) context.go(loginRoute);
        } else {
          if (context.mounted) context.go(WelcomeRoutes.path);
        }
        return;
      }

      if (access != null) {
        _dio.options.headers['Authorization'] = 'Bearer $access';
        if (!context.mounted) return;

        final meOk = await _tryGetMeAndRoute(context);

        if (meOk) return;

        if (refresh != null) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            if (!context.mounted) return;

            final meOk2 = await _tryGetMeAndRoute(context);
            if (meOk2) return;
          }
        }

        await _clearTokensLocally();
        if (context.mounted) context.go(loginRoute);
        return;
      }

      if (refresh != null) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          if (!context.mounted) return;

          final meOk2 = await _tryGetMeAndRoute(context);
          if (meOk2) return;
        }
        await _clearTokensLocally();
        if (context.mounted) context.go(loginRoute);
      }
    } catch (_) {
      final hadAny = await _hasAnyToken();
      if (hadAny) {
        await _clearTokensLocally();
        if (context.mounted) context.go(loginRoute);
      } else {
        if (context.mounted) context.go(WelcomeRoutes.path);
      }
    }
  }

  static Future<bool> _hasAnyToken() async {
    final a = await _secureStorage.read(key: 'auth_token');
    final r = await _secureStorage.read(key: 'refresh_token');
    return (a != null) || (r != null);
  }

  static Future<void> _clearTokensLocally() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  static Future<bool> _tryGetMeAndRoute(BuildContext context) async {
    try {
      final resp = await _dio.get('/auth/me');
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>? ?? {};
        final onboarded = user['onboardingCompleted'] as bool? ?? false;

        if (!onboarded) {
          if (!context.mounted) return false;

          final resumed = await _routeToOnboardingResumeIfAny(context, null);
          if (!resumed) {
            if (!context.mounted) return false;
            _routeToOnboardingByStep(context, 1);
          }
        } else {
          if (context.mounted) context.go(homeRoute);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _tryRefresh() async {
    try {
      final refresh = await _secureStorage.read(key: 'refresh_token');
      if (refresh == null) return false;

      final d = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final resp = await d.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newToken != null) {
          await _secureStorage.write(key: 'auth_token', value: newToken);
          _dio.options.headers['Authorization'] = 'Bearer $newToken';
        }
        if (newRefresh != null) {
          await _secureStorage.write(key: 'refresh_token', value: newRefresh);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _routeToOnboardingResumeIfAny(
    BuildContext context,
    int? serverStep,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('onboarding_draft_v1');
      if (s == null) return false;

      final draft = jsonDecode(s) as Map<String, dynamic>;
      final byStepRaw = draft['byStep'];
      if (byStepRaw == null || byStepRaw is! Map) return false;

      final savedSteps = <int>[];
      for (final k in byStepRaw.keys) {
        final idx = int.tryParse(k.toString());
        if (idx != null) savedSteps.add(idx);
      }

      int resumeStep;
      if (savedSteps.isNotEmpty) {
        savedSteps.sort();
        resumeStep = savedSteps.last;
      } else if (serverStep != null && serverStep > 0) {
        resumeStep = serverStep;
      } else {
        resumeStep = 1;
      }
      if (!context.mounted) return false;

      _routeToOnboardingByStep(context, resumeStep);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _routeToOnboardingByStep(BuildContext context, int? step) {
    final s = step ?? 1;
    String target;
    switch (s) {
      case 1:
        target = onboardingReasonRoute;
        break;
      case 2:
        target = onboardingChallengesRoute;
        break;
      case 3:
        target = onboardingFutureSelfRoute;
        break;
      case 4:
        target = onboardingWorkoutLocationRoute;
        break;
      case 5:
        target = onboardingMotivationRoute;
        break;
      case 6:
        target = onboardingProgressRoute;
        break;
      case 7:
        target = onboardingCompletionRoute;
        break;
      default:
        target = onboardingReasonRoute;
    }

    if (context.mounted) context.go(target);
  }
}
