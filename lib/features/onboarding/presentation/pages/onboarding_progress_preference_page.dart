import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/progress_pref_card.dart';

class OnboardingProgressPreferencePage extends StatefulWidget {
  const OnboardingProgressPreferencePage({super.key});

  @override
  State<OnboardingProgressPreferencePage> createState() =>
      _OnboardingProgressPreferencePageState();
}

const _kOnboardingDraftKey = 'onboarding_draft_v1';

class _OnboardingProgressPreferencePageState
    extends State<OnboardingProgressPreferencePage> {
  int? _selectedIndex;
  bool _saving = false;

  final List<_PrefOption> _options = const [
    _PrefOption(
      icon: PhosphorIconsFill.fire,
      label: "Small streaks",
      subtext: 'Daily wins and momentum tracking',
      color: AppColors.accent,
    ),
    _PrefOption(
      icon: PhosphorIconsFill.chartLineUp,
      label: "Long-term trends",
      subtext: 'Weekly and monthly progress charts',
      color: AppColors.primary,
    ),
    _PrefOption(
      icon: PhosphorIconsFill.target,
      label: "Milestones (badges)",
      subtext: 'Achievement unlocks and celebrations',
      color: AppColors.positive,
    ),
    _PrefOption(
      icon: PhosphorIconsFill.cubeTransparent,
      label: "Honest feedback, no sugarcoating",
      subtext: 'Real talk about your performance',
      color: AppColors.secondary,
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
      final Map<String, dynamic> existing =
          jsonDecode(s) as Map<String, dynamic>;
      final byStep = Map<String, dynamic>.from(existing['byStep'] ?? {});
      final step6 = byStep['6'];
      if (step6 is Map && step6['progressPreference'] is String) {
        final value = step6['progressPreference'] as String;
        final idx = _options.indexWhere((o) => o.label == value);
        if (idx >= 0) setState(() => _selectedIndex = idx);
      }
    } catch (_) {}
  }

  void _onOptionTap(int idx) {
    setState(() {
      _selectedIndex = _selectedIndex == idx ? null : idx;
    });

    final label = _selectedIndex != null
        ? _options[_selectedIndex!].label
        : null;
    OnboardingService.saveStepLocal(
      step: 6,
      data: {'progressPreference': label},
    );
  }

  Future<void> _onContinue() async {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preference to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final chosen = _options[_selectedIndex!].label;
      await OnboardingService.saveStepLocal(
        step: 6,
        data: {'progressPreference': chosen},
      );
      if (mounted) context.push('/onboarding/completion');
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
      child: Icon(
        PhosphorIconsFill.chartLineUp,
        size: 40,
        color: scheme.onPrimary,
      ),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "How do you like to see your progress?",
      child: Column(
        children: [
          ...List.generate(_options.length, (i) {
            final opt = _options[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _options.length - 1 ? 16 : 0,
              ),
              child: ProgressPrefCard(
                icon: opt.icon,
                label: opt.label,
                subtext: opt.subtext,
                iconColor: opt.color,
                selected: _selectedIndex == i,
                onTap: () => _onOptionTap(i),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          const HelperTextCard(
            text: "Your feedback loop will be built around your preference.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}

class _PrefOption {
  final IconData icon;
  final String label;
  final String subtext;
  final Color color;
  const _PrefOption({
    required this.icon,
    required this.label,
    required this.subtext,
    required this.color,
  });
}
