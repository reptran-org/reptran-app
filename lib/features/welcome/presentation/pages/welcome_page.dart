import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

import '../widgets/welcome_header.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_cta.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final features = <_Feature>[
      _Feature(
        PhosphorIconsRegular.userCheck,
        'Identity-First Approach',
        scheme.tertiary,
      ),
      _Feature(
        PhosphorIconsRegular.testTube,
        'Science-Backed Framework',
        scheme.secondary,
      ),
      _Feature(
        PhosphorIconsRegular.heartBreak,
        'Emotional Recovery System',
        scheme.primary,
      ),
      _Feature(
        PhosphorIconsRegular.nut,
        'Environment Optimization',
        AppColors.positive,
      ),
      _Feature(
        PhosphorIconsRegular.target,
        'Minimal Overwhelm',
        scheme.tertiary,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WelcomeHeader(
                    title: 'Welcome to RepTran',
                    subtitle: 'Transform through Reps',
                    description:
                        'Evidence-based recovery system designed around your unique identity',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What do we solve?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: AppTypography.wBold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Column(
                          children: [
                            for (int i = 0; i < features.length; i++) ...[
                              FeatureCard(
                                icon: features[i].icon,
                                label: features[i].label,
                                bg: features[i].bg,
                                index: i,
                              ),
                              if (i != features.length - 1)
                                const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: AppBorders.boxCard(scheme),
                            boxShadow: AppShadows.e1(scheme),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Trusted by people transforming their lives',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: AppOpacities.secondary,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Join the movement',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: AppTypography.wBold,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        PrimaryCta(
                          onPressed: () => context.push('/auth/signup'),
                          text: 'Get Started',
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Start your transformation journey today',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurface.withValues(
                                  alpha: AppOpacities.secondary,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final Color bg;
  const _Feature(this.icon, this.label, this.bg);
}
