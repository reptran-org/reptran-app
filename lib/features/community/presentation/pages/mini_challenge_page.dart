import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class MiniChallengePage extends StatelessWidget {
  const MiniChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.xxl,
            bottom: AppSpacing.xxl,
            left: AppSpacing.md,
            right: AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------------- First Card: Mini Challenge ----------------
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 60x60 icon container (accent bg, 32px white icon)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            PhosphorIconsRegular.fireSimple,
                            size: 32,
                            color: AppColors.whiteUtility,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Pill: only text, bg = scheme.primary, text = primary
                        Builder(
                          builder: (context) {
                            final scheme = Theme.of(context).colorScheme;
                            final tt = Theme.of(context).textTheme;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(
                                  alpha: 0.10,
                                ), // bg as requested
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'MINI CHALLENGE',
                                style: tt.labelMedium?.copyWith(
                                  // text color = primary (as requested)
                                  // If you want higher contrast, switch to scheme.onPrimary.
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Title + description
                        Builder(
                          builder: (context) {
                            final tt = Theme.of(context).textTheme;
                            final scheme = Theme.of(context).colorScheme;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No Misses!', style: tt.headlineSmall),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Stay active for 3 consecutive days — rebuild your streak.',
                                  style: tt.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: AppOpacities.secondary,
                                    ),
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ---------------- Progress Card ----------------
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Spiral icon beside "Your Progress"
                            Icon(
                              PhosphorIconsRegular.spiral,
                              size: 24,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),

                            Expanded(
                              child: Text(
                                'Your Progress',
                                style: tt.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),

                            // Pill at the end: bg primary @10%, icon accent, text primary
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.fireSimple,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Day 2/3',
                                    style: tt.labelMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Progress bar: 12px height, track=outline, bar=secondary
                        _ProgressBar(
                          progress: 2 / 3,
                          height: 12,
                          trackColor: scheme.outline,
                          barColor: scheme.secondary,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        Text('Day 2 of 3 Complete', style: tt.bodySmall),

                        const SizedBox(height: AppSpacing.sm),

                        Row(
                          children: [
                            Expanded(
                              child: _DayPill(
                                labelTop: 'DAY 1',
                                checked: true,
                                backgroundColor: scheme.secondary.withValues(
                                  alpha: 0.10,
                                ),
                                borderColor: scheme.secondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _DayPill(
                                labelTop: 'DAY 2',
                                checked: true,
                                backgroundColor: scheme.secondary.withValues(
                                  alpha: 0.10,
                                ),
                                borderColor: scheme.secondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _DayPill(
                                labelTop: 'DAY 3',
                                checked: false,
                                backgroundColor: scheme.secondary.withValues(
                                  alpha: 0.10,
                                ),
                                borderColor: scheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------------- Community Card ----------------
                  _Card(
                    child: Builder(
                      builder: (context) {
                        final scheme = Theme.of(context).colorScheme;
                        final tt = Theme.of(context).textTheme;
                        final isLight =
                            Theme.of(context).brightness == Brightness.light;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.usersThree,
                                  size: 24,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Community',
                                    style: tt.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Avatars + copy
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Overlapping initials
                                Expanded(
                                  child: _InitialAvatarStack(
                                    labels: const ['M', 'J', 'T', 'P', '+14'],
                                    // 40px circles with ~12px overlap
                                    itemSize: 40,
                                    overlap: 12,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                // Right text
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '+128 people',
                                        style: tt.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'joined this challenge',
                                        style: tt.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // Bottom pill
                            Container(
                              width: double
                                  .infinity, // let the pill take full card width
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                                horizontal: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? AppColors.neutralLight
                                    : AppColors.neutralDark,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.max, // <-- key change
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.pulse,
                                    size: 20,
                                    color: scheme.secondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    // <-- gives RichText a width so it can wrap
                                    child: Text.rich(
                                      TextSpan(
                                        style: tt.bodySmall?.copyWith(
                                          color: scheme.onSurface,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '82% ',
                                            style: tt.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(
                                            text:
                                                'completion rate in the last 24 hours',
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------------- Reward Preview Card ----------------
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.gift,
                              size: 24,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Reward Preview',
                                style: tt.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Row(
                          children: [
                            // POSITIVE tile
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 160,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.positive.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.lg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.positive,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.whiteUtility,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            PhosphorIconsRegular.lightning,
                                            size: 24,
                                            color: AppColors.positive,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        '100',
                                        style: tt.headlineSmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('POINTS', style: tt.labelSmall),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: AppSpacing.sm),

                            // ACCENT tile
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 160,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.lg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.whiteUtility,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            // swap to PhosphorIconsRegular.ribbon / medal if you want a badge icon
                                            PhosphorIconsRegular.mapPin,
                                            size: 24,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Bounce\nBack Badge',
                                        style: tt.bodyMedium,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------------- Join Button ----------------
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: AppShadows.e1(scheme),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.lightning,
                                  size: 24,
                                  color: scheme.onSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'JOIN CHALLENGE',
                                  style: tt.titleMedium!.copyWith(
                                    color: scheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

// =============== Reusable Helpers ===============

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.leading});

  final String label;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: AppBorders.boxOnePx(scheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading!, size: 24, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: tt.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    this.height = 12,
    this.trackColor,
    this.barColor,
    this.radius,
  });

  final double progress;
  final double height;
  final Color? trackColor;
  final Color? barColor;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = radius ?? BorderRadius.circular(AppRadii.sm);

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: r, // rounds the track edges
        child: Stack(
          children: [
            // Track
            Container(
              height: height,
              color:
                  (trackColor ??
                  scheme.outline.withValues(alpha: AppOpacities.tertiary)),
            ),
            // Fill with its own radius so the trailing edge is rounded too
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: (barColor ?? scheme.secondary),
                  borderRadius: r, // <-- key line
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.labelTop,
    required this.checked,
    this.backgroundColor,
    this.borderColor,
  });

  final String labelTop;
  final bool checked;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Color bg =
        backgroundColor ?? scheme.secondary.withValues(alpha: 0.10);
    final Color br = borderColor ?? scheme.secondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg, // secondary @ 10%
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: br, width: 1), // 1px secondary
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checked
                ? PhosphorIconsRegular.checkCircle
                : PhosphorIconsRegular.circle,
            size: 24,
            color: checked
                ? scheme.secondary
                : scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(labelTop, style: tt.bodySmall, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.label, this.size = 40, super.key});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.whiteUtility,
          width: 2, // exact 2px border
        ),
      ),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          color: AppColors.whiteUtility,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InitialAvatarStack extends StatelessWidget {
  const _InitialAvatarStack({
    required this.labels,
    this.itemSize = 40,
    this.overlap = 12,
    super.key,
  });

  final List<String> labels;
  final double itemSize;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        (labels.length * itemSize) - ((labels.length - 1) * overlap);
    return SizedBox(
      height: itemSize,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < labels.length; i++)
            Positioned(
              left: i * (itemSize - overlap),
              child: _InitialCircle(label: labels[i], size: itemSize),
            ),
        ],
      ),
    );
  }
}
