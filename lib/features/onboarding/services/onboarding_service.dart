import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kOnboardingDraftKey = 'onboarding_draft_v1';

class OnboardingService {
  static Future<void> saveStepLocal({
    required int step,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOnboardingDraftKey);
    Map<String, dynamic> draft = {
      'version': 1,
      'currentStep': step,
      'byStep': {'$step': data},
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (raw != null) {
      try {
        final existing = jsonDecode(raw) as Map<String, dynamic>;
        final byStep = Map<String, dynamic>.from(existing['byStep'] ?? {});
        byStep['$step'] = data;
        draft = {
          'version': existing['version'] ?? 1,
          'currentStep': step,
          'byStep': byStep,
          'updatedAt': DateTime.now().toIso8601String(),
        };
      } catch (_) {
        // If parse fails, overwrite with fresh draft
      }
    }

    await prefs.setString(_kOnboardingDraftKey, jsonEncode(draft));
  }

  /// Optional: read full draft
  static Future<Map<String, dynamic>?> readDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOnboardingDraftKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Optional: clear draft after completion
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboardingDraftKey);
  }
}
