import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  ColorScheme _cs(BuildContext c) => Theme.of(c).colorScheme;
  bool _isLight(BuildContext c) => Theme.of(c).brightness == Brightness.light;

  @override
  Widget build(BuildContext context) {
    final cs = _cs(context);
    final isLight = _isLight(context);

    return Scaffold(
      backgroundColor: cs.surface,
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
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Notifications',
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

            // ─────────────────────────────────────────────
            // Content
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info block ────────────────────────
                  _InfoCard(cs: cs, isLight: isLight),

                  const SizedBox(height: AppSpacing.md),

                  // ── Coming soon items ─────────────────
                  _ComingSoonCard(cs: cs, isLight: isLight),
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
          // ✅ Fixed title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isLight ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  PhosphorIcons.bellRinging(),
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // ✅ IMPORTANT FIX
              Expanded(
                child: Text(
                  'Gentle support, coming soon',
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
            "We're working on thoughtful reminders designed to support your routine — not pressure you into it.",
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wRegular,
              color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
              height: AppTypography.lhNormal,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Things like a quiet nudge before your usual workout time, a rest timer alert mid-session, or a soft check-in after a few days off — reminders that feel human, not robotic.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wRegular,
              color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
              height: AppTypography.lhNormal,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ✅ This is safe already (no Row → no overflow risk)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isLight ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Notifications are not available yet',
              style: TextStyle(
                fontSize: AppTypography.micro,
                fontWeight: AppTypography.wMedium,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Coming Soon Card
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final ColorScheme cs;
  final bool isLight;

  const _ComingSoonCard({required this.cs, required this.isLight});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'What to expect',
              style: TextStyle(
                fontSize: AppTypography.caption,
                fontWeight: AppTypography.wMedium,
                color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
                letterSpacing: 0.4,
              ),
            ),
          ),

          _ComingSoonRow(
            icon: PhosphorIcons.barbell(),
            label: 'Workout Reminders',
            sublabel: 'A quiet heads-up before your usual session time.',
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

          _ComingSoonRow(
            icon: PhosphorIcons.timer(),
            label: 'Rest Timer Alerts',
            sublabel: 'Know when your rest is up without watching the clock.',
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

          _ComingSoonRow(
            icon: PhosphorIcons.arrowsCounterClockwise(),
            label: 'Consistency Nudges',
            sublabel: 'A gentle check-in if you\'ve been away for a while.',
            cs: cs,
            isLight: isLight,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable coming soon row
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final ColorScheme cs;
  final bool isLight;
  final bool isLast;

  const _ComingSoonRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.cs,
    required this.isLight,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          isLast ? AppSpacing.md : AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: isLight ? 0.06 : 0.10),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 18, color: cs.onSurface),
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
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      fontWeight: AppTypography.wRegular,
                      color: cs.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      height: AppTypography.lhNormal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: AppTypography.wMedium,
                  color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}