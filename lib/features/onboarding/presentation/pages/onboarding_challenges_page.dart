import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/option_list.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDraftKey = 'onboarding_draft_v1';

class OnboardingChallengesPage extends StatefulWidget {
  const OnboardingChallengesPage({super.key});

  @override
  State<OnboardingChallengesPage> createState() =>
      OnboardingChallengesPageState();
}

class OnboardingChallengesPageState extends State<OnboardingChallengesPage> {
  final Set<String> _selected = {};
  bool _saving = false;

  final List<Map<String, Object?>> _options = [
    {
      'icon': PhosphorIconsFill.clock,
      'label': 'Finding time',
      'color': AppColors.primary,
    },
    {
      'icon': PhosphorIconsFill.fire,
      'label': 'Staying motivated',
      'color': AppColors.accent,
    },
    {
      'icon': PhosphorIconsFill.chartLineDown,
      'label': 'Not seeing results',
      'color': Colors.grey,
    },
    {
      'icon': PhosphorIconsFill.warning,
      'label': 'Fear of failing / judgement',
      'color': AppColors.secondary,
    },
    {
      'icon': PhosphorIconsFill.question,
      'label': 'Not knowing what to do',
      'color': AppColors.positive,
    },
    {'icon': PhosphorIconsFill.pencil, 'label': 'Other', 'color': Colors.black},
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
      final step2 = byStep['2'];
      if (step2 is Map && step2['challenges'] is List) {
        final List list = step2['challenges'];
        setState(() {
          _selected.clear();
          for (final e in list) {
            if (e is String) _selected.add(e);
          }
        });
      }
    } catch (_) {
      // ignore parse errors and keep defaults
    }
  }

  void _onSelectionChanged(Set<String> selection) {
    setState(() {
      _selected
        ..clear()
        ..addAll(selection);
    });

    // autosave (fire-and-forget)
    OnboardingService.saveStepLocal(
      step: 2,
      data: {'challenges': _selected.toList()},
    );
  }

  Future<void> _onContinue() async {
    if (_selected.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one option to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await OnboardingService.saveStepLocal(
        step: 2,
        data: {'challenges': _selected.toList()},
      );
      if (mounted) context.push('/onboarding/future-self');
    } catch (_) {
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
      child: Icon(
        PhosphorIconsFill.barricade,
        size: 40,
        color: scheme.onPrimary,
      ),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "What usually gets in the way?",
      subtitle: "You can select multiple options",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionList(
            options: _options,
            multiSelect: true,
            initialSelection: _selected,
            onSelectionChanged: _onSelectionChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          const HelperTextCard(
            text:
                "We'll shape your experience around your challenges — not ignore them.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}
