import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/option_card.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/helper_text_card.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';

class OnboardingReasonPage extends StatefulWidget {
  const OnboardingReasonPage({super.key});

  @override
  State<OnboardingReasonPage> createState() => _OnboardingReasonPageState();
}

class _OnboardingReasonPageState extends State<OnboardingReasonPage> {
  String? _selectedLabel;
  bool _saving = false;

  final _options = [
    {
      'icon': PhosphorIconsFill.barbell,
      'label': 'Get stronger',
      'color': AppColors.primary,
    },
    {
      'icon': PhosphorIconsFill.heart,
      'label': 'Improve health',
      'color': AppColors.positive,
    },
    {
      'icon': PhosphorIconsFill.brain,
      'label': 'Build discipline',
      'color': AppColors.secondary,
    },
    {
      'icon': PhosphorIconsFill.lightning,
      'label': 'Lose fat / look better',
      'color': AppColors.accent,
    },
    {'icon': PhosphorIconsFill.pencil, 'label': 'Other', 'color': null},
  ];

  Future<void> _onContinue() async {
    if (_selectedLabel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a reason to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await OnboardingService.saveStepLocal(
        step: 1,
        data: {'reason': _selectedLabel},
      );
      if (!mounted) return;
      context.push('/onboarding/challenges');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      child: Icon(PhosphorIconsFill.barbell, size: 40, color: scheme.onPrimary),
    );

    return OnboardingScaffold(
      icon: icon,
      title: "What's your main reason for working out?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final opt in _options) ...[
            OptionCard(
              icon: opt['icon'] as IconData,
              label: opt['label'] as String,
              selected: _selectedLabel == opt['label'],
              onTap: () =>
                  setState(() => _selectedLabel = opt['label'] as String),
              iconColor: opt['color'] as Color?,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: AppSpacing.md),
          const HelperTextCard(
            text:
                "Knowing your 'why' keeps you anchored when motivation fades.",
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingCtaButton(onPressed: _onContinue, loading: _saving),
        ],
      ),
    );
  }
}
