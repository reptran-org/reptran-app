import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:reptran_app/core/constants/tokens.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        scheme.brightness == Brightness.dark
                            ? 'assets/images/reptran_logo_white.png'
                            : 'assets/images/reptran_logo.png',
                        height: 48,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => context.pop(),
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.e1(scheme),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.caretLeft,
                              size: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppTypography.wBold,
                    height: AppTypography.lhNormal,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      fontWeight: AppTypography.wRegular,
                      height: AppTypography.lhNormal,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
