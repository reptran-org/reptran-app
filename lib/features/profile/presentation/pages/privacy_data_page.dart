import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class PrivacyDataPage extends StatelessWidget {
  const PrivacyDataPage({super.key});

  ColorScheme _cs(BuildContext c) => Theme.of(c).colorScheme;
  bool _isLight(BuildContext c) => Theme.of(c).brightness == Brightness.light;

Future<void> _launchUrl(String url) async {
  try {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
}

  @override
  Widget build(BuildContext context) {
    final cs = _cs(context);
    final isLight = _isLight(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────
            // Header
            // ─────────────────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      PhosphorIcons.arrowLeft(),
                      size: 22,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Privacy & Data',
                    style: TextStyle(
                      fontSize: AppTypography.heading,
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                      height: AppTypography.lhTight,
                    ),
                  ),
                ],
              ),
            ),
const SizedBox(height: AppSpacing.md),
            // ─────────────────────────────────────────────
            // Content
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info block ────────────────────────
                  _InfoCard(cs: cs, isLight: isLight),

                  const SizedBox(height: AppSpacing.md),

                  // ── Actions card ──────────────────────
                  _ActionsCard(
                    cs: cs,
                    isLight: isLight,
                    onPrivacyPolicy: () =>
                        _launchUrl('https://reptran.site/privacy-policy'),
                    onDeleteAccount: () =>
                        _launchUrl('https://reptran.site/delete-account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final bool isLight;

  const _InfoCard({required this.cs, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isLight ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  PhosphorIcons.shieldCheck(),
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // ✅ FIX: prevent overflow
              Expanded(
                child: Text(
                  'Your data, your control',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: AppTypography.wSemibold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'RepTran stores your workouts, progress, and activity data to help you stay consistent and build habits that last.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wRegular,
              color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
              height: AppTypography.lhNormal,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Bullet points
          _InfoPoint(
            icon: PhosphorIcons.prohibit(),
            text: 'We never sell your data to third parties.',
            cs: cs,
            isLight: isLight,
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoPoint(
            icon: PhosphorIcons.chartLineUp(),
            text: 'Data is only used to support your progress.',
            cs: cs,
            isLight: isLight,
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoPoint(
            icon: PhosphorIcons.key(),
            text: 'You can delete your account and all data at any time.',
            cs: cs,
            isLight: isLight,
          ),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final bool isLight;

  const _InfoPoint({
    required this.icon,
    required this.text,
    required this.cs,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2), // slight tweak for alignment
          child: Icon(
            icon,
            size: 15,
            color: cs.primary.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),

        // already correct ✅
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wRegular,
              color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
              height: AppTypography.lhNormal,
            ),
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Actions Card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final ColorScheme cs;
  final bool isLight;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onDeleteAccount;

  const _ActionsCard({
    required this.cs,
    required this.isLight,
    required this.onPrivacyPolicy,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        children: [
          _PrivacyActionRow(
            icon: PhosphorIcons.fileText(),
            label: 'Privacy Policy',
            onTap: onPrivacyPolicy,
            cs: cs,
            isLight: isLight,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: 0.5),
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          _PrivacyActionRow(
            icon: PhosphorIcons.trash(),
            label: 'Delete Account',
            sublabel: 'This action is permanent and cannot be undone.',
            onTap: onDeleteAccount,
            isDestructive: true,
            cs: cs,
            isLight: isLight,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable action row
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final bool isDestructive;
  final ColorScheme cs;
  final bool isLight;

  const _PrivacyActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
    required this.isLight,
    this.sublabel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? cs.error
        : cs.onSurface.withValues(alpha: AppOpacities.secondary);
    final labelColor = isDestructive ? cs.error : cs.onSurface;
    final iconBg = isDestructive
        ? cs.error.withValues(alpha: isLight ? 0.08 : 0.15)
        : cs.onSurface.withValues(alpha: isLight ? 0.06 : 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        splashColor: (isDestructive ? cs.error : cs.primary).withValues(
          alpha: 0.06,
        ),
        highlightColor: (isDestructive ? cs.error : cs.primary).withValues(
          alpha: 0.04,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: AppTypography.wMedium,
                        color: labelColor,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: TextStyle(
                          fontSize: AppTypography.micro,
                          fontWeight: AppTypography.wRegular,
                          color: cs.error.withValues(alpha: 0.65),
                          height: AppTypography.lhNormal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.arrowRight(),
                size: 16,
                color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
