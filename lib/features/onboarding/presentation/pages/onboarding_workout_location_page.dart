import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/location_option_card.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';

const _kOnboardingDraftKey = 'onboarding_draft_v1';

class OnboardingWorkoutLocationPage extends StatefulWidget {
  const OnboardingWorkoutLocationPage({super.key});

  @override
  State<OnboardingWorkoutLocationPage> createState() =>
      _OnboardingWorkoutLocationPageState();
}

class _OnboardingWorkoutLocationPageState
    extends State<OnboardingWorkoutLocationPage> {
  String? _selectedLabel;
  bool _saving = false;

  final List<_LocationOption> _options = const [
    _LocationOption(
      icon: PhosphorIconsFill.barbell,
      label: 'Gym',
      color: AppColors.primary,
    ),
    _LocationOption(
      icon: PhosphorIconsFill.house,
      label: 'Home',
      color: AppColors.secondary,
    ),
    _LocationOption(
      icon: PhosphorIconsFill.treePalm,
      label: 'Outdoors',
      color: AppColors.positive,
    ),
    _LocationOption(
      icon: PhosphorIconsFill.pencil,
      label: 'Other',
      color: Colors.grey,
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
      final step4 = byStep['4'];
      if (step4 is Map && step4['location'] is String) {
        setState(() => _selectedLabel = step4['location'] as String);
      }
    } catch (_) {}
  }

  void _onOptionTap(String label) {
    setState(() {
      _selectedLabel = _selectedLabel == label ? null : label;
    });
    OnboardingService.saveStepLocal(
      step: 4,
      data: {'location': _selectedLabel},
    );
  }

  Future<void> _onContinue() async {
    if (_selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a location to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await OnboardingService.saveStepLocal(
        step: 4,
        data: {'location': _selectedLabel},
      );
      if (mounted) context.push('/onboarding/motivation');
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
      child: Icon(PhosphorIconsFill.house, size: 40, color: scheme.onPrimary),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "Where do you usually work out (or want to)?",
      child: Column(
        children: [
          ..._options.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LocationOptionCard(
                icon: opt.icon,
                label: opt.label,
                iconColor: opt.color,
                isActive: _selectedLabel == opt.label,
                onTap: () => _onOptionTap(opt.label),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          const HelperTextCard(
            text:
                "We'll make workouts easier to stick with by shaping your environment.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}

class _LocationOption {
  final IconData icon;
  final String label;
  final Color color;
  const _LocationOption({
    required this.icon,
    required this.label,
    required this.color,
  });
}
