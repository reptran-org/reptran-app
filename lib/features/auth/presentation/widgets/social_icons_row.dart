

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;

  const GoogleSignInButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/google-svg.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 12),
            Text(
              "Continue with Google",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}