import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:go_router/go_router.dart';

class SessionSummaryPage extends StatefulWidget {
  const SessionSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends State<SessionSummaryPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _data;
  bool _progressExpanded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDurations.long,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fetch();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await SessionService().getSessionSummary(
        sessionId: widget.sessionId,
      );
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load summary. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Loading summary…",
                  style: textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: scheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                      border: AppBorders.boxOnePx(scheme),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.warningCircle,
                      size: 32,
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "Summary unavailable",
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Please try again.",
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PrimaryButton(
                    label: "Retry",
                    icon: PhosphorIconsRegular.arrowClockwise,
                    onPressed: () {
                      setState(() => _loading = true);
                      _fetch();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final data = _data!;

    List<dynamic> _normalizeToList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      if (value is Map) return [value];
      return [];
    }

    final session = (data["session"] as Map<String, dynamic>?) ?? {};
    final adaptive = (data["adaptive"] as Map<String, dynamic>?) ?? {};
    final ctas = _normalizeToList(adaptive["ctas"]);
    final headline = (adaptive["headline"] as Map<String, dynamic>?) ?? {};
    final rewards = (data["rewards"] as Map<String, dynamic>?) ?? {};
    final reflection = data["reflection"];
    final stats = (data["stats"] as Map<String, dynamic>?) ?? {};
    final weeklyRaw = _normalizeToList(data["weekly"]);
    final exercisesRaw = _normalizeToList(data["exercises"]);

    final headlineTitle = (headline["title"] as String?) ?? "Session Complete";
    final headlineMessage =
        (headline["message"] as String?) ??
        "Strong work today. You're one step closer to your goal.";

    final durationMin = _toIntOrNull(session["durationMin"]);
    final totalSets = _toIntOrNull(session["totalSets"]);
    final totalReps = _toIntOrNull(session["totalReps"]);
    final totalVolumeKg = _toNumOrNull(session["totalVolumeKg"]);

    final points = (rewards["points"] as Map<String, dynamic>?) ?? {};
    final pointsEarned = _toInt(points["earnedThisSession"]);
    final badges = (rewards["badges"] as Map<String, dynamic>?) ?? {};
    final earnedBadges = _normalizeToList(badges["earnedThisSession"]);

    final reflectionExists = reflection != null;
    final reflectionMap =
        reflectionExists ? (reflection as Map<String, dynamic>) : null;
    final moodRaw = reflectionMap?["mood"] as String?;
    final challengeRating = _toIntOrNull(reflectionMap?["challengeRating"]);
    final reflectionNote = reflectionMap?["note"] as String?;

    final streakDays = _toIntOrNull(stats["streakDays"]);
    final weeklyCount = _toIntOrNull(stats["weeklyCount"]);
    final totalSessions = _toIntOrNull(stats["totalSessions"]);
    final gapDays = _toIntOrNull(stats["gapDays"]);

    final insightCard =
        (adaptive["insightCard"] as Map<String, dynamic>?) ?? {};
    final insightTitle = _stringOrFallback(
      insightCard["title"],
      fallback: "You're proving it day after day",
    );
    final insightMessage = _stringOrFallback(
      insightCard["message"],
      fallback:
          "This is what a consistent builder looks like. Keep building your identity through action.",
    );

    final weekly = weeklyRaw.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return {
        "date": m["date"],
        "sessions": _toInt(m["sessions"]),
        "points": _toInt(m["points"]),
      };
    }).toList();

    final showedUpDays = weekly.where((d) => _toInt(d["sessions"]) > 0).length;

    final exercises = exercisesRaw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    final exerciseNames = exercises
        .map((e) => (e["name"] as String?)?.trim() ?? "")
        .where((n) => n.isNotEmpty)
        .toList();

    final firstBadgeWrap = earnedBadges.isNotEmpty
        ? (earnedBadges.first as Map).cast<String, dynamic>()
        : null;
    final badge = (firstBadgeWrap?["badge"] as Map?)?.cast<String, dynamic>();
    final badgeTitle =
        (badge?["title"] as String?) ??
        (badge?["name"] as String?) ??
        "Badge unlocked";
    final badgeDesc = (badge?["description"] as String?) ?? "New badge earned.";

    return Scaffold(
      backgroundColor: scheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HERO HEADER ──────────────────────────────────────
                    _HeroHeader(
                      headlineTitle: headlineTitle,
                      headlineMessage: headlineMessage,
                      pointsEarned: pointsEarned,
                      streakDays: streakDays,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── STAT STRIP ─────────────────────────────────
                          _StatStrip(
                            durationMin: durationMin,
                            totalVolumeKg: totalVolumeKg,
                            totalSets: totalSets,
                            totalReps: totalReps,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── POINTS + BADGE ─────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _PointsCard(
                                    pointsEarned: pointsEarned,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: _BadgeCard(
                                    earnedBadges: earnedBadges,
                                    badgeTitle: badgeTitle,
                                    badgeDesc: badgeDesc,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── EXERCISES ──────────────────────────────────
                          if (exerciseNames.isNotEmpty) ...[
                            _ExercisesCard(exerciseNames: exerciseNames),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // ── REFLECTION ─────────────────────────────────
                          if (reflectionExists) ...[
                            _ReflectionCard(
                              moodRaw: moodRaw,
                              challengeRating: challengeRating,
                              reflectionNote: reflectionNote,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // ── WEEKLY CONSISTENCY ─────────────────────────
                          _WeeklyCard(
                            weekly: weekly,
                            showedUpDays: showedUpDays,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── PROGRESS & ANALYTICS ───────────────────────
                          _ProgressCard(
                            streakDays: streakDays,
                            weeklyCount: weeklyCount,
                            totalSessions: totalSessions,
                            gapDays: gapDays,
                            expanded: _progressExpanded,
                            onToggle: () => setState(
                              () => _progressExpanded = !_progressExpanded,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── INSIGHT BANNER ─────────────────────────────
                          _InsightBanner(
                            title: insightTitle,
                            message: insightMessage,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── CTA ────────────────────────────────────────
                          _PrimaryButton(
                            label: _ctaLabel(
                              ctas,
                              index: 0,
                              fallback: 'Back to Home',
                            ),
                            icon: PhosphorIconsRegular.house,
                            onPressed: () => context.push('/home'),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── FOOTER ─────────────────────────────────────
                          Center(
                            child: Text(
                              '"Small steps, strong identity. Keep showing up."',
                              style: textTheme.labelSmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: AppOpacities.tertiary),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HERO HEADER
// ═══════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final String headlineTitle;
  final String headlineMessage;
  final int pointsEarned;
  final int? streakDays;

  const _HeroHeader({
    required this.headlineTitle,
    required this.headlineMessage,
    required this.pointsEarned,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.secondary,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.whiteUtility.withValues(
                alpha: AppOpacities.disabled,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.whiteUtility.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: const Icon(
              PhosphorIconsRegular.checkCircle,
              size: 28,
              color: AppColors.whiteUtility,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headlineTitle,
            style: textTheme.headlineSmall!.copyWith(
              color: AppColors.whiteUtility,
              fontWeight: AppTypography.wBold,
              height: AppTypography.lhTight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            headlineMessage,
            style: textTheme.bodyMedium!.copyWith(
              color: AppColors.whiteUtility.withValues(alpha: 0.80),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Points / streak pill
          Row(
            children: [
              _HeroPill(
                icon: PhosphorIconsRegular.sparkle,
                label: pointsEarned > 0 ? "+$pointsEarned pts" : "0 pts",
              ),
              if (streakDays != null && streakDays! > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                _HeroPill(
                  icon: PhosphorIconsRegular.fire,
                  label: "$streakDays day streak",
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteUtility.withValues(alpha: AppOpacities.disabled),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: AppColors.whiteUtility.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.whiteUtility),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wSemibold,
              color: AppColors.whiteUtility,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STAT STRIP — Duration / Volume / Sets / Reps in a horizontal scroll-safe row
// ═══════════════════════════════════════════════════════════════════

class _StatStrip extends StatelessWidget {
  final int? durationMin;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;

  const _StatStrip({
    required this.durationMin,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.totalReps,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Pull the card up over the hero gradient
    return Transform.translate(
      offset: const Offset(0, -AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e3(scheme),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _StatCell(
              icon: PhosphorIconsRegular.timer,
              label: 'Duration',
              value: durationMin != null ? '$durationMin' : '—',
              unit: durationMin != null ? 'min' : '',
              color: scheme.primary,
            ),
            _StatDivider(),
            _StatCell(
              icon: PhosphorIconsRegular.trendUp,
              label: 'Volume',
              value: totalVolumeKg != null
                  ? _formatKgShort(totalVolumeKg!)
                  : '—',
              unit: totalVolumeKg != null ? 'kg' : '',
              color: AppColors.secondary,
            ),
            _StatDivider(),
            _StatCell(
              icon: PhosphorIconsRegular.repeat,
              label: 'Sets',
              value: totalSets?.toString() ?? '—',
              unit: '',
              color: AppColors.accent,
            ),
            _StatDivider(),
            _StatCell(
              icon: PhosphorIconsRegular.arrowsClockwise,
              label: 'Reps',
              value: totalReps?.toString() ?? '—',
              unit: '',
              color: AppColors.positive,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppOpacities.disabled),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.xxs),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: AppTypography.wBold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 40,
      color: scheme.outline.withValues(alpha: 0.5),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// POINTS CARD
// ═══════════════════════════════════════════════════════════════════

class _PointsCard extends StatelessWidget {
  final int pointsEarned;
  const _PointsCard({required this.pointsEarned});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.sparkle,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Points",
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "+$pointsEarned",
            style: textTheme.headlineSmall!.copyWith(
              fontWeight: AppTypography.wBold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            "Earned this session",
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BADGE CARD
// ═══════════════════════════════════════════════════════════════════

class _BadgeCard extends StatelessWidget {
  final List earnedBadges;
  final String badgeTitle;
  final String badgeDesc;

  const _BadgeCard({
    required this.earnedBadges,
    required this.badgeTitle,
    required this.badgeDesc,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasBadge = earnedBadges.isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasBadge
                      ? PhosphorIconsRegular.medal
                      : PhosphorIconsRegular.medal,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Badge",
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasBadge ? badgeTitle : "None today",
            style: textTheme.titleMedium!.copyWith(
              fontWeight: AppTypography.wSemibold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            hasBadge ? badgeDesc : "Showing up still counts.",
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISES CARD
// ═══════════════════════════════════════════════════════════════════

class _ExercisesCard extends StatelessWidget {
  final List<String> exerciseNames;
  const _ExercisesCard({required this.exerciseNames});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.barbell,
                  size: 16,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "Exercises trained",
                  style: textTheme.titleSmall!.copyWith(
                    fontWeight: AppTypography.wSemibold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  "${exerciseNames.length}",
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.secondary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: exerciseNames
                .map((name) => _ExerciseChip(label: name))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  const _ExerciseChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: AppBorders.boxOnePx(scheme),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall!.copyWith(
          color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          fontWeight: AppTypography.wMedium,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REFLECTION CARD
// ═══════════════════════════════════════════════════════════════════

class _ReflectionCard extends StatelessWidget {
  final String? moodRaw;
  final int? challengeRating;
  final String? reflectionNote;

  const _ReflectionCard({
    required this.moodRaw,
    required this.challengeRating,
    required this.reflectionNote,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final moodLabel =
        moodRaw == null || moodRaw!.trim().isEmpty
        ? "Not logged"
        : "${_moodLabel(moodRaw!)} ${_moodEmoji(moodRaw!)}";

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.heart,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Your check-in",
                style: textTheme.titleSmall!.copyWith(
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _MiniTile(
                  icon: PhosphorIconsRegular.smiley,
                  label: "Mood",
                  value: moodLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MiniTile(
                  icon: PhosphorIconsRegular.gauge,
                  label: "Challenge",
                  value: challengeRating == null ? "—" : "$challengeRating/10",
                ),
              ),
            ],
          ),

          if (challengeRating != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TicksBar(value: challengeRating!.clamp(0, 10)),
          ],

          if (reflectionNote != null &&
              reflectionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIconsRegular.quotes,
                    size: 16,
                    color: scheme.primary.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      reflectionNote!.trim(),
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final meta = scheme.onSurface.withValues(alpha: AppOpacities.secondary);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: AppBorders.boxOnePx(scheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: meta),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: textTheme.labelSmall!.copyWith(color: meta),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: AppTypography.wSemibold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TicksBar extends StatelessWidget {
  final int value;
  const _TicksBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(10, (i) {
        final filled = i < value;
        final isHigh = value >= 8;
        final fillColor = isHigh ? AppColors.accent : scheme.primary;

        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == 9 ? 0 : 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.full),
              color: filled
                  ? fillColor
                  : scheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WEEKLY CONSISTENCY CARD
// ═══════════════════════════════════════════════════════════════════

class _WeeklyCard extends StatelessWidget {
  final List<Map<String, dynamic>> weekly;
  final int showedUpDays;

  const _WeeklyCard({required this.weekly, required this.showedUpDays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.calendarCheck,
                  size: 16,
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Consistency",
                      style: textTheme.titleSmall!.copyWith(
                        fontWeight: AppTypography.wSemibold,
                      ),
                    ),
                    Text(
                      "Last 7 days",
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  '$showedUpDays / 7',
                  style: textTheme.labelSmall!.copyWith(
                    color: AppColors.positive,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final d = i < weekly.length ? weekly[i] : {"sessions": 0};
              final sessions = _toInt(d["sessions"]);
              final trained = sessions > 0;
              final isToday = i == 6;
              final maxH = 56.0;
              final height = sessions <= 0 ? 14.0 : (sessions == 1 ? 36.0 : maxH);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : AppSpacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300 + i * 60),
                        curve: Curves.easeOut,
                        height: height,
                        decoration: BoxDecoration(
                          color: trained
                              ? (isToday
                                    ? scheme.primary
                                    : scheme.secondary.withValues(alpha: 0.7))
                              : scheme.onSurface.withValues(alpha: 0.07),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppRadii.xs),
                            topRight: Radius.circular(AppRadii.xs),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _weekdayShort(i),
                        style: textTheme.labelSmall!.copyWith(
                          color: isToday
                              ? scheme.primary
                              : scheme.onSurface.withValues(
                                  alpha: AppOpacities.tertiary,
                                ),
                          fontWeight: isToday
                              ? AppTypography.wBold
                              : AppTypography.wRegular,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRESS & ANALYTICS CARD
// ═══════════════════════════════════════════════════════════════════

class _ProgressCard extends StatelessWidget {
  final int? streakDays;
  final int? weeklyCount;
  final int? totalSessions;
  final int? gapDays;
  final bool expanded;
  final VoidCallback onToggle;

  const _ProgressCard({
    required this.streakDays,
    required this.weeklyCount,
    required this.totalSessions,
    required this.gapDays,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: AppOpacities.disabled,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.chartBar,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "Progress & Analytics",
                  style: textTheme.titleSmall!.copyWith(
                    fontWeight: AppTypography.wSemibold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    expanded
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 16,
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _AnalyticTile(
                  icon: PhosphorIconsRegular.fire,
                  label: "Streak",
                  value: streakDays != null ? "$streakDays days" : "—",
                  accent: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AnalyticTile(
                  icon: PhosphorIconsRegular.calendarBlank,
                  label: "This week",
                  value: weeklyCount != null ? "$weeklyCount sessions" : "—",
                  accent: scheme.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AnalyticTile(
                  icon: PhosphorIconsRegular.stack,
                  label: "All time",
                  value: totalSessions?.toString() ?? "—",
                  accent: scheme.primary,
                ),
              ),
            ],
          ),

          if (expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 0),
            const SizedBox(height: AppSpacing.sm),
            if (gapDays != null && gapDays! >= 3)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.clockCounterClockwise,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Comeback gap: $gapDays days",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: AppTypography.wSemibold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            "Returning is the win.",
                            style: textTheme.bodySmall!.copyWith(
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
              )
            else
              Text(
                "Consistent week. Keep the momentum going.",
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _AnalyticTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accent.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleSmall!.copyWith(
              fontWeight: AppTypography.wBold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// INSIGHT BANNER (gradient)
// ═══════════════════════════════════════════════════════════════════

class _InsightBanner extends StatelessWidget {
  final String title;
  final String message;

  const _InsightBanner({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        boxShadow: AppShadows.e2(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.whiteUtility.withValues(
                alpha: AppOpacities.disabled,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.lightbulb,
              size: 22,
              color: AppColors.whiteUtility,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall!.copyWith(
                    color: AppColors.whiteUtility,
                    fontWeight: AppTypography.wBold,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: textTheme.bodySmall!.copyWith(
                    color: AppColors.whiteUtility.withValues(alpha: 0.85),
                    height: AppTypography.lhNormal,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED CARD WRAPPER
// ═══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRIMARY BUTTON
// ═══════════════════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.e2(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: scheme.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.titleSmall!.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: AppTypography.wSemibold,
                      ),
                      overflow: TextOverflow.ellipsis,
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

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

String _ctaLabel(List ctas, {required int index, required String fallback}) {
  if (ctas.length <= index) return fallback;
  final item = ctas[index];
  if (item is Map && item["label"] != null) {
    final s = item["label"].toString().trim();
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

String _stringOrFallback(dynamic value, {required String fallback}) {
  final s = value?.toString();
  if (s == null || s.trim().isEmpty) return fallback;
  return s.trim();
}

String _weekdayShort(int index) {
  const labels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
  return labels[index.clamp(0, 6)];
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _toNumOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

String _formatKgShort(double kg) {
  final rounded = kg.round();
  if (rounded >= 1000) {
    return "${(rounded / 1000).toStringAsFixed(1)}k";
  }
  return rounded.toString();
}

String _moodEmoji(String mood) {
  switch (mood.trim().toUpperCase()) {
    case "GREAT": return "😄";
    case "GOOD": return "😊";
    case "OKAY": return "😐";
    case "TOUGH": return "😩";
    default: return "🙂";
  }
}

String _moodLabel(String mood) {
  switch (mood.trim().toUpperCase()) {
    case "GREAT": return "Great";
    case "GOOD": return "Good";
    case "OKAY": return "Okay";
    case "TOUGH": return "Tough";
    default: return mood;
  }
}