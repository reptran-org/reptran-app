import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/motivation_option_card.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';

const _kOnboardingDraftKey = 'onboarding_draft_v1';

class OnboardingMotivationPage extends StatefulWidget {
  const OnboardingMotivationPage({super.key});

  @override
  State<OnboardingMotivationPage> createState() =>
      _OnboardingMotivationPageState();
}

class _OnboardingMotivationPageState extends State<OnboardingMotivationPage> {
  final Set<String> _selected = {};
  bool _saving = false;

  final List<_MotivationOption> _options = const [
    _MotivationOption(
      icon: PhosphorIconsFill.chartLineUp,
      label: 'Seeing progress',
      color: AppColors.primary,
    ),
    _MotivationOption(
      icon: PhosphorIconsFill.lightning,
      label: 'Feeling energized',
      color: AppColors.accent,
    ),
    _MotivationOption(
      icon: PhosphorIconsFill.trophy,
      label: 'Sense of accomplishment',
      color: AppColors.secondary,
    ),
    _MotivationOption(
      icon: PhosphorIconsFill.handshake,
      label: 'Accountability / community',
      color: AppColors.positive,
    ),
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
      final existing = jsonDecode(s) as Map<String, dynamic>;
      final byStep = Map<String, dynamic>.from(existing['byStep'] ?? {});
      final step5 = byStep['5'];
      if (step5 is Map && step5['motivations'] is List) {
        setState(() {
          _selected.clear();
          for (final e in step5['motivations']) {
            if (e is String) _selected.add(e);
          }
        });
      }
    } catch (_) {}
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
    OnboardingService.saveStepLocal(
      step: 5,
      data: {'motivations': _selected.toList()},
    );
  }

  Future<void> _onContinue() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose at least one option to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await OnboardingService.saveStepLocal(
        step: 5,
        data: {'motivations': _selected.toList()},
      );
      if (mounted) context.push('/onboarding/progress-preference');
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
      child: Icon(PhosphorIconsFill.target, size: 40, color: scheme.onPrimary),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "What makes a workout feel rewarding for you?",
      child: Column(
        children: [
          ..._options.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MotivationOptionCard(
                icon: opt.icon,
                label: opt.label,
                iconColor: opt.color,
                selected: _selected.contains(opt.label),
                onTap: () => _toggle(opt.label),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          const HelperTextCard(
            text: "We'll align your rewards to what actually motivates you.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}

class _MotivationOption {
  final IconData icon;
  final String label;
  final Color color;
  const _MotivationOption({
    required this.icon,
    required this.label,
    required this.color,
  });
}
