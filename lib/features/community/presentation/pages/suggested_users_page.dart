// SuggestedBuildersScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class SuggestedBuildersPage extends StatelessWidget {
  const SuggestedBuildersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // ── DATA (10 unique suggestions; static) ──────────────────────────────
    final people = <_Suggestion>[
      const _Suggestion(
        'Sarah Mitchell',
        'Builder',
        '“I’m building consistency, 4x per week”',
        '12 Days',
        'Morning trainer',
      ),
      const _Suggestion(
        'Diego Alvarez',
        'Explorer',
        '“Run + mobility on weekdays”',
        '8 Days',
        'Early bird',
      ),
      const _Suggestion(
        'Priya Nair',
        'Builder',
        '“Strength + yoga split”',
        '21 Days',
        'Lunchtime',
      ),
      const _Suggestion(
        'Marcus Lee',
        'Athlete',
        '“Push/Pull/Legs – no excuses”',
        '5 Days',
        'Evening trainer',
      ),
      const _Suggestion(
        'Hannah Park',
        'Builder',
        '“Short daily sessions > long none”',
        '15 Days',
        'Morning trainer',
      ),
      const _Suggestion(
        'Jonas Becker',
        'Explorer',
        '“Walk + calisthenics”',
        '9 Days',
        'Anytime',
      ),
      const _Suggestion(
        'Fatima Zahra',
        'Builder',
        '“Pilates + strength, 3x/wk”',
        '14 Days',
        'Afternoon',
      ),
      const _Suggestion(
        'Noah Williams',
        'Athlete',
        '“CrossFit & conditioning”',
        '6 Days',
        'Morning trainer',
      ),
      const _Suggestion(
        'Aisha Khan',
        'Explorer',
        '“Daily steps + stretches”',
        '30 Days',
        'Evening trainer',
      ),
      const _Suggestion(
        'Luca Rossi',
        'Builder',
        '“Quads & core focus lately”',
        '11 Days',
        'Lunchtime',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // firstSectionHasBg: true  → NO page-level padding here
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── TOP SECTION (has its own padding & surface bg) ───────
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: AppBorders.boxCard(scheme),
                      boxShadow: AppShadows.e1(scheme),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxl, // page framing applied INSIDE
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading + subheading
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.usersThree,
                              size: 24,
                              color: scheme.onSurface,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Suggested Builders',
                              style: text.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Follow others with similar goals and streaks.',
                          style: text.bodyMedium!.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Filter pills (static)
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: const [
                            _FilterPill(
                              icon: PhosphorIconsRegular.calendarBlank,
                              label: 'Similar Schedule',
                              selected: true,
                            ),
                            _FilterPill(
                              icon: PhosphorIconsRegular.target,
                              label: 'Same Goal (4x/week)',
                            ),
                            _FilterPill(
                              icon: PhosphorIconsRegular.mapPin,
                              label: 'Nearby',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── LIST SECTION (standard horizontal padding) ───────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < people.length; i++) ...[
                          _SuggestionCard(person: people[i]),
                          if (i != people.length - 1)
                            const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ),
                  ),

                  // bottom framing only at page end
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ───────────────────────── Helpers & widgets ─────────────────────────

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _FilterPill({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = selected
        ? scheme.secondary
        : isLight
        ? AppColors.neutralLight
        : AppColors.neutralDark;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: text.bodySmall!.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _Suggestion {
  final String name;
  final String role; // e.g., Builder / Explorer / Athlete
  final String quote;
  final String streak;
  final String timePref;
  const _Suggestion(
    this.name,
    this.role,
    this.quote,
    this.streak,
    this.timePref,
  );
}

class _SuggestionCard extends StatelessWidget {
  final _Suggestion person;
  const _SuggestionCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name/role
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _InitialAvatar(initials: _initials(person.name)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: text.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    _PillTag(
                      icon: PhosphorIconsRegular.certificate,
                      label: person.role,
                      bg: isLight
                          ? AppColors.neutralLight
                          : AppColors.neutralDark,
                      fg: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Quote
          Text(person.quote, style: text.bodySmall, softWrap: true),

          const SizedBox(height: AppSpacing.sm),

          // Meta chips row
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _PillTag(
                icon: PhosphorIconsRegular.fire,
                label: person.streak,
                bg: AppColors.accent.withValues(alpha: 0.10),
                fg: AppColors.accent,
              ),
              _PillTag(
                icon: PhosphorIconsRegular.clock,
                label: person.timePref,
                bg: Theme.of(context).colorScheme.secondary.withValues(
                  alpha: 0.10,
                ),
                fg: scheme.secondary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Follow button
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow: AppShadows.e1(scheme),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.userPlus,
                          size: 24,
                          color: scheme.onSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Follow',
                          style: text.titleMedium!.copyWith(
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
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    final a = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initials;
  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          width: 2,
          color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: text.titleMedium!.copyWith(color: scheme.onSecondary),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  const _PillTag({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: text.bodySmall!.copyWith(color: fg)),
        ],
      ),
    );
  }
}
