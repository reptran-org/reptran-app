import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';
import 'package:reptran_app/features/home/presentation/pages/micro_nudge_modal.dart';
import 'package:reptran_app/features/home/presentation/pages/snooze_modal.dart';
import 'package:reptran_app/features/home/presentation/pages/weekly_intent_modal.dart';
import 'package:reptran_app/features/home/services/home_card_service.dart';
import 'package:reptran_app/features/home/services/recovery_service.dart';
import 'package:reptran_app/features/home/services/workout_context_service.dart';
import 'package:reptran_app/features/notifications/services/nudge_notification_service.dart';
import 'package:reptran_app/features/profile/presentation/pages/environment_check_in_modal.dart';
import 'package:reptran_app/features/workout/services/active_session_restore.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:reptran_app/shared/widgets/app_scaffold.dart';
import 'package:reptran_app/shared/widgets/tab_item.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kIntentModalShownDate = 'intent_modal_shown_date';
final _storage = const FlutterSecureStorage();

Future<bool> _shouldShowIntentModal(bool backendFlag) async {
  if (!backendFlag) return false;

  final now = DateTime.now().toLocal();
  final todayStr = "${now.year}-${now.month}-${now.day}";

  final lastShown = await _storage.read(key: _kIntentModalShownDate);

  if (lastShown == null) return true;

  return lastShown != todayStr;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeCardData> _homeCardFuture;
  late Future<WorkoutContext?> _workoutContextFuture;
  late Future<RecoveryData?> _recoveryFuture;
  late Future<List<dynamic>> _communityFuture;

  @override
  void initState() {
    super.initState();

    _homeCardFuture = HomeCardService().fetchHomeCardData();
    _workoutContextFuture = WorkoutContextService().fetchWorkoutContext();
    _recoveryFuture = RecoveryService().fetchCurrentRecovery();
    _communityFuture = ActivityService().getFeed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActiveSessionRestore.restore(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      current: TabItem.home,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            children: [
              // ─────────────────────────────────────────────
              // 🧠 FIRST CARD — Identity / Consistency
              // ─────────────────────────────────────────────
              FutureBuilder<HomeCardData>(
                future: _homeCardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 160);
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!;

                  /// ✅ Trigger modal safely after build
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final shouldShow = await _shouldShowIntentModal(
                      data.shouldShowIntentModal,
                    );

                    if (!shouldShow) return;

                    final now = DateTime.now().toLocal();
                    final todayStr = "${now.year}-${now.month}-${now.day}";

                    await _storage.write(
                      key: _kIntentModalShownDate,
                      value: todayStr,
                    );

                    if (!context.mounted) return;

                    IntentModal.show(
                      context,
                      onSelect: (value) async {
                        await HomeCardService().updateWeeklyIntent(value);

                        if (!context.mounted) return;

                        /// ✅ Show snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Weekly intent set',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            elevation: 2,
                          ),
                        );

                        setState(() {
                          _homeCardFuture = HomeCardService()
                              .fetchHomeCardData();
                        });
                      },
                    );
                  });

                  return FirstCard(cs: cs, data: data);
                },
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────────
              // 🏋️ SECOND CARD — Workout Context
              // ─────────────────────────────────────────────
              FutureBuilder<WorkoutContext?>(
                future: _workoutContextFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 140);
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    // No workout available → hide card
                    return const SizedBox();
                  }

                 final ctx = snapshot.data!;

if (ctx.source == 'COMPLETED_TODAY') {
  return CompletedTodayCard(cs: cs, workoutContext: ctx);
}

return SecondCard(cs: cs, workoutContext: ctx);
                },
              ),

              const SizedBox(height: 24),
              FutureBuilder<RecoveryData?>(
                future: _recoveryFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox();
                  }

                  return BounceBackCard(cs: cs, recovery: snapshot.data!);
                },
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Community', cs: cs),
const SizedBox(height: 16),

FutureBuilder<List<dynamic>>(
  future: _communityFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 96);
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const SizedBox();
    }

    return CommunityScroller(
      cs: cs,
      items: snapshot.data!,
    );
  },
),
              const SizedBox(height: 24),
              InsightCard(cs: cs),
              const SizedBox(height: 16),
              ProgressCard(cs: cs),
            ],
          ),
        ),
      ),
    );
  
  
  }
}

/// ------------------------------------------------------------
/// First Card
/// ------------------------------------------------------------
class FirstCard extends StatelessWidget {
  const FirstCard({super.key, required this.cs, required this.data});

  final ColorScheme cs;
  final HomeCardData data;

  @override
  Widget build(BuildContext context) {
    final weeklyGoal = data.weeklyIntent;
    final hasIntent = weeklyGoal != null;

    final progress = hasIntent && weeklyGoal! > 0
        ? (data.weeklyCount / weeklyGoal)
        : 0.0;

    final hasStreak = (data.streakDays ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppScale.s(context,AppRadii.lg)),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      padding: EdgeInsets.all(AppScale.s(context,AppSpacing.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Heading
          Text(
            'Keep building, ${data.name ?? 'there'} 💪',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppScale.t(context,AppTypography.heading),
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
              height: AppTypography.lhTight,
            ),
          ),

          SizedBox(height: AppScale.s(context,AppSpacing.xxs)),

          /// Identity statement
          Text(
            data.futureSelf ??
                'I am the type of person who shows up consistently.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppScale.t(context,AppTypography.body),
              fontWeight: AppTypography.wSemibold,
              color: cs.primary,
              height: AppTypography.lhNormal,
            ),
          ),

          SizedBox(height: AppScale.s(context,AppSpacing.sm)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressCircle(
                size: AppScale.s(context,56),
                borderWidth: AppScale.s(context,4),
                borderColor: cs.secondary,
                progress: progress,
                innerText:
                    hasIntent ? '${data.weeklyCount}/$weeklyGoal' : '—',
                innerStyle: TextStyle(
                  fontSize: AppScale.t(context,AppTypography.body),
                  fontWeight: AppTypography.wSemibold,
                  color: cs.primary,
                ),
              ),

              SizedBox(width: AppScale.s(context,AppSpacing.sm)),

              /// Middle content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasIntent ? 'Weekly goal' : 'This week',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppScale.t(context,AppTypography.caption),
                        fontWeight: AppTypography.wSemibold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: AppScale.s(context,AppSpacing.xs)),
                    Text(
                      hasIntent
                          ? '${data.weeklyCount}/$weeklyGoal workouts this week'
                          : 'Just focus on showing up',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppScale.t(context,AppTypography.caption),
                        color: cs.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppScale.s(context,AppSpacing.xs)),

              /// Right content
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasStreak
                          ? '🔥 ${data.streakDays}-day streak'
                          : 'Start your streak 🔥',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: AppScale.t(context,AppTypography.body),
                        fontWeight: AppTypography.wSemibold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: AppScale.s(context,AppSpacing.xs)),
                    Text(
                      hasStreak
                          ? 'Momentum matters'
                          : 'One day is enough to begin',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: AppScale.t(context,AppTypography.caption),
                        color: cs.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({
    required this.size,
    required this.borderWidth,
    required this.borderColor,
    required this.innerText,
    required this.innerStyle,
    required this.progress,
  });

  final double size;
  final double borderWidth;
  final Color borderColor;
  final String innerText;
  final TextStyle innerStyle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              /// 👇 FIX: force full size + remove internal gap feel
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: borderWidth,
                  strokeCap: StrokeCap.round, // nicer edge, reduces visual gap
                  backgroundColor: borderColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(
                    value == 1 ? Colors.green : borderColor,
                  ),
                ),
              ),

              Text(innerText, style: innerStyle),
            ],
          );
        },
      ),
    );
  }
}








class SecondCard extends StatelessWidget {
  const SecondCard({super.key, required this.cs, required this.workoutContext});

  final ColorScheme cs;
  final WorkoutContext workoutContext;

  @override
  Widget build(BuildContext contextBuild) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────
          // Title + Meta (NO play button)
          // ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutContext.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.clock(PhosphorIconsStyle.regular),
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _durationLabel(workoutContext),
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ❌ Play button intentionally removed
              InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () {
                  _handleStart(contextBuild);
                },
                child: Icon(
                  PhosphorIconsFill.playCircle,
                  size: 48,
                  color: cs.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─────────────────────────────────────────────
          // CTA Button (ONLY ACTION)
          // ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                _handleStart(contextBuild);
              },
              child: const Text(
                'Start Workout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // const SizedBox(height: 16),

          // ❌ Snooze intentionally removed
          Center(
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: contextBuild,
                  builder: (_) => const SnoozeModal(),
                );
              },
              child: Text(
                'Snooze for later',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(WorkoutContext ctx) {
    switch (ctx.source) {
      case 'ROUTINE_DAY':
        return '45 min';
      case 'USER_WORKOUT':
        return '40 min';
      case 'TEMPLATE':
        return '30 min';
      default:
        return '—';
    }
  }

  void _handleStart(BuildContext context) {
    NudgeSessionService.startFromNudge(
      context,
      userWorkoutId: workoutContext.userWorkoutId,
      templateId: workoutContext.templateId,
    );
  }
}



class CompletedTodayCard extends StatelessWidget {
  const CompletedTodayCard({
    super.key,
    required this.cs,
    required this.workoutContext,
  });

  final ColorScheme cs;
  final WorkoutContext workoutContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.positive.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: AppShadows.e2(cs),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
       children: [
  _TopRow(cs: cs),
  const SizedBox(height: AppSpacing.xs),
  _Tagline(cs: cs),

  const SizedBox(height: AppSpacing.md), // 🔽 reduced
  Text(
    workoutContext.title,
    style: TextStyle(
      fontSize: AppTypography.body,
      fontWeight: AppTypography.wSemibold,
      height: AppTypography.lhTight,
      color: cs.onSurface.withValues(alpha: 0.9),
    ),
  ),

  const SizedBox(height: AppSpacing.xs), // 🔽 reduced
  _StatStrip(cs: cs, workoutContext: workoutContext),

  const SizedBox(height: AppSpacing.md),
_SummaryButton(
  cs: cs,
  sessionId: workoutContext.sessionId!, // assuming it exists for COMPLETED_TODAY
),
],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top row — check badge + title
// ─────────────────────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: AppSpacing.lg,
          height: AppSpacing.lg,
          decoration: BoxDecoration(
            color: AppColors.positive.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: const Icon(
            PhosphorIconsFill.checkCircle,
            color: AppColors.positive,
            size: AppTypography.title,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'You showed up today',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: AppTypography.wBold,
              height: AppTypography.lhTight,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tagline — calm, quiet
// ─────────────────────────────────────────────────────────────

class _Tagline extends StatelessWidget {
  const _Tagline({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl + AppSpacing.xs),
      child: Text(
        'That\'s what builds consistency.',
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: AppTypography.wRegular,
          height: AppTypography.lhNormal,
          color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat strip — 4 stats in a row, secondary hierarchy
// ─────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.cs, required this.workoutContext});

  final ColorScheme cs;
  final WorkoutContext workoutContext;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
        value: '${workoutContext.durationMin}',
        unit: 'min',
      ),
      _StatData(
        icon: PhosphorIcons.barbell(PhosphorIconsStyle.regular),
        value: '${workoutContext.totalSets}',
        unit: 'sets',
      ),
      _StatData(
        icon: PhosphorIcons.repeat(PhosphorIconsStyle.regular),
        value: '${workoutContext.totalReps}',
        unit: 'reps',
      ),
      _StatData(
        icon: PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
        value: '${(workoutContext.totalVolumeKg ?? 0).toStringAsFixed(0)}',
        unit: 'kg',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            Expanded(child: _StatCell(cs: cs, data: stats[i])),
            if (i < stats.length - 1) _StatDivider(cs: cs),
          ],
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.cs, required this.data});

  final ColorScheme cs;
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          data.icon,
          size: AppTypography.caption,
          color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          data.value,
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: AppTypography.wBold,
            height: AppTypography.lhTight,
            color: cs.onSurface,
          ),
        ),
        Text(
          data.unit,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: AppTypography.wRegular,
            height: AppTypography.lhTight,
            color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppSpacing.lg,
      color: cs.onSurface.withValues(alpha: 0.08),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary CTA — understated, not loud
// ─────────────────────────────────────────────────────────────

class _SummaryButton extends StatefulWidget {
  const _SummaryButton({
    required this.cs,
    required this.sessionId, // ✅ add
  });

  final ColorScheme cs;
  final String sessionId; // ✅ add

  @override
  State<_SummaryButton> createState() => _SummaryButtonState();
}

class _SummaryButtonState extends State<_SummaryButton> {
  bool _pressed = false;

  

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
  setState(() => _pressed = false);

  if (widget.sessionId.isEmpty) return;

  context.pushNamed(
    'sessionSummary',
    extra: widget.sessionId, // ✅ pass sessionId
  );
},
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimation.pressScale : 1.0,
        duration: AppAnimation.microInteraction,
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.positive.withValues(alpha: 0.20)
                : AppColors.positive.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: AppColors.positive.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.listChecks(PhosphorIconsStyle.regular),
                size: AppTypography.body,
                color: AppColors.positive,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Session Summary',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: AppTypography.wSemibold,
                  height: AppTypography.lhTight,
                  color: AppColors.positive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// ------------------------------------------------------------
/// Third Card (Bounce Back Strong) with gradient + mini-cards
/// ------------------------------------------------------------
class BounceBackCard extends StatelessWidget {
  const BounceBackCard({super.key, required this.cs, required this.recovery});

  final ColorScheme cs;
  final RecoveryData recovery;

  String _cleanTitle(String title) {
    return title
        .replaceFirst(
          RegExp(r'^\d+\s*[-]?\s*Minute[s]?\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB4335), Color(0xFFFFB347)],
        ),
        borderRadius: radius,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────
          // Title + Close
          // ─────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Yesterday didn’t go as planned.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // optional: implement skip later
                },
                icon: const Icon(
                  PhosphorIconsRegular.x,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'A small reset counts.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),

          const SizedBox(height: 16),

          // ─────────────────────────────
          // Micro Goals (Horizontal Scroll)
          // ─────────────────────────────
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recovery.goals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final goal = recovery.goals[index];
                final cleanTitle = _cleanTitle(goal.label);

                return _MiniActionChip(
                  label: '${goal.durationMin} min\n$cleanTitle',
                  onTap: () async {
                    if (goal.templateId == null) {
                      return;
                    }

                    try {
                      final session = await SessionService().startSession(
                        templateId: goal.templateId,
                      );

                      final sessionId = session["id"]?.toString();
                      if (sessionId == null) return;

                      if (context.mounted) {
                        context.push('/workout/logger', extra: sessionId);
                      }
                    } catch (e) {}
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Community
/// ------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.cs});
  final String title;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

class CommunityScroller extends StatelessWidget {
  const CommunityScroller({
    super.key,
    required this.cs,
    required this.items,
  });

  final ColorScheme cs;
  final List<dynamic> items;

  String _mapStatus(Map<String, dynamic> json) {
    final type = json['type'];
    final payload = json['payload'] ?? {};

    switch (type) {
      case 'SESSION_SHOWED_UP':
      case 'WORKOUT_COMPLETED':
        return 'completed a session';

      case 'STREAK_MILESTONE':
        return 'hit ${payload['days']} day streak';

      case 'BOUNCE_BACK':
        return 'bounced back today';

      default:
        return 'made progress';
    }
  }

  String _timeAgo(String iso) {
    final created = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(created);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110, // slightly increased
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final item = items[i] as Map<String, dynamic>;
          final actor = item['actor'] ?? {};

          final name = actor['name'] ?? 'User';
          final avatarUrl = actor['avatarUrl'];
          final status = _mapStatus(item);
          final createdAt = item['createdAt'] ?? '';
          final reactionsSummary = item['reactionsSummary'];

          return _CommunityCardHorizontal(
            name: name,
            status: status,
            avatarUrl: avatarUrl,
            createdAt: createdAt,
            reactionsSummary: reactionsSummary,
            timeAgo: _timeAgo,
            cs: cs,
          );
        },
      ),
    );
  }
}


class _CommunityCardHorizontal extends StatelessWidget {
  const _CommunityCardHorizontal({
    required this.name,
    required this.status,
    required this.cs,
    required this.createdAt,
    required this.timeAgo,
    this.avatarUrl,
    this.reactionsSummary,
  });

  final String name;
  final String status;
  final ColorScheme cs;
  final String createdAt;
  final String Function(String) timeAgo;

  final String? avatarUrl;
  final Map<String, dynamic>? reactionsSummary;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;


    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ prevents overflow
          children: [
            // 🔹 Top Row (Avatar + Name + Time)
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primary,
                  backgroundImage: (url != null && url.isNotEmpty)
                      ? NetworkImage(url)
                      : null,
                  child: (url == null || url.isEmpty)
                      ? Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (createdAt.isNotEmpty)
                  Text(
                    timeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // 🔹 Status
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: cs.onSurface.withOpacity(0.85),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // 🔹 Bottom Row (Reactions)
          // 🔹 Bottom Row (Reactions)
if (reactionsSummary != null && reactionsSummary!.isNotEmpty)
  Builder(
    builder: (_) {
      final entries = reactionsSummary!.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));

      return Row(
        children: entries.take(3).map((entry) {
          final emoji = entry.key;
          final count = entry.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    },
  ),
          ],
        ),
      ),
    );
  }
}



/// ------------------------------------------------------------
/// Insight Card
/// ------------------------------------------------------------
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      // onTap: () => context.push('/profile/reonboarding-flow'), // ← tap action
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 40x40 circle with secondary @10% opacity
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('💡', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                "You’re building consistency",
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Progress Card
/// ------------------------------------------------------------
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // onTap: () => context.push('/profile/badge-showcase'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + title, and right-aligned subtext
            Row(
              children: [
                Icon(PhosphorIconsRegular.medal, color: cs.tertiary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Bronze Badge',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '2 more sessions',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            LayoutBuilder(
              builder: (context, c) {
                final total = c.maxWidth;
                final filled = total * 0.35; // placeholder progress
                return Stack(
                  children: [
                    Container(
                      width: total,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Container(
                      width: filled,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.tertiary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

