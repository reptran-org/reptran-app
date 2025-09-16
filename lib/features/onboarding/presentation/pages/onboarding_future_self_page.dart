import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/future_self_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';

const _kOnboardingDraftKey = 'onboarding_draft_v1';

class OnboardingFutureSelfPage extends StatefulWidget {
  const OnboardingFutureSelfPage({super.key});

  @override
  State<OnboardingFutureSelfPage> createState() =>
      _OnboardingFutureSelfPageState();
}

class _OnboardingFutureSelfPageState extends State<OnboardingFutureSelfPage> {
  int? selectedIndex;
  bool _saving = false;

  final List<String> options = [
    "I want to be someone who never skips workouts.",
    "I want to live long & strong.",
    "I want to prove I can be disciplined.",
    "I'm not sure yet — I just want to start.",
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingDraft();
  }

  Future<void> _loadExistingDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kOnboardingDraftKey);
      if (s == null) return;
      final Map<String, dynamic> existing =
          jsonDecode(s) as Map<String, dynamic>;
      final byStep = Map<String, dynamic>.from(existing['byStep'] ?? {});
      final step3 = byStep['3'];
      if (step3 is Map && step3['futureSelf'] is String) {
        final value = step3['futureSelf'] as String;
        final idx = options.indexOf(value);
        if (idx >= 0) {
          setState(() => selectedIndex = idx);
        }
      }
    } catch (_) {
      // ignore parse errors
    }
  }

  void _onCardTap(int idx) {
    setState(() {
      if (selectedIndex == idx) {
        selectedIndex = null;
      } else {
        selectedIndex = idx;
      }
    });
  }

  Future<void> _onContinue() async {
    if (selectedIndex == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick one option to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final chosen = options[selectedIndex!];
      await OnboardingService.saveStepLocal(
        step: 3,
        data: {'futureSelf': chosen},
      );
      if (mounted) context.push('/onboarding/workout-location');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icon = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Icon(PhosphorIconsFill.sparkle, size: 40, color: scheme.onPrimary),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "When you picture your future self, which feels most true?",
      titleGradient: true, // <-- use gradient like earlier
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(options.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < options.length - 1 ? AppSpacing.sm : 0,
              ),
              child: FutureSelfCard(
                text: options[index],
                isSelected: selectedIndex == index,
                onTap: () => _onCardTap(index),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          const HelperTextCard(
            text:
                "Identity drives consistency more than goals. This helps us align with yours.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}
