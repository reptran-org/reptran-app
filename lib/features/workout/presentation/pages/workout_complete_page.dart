// File: WorkoutCompletePage.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/workout/presentation/pages/reward_overlay.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';

class WorkoutCompletePage extends StatefulWidget {
  const WorkoutCompletePage({super.key, required this.sessionId, this.preview});

  final String sessionId;
  final Map<String, dynamic>? preview;

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  bool _showSessionDetails = false;
  String? _selectedMood; // "GREAT" | "GOOD" | "OKAY" | "TOUGH"
  bool _challengeTouched = false;
  int _challenge10 = 6; // default visual position

  bool _submitting = false;

  Map<String, dynamic>? _preview;

  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _preview = widget.preview;
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await SessionService().getFeedbackScreenData(
        sessionId: widget.sessionId,
      );

      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onContinuePressed() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final note = _notesController.text.trim();
      final payloadNote = note.isEmpty ? null : note;

      // 1) Save reflection
      final reflection = await SessionService().submitSessionReflection(
        sessionId: widget.sessionId,
        mood: _selectedMood,
        challengeRating: _challengeTouched ? _challenge10 : null,
        note: payloadNote,
      );

      // 2) Fetch rewards (points + badges)
      final rewards = _preview ?? {};

      if (!mounted) return;

      final pointsDelta = (rewards["points"]?["total"] ?? 0) as int;

      final badges = (rewards["badges"] as List?) ?? [];
      final badge = badges.isNotEmpty
          ? badges.first as Map<String, dynamic>
          : null;

      final payload = SessionRewardsPayload(
        sessionId: rewards["sessionId"] as String,
        pointsDelta: pointsDelta,
        badge: badge == null
            ? null
            : RewardBadge(
                key: badge["key"] as String,
                title: badge["title"] as String,
                description: badge["description"] as String,
                iconUrl: badge["iconUrl"] as String?,
              ),
      );

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'reward-overlay',
        barrierColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.0),
        transitionDuration: AppDurations.medium,
        pageBuilder: (_, __, ___) => PopScope(
          canPop: false, // 🚨 THIS is the key fix
          child: RewardOverlay(
            payload: payload,
            onViewSummary: () {
              Navigator.of(context).pop(); // close overlay
              context.go('/workout/session-summary', extra: widget.sessionId);
            },
            onBackHome: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
          ),
        ),
        transitionBuilder: (_, anim, __, child) {
          final scale = 0.96 + (0.04 * anim.value);
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: anim.value, child: child),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn’t save. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Wrapping up...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text("Saving your session.", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // ✅ handle fetch failure safely
    if (_data == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We couldn’t load your session summary.",
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "You still completed the session — you can continue.",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text("Go back"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ now safe to read _data!
    final immediate = _data!['immediateFeedback'] as Map<String, dynamic>;
    final title = (immediate['title'] as String?)?.trim().isNotEmpty == true
        ? (immediate['title'] as String)
        : "Workout complete 💪";

    final message = (immediate['message'] as String?)?.trim().isNotEmpty == true
        ? (immediate['message'] as String)
        : "You showed up today — that matters.";

    final session = _data!['session'] as Map<String, dynamic>;

    final durationMin = (session['durationMin'] as int?) ?? 0;
    final totalSets = (session['totalSets'] as int?) ?? 0;
    final totalReps = (session['totalReps'] as int?) ?? 0;
    final totalVolumeKg = (session['totalVolumeKg'] as num?) ?? 0;
    return Scaffold(
      // scaffold background comes from theme / color scheme
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              // firstSectionHasBg: false -> apply horizontal padding here
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  const _SuccessCheckIcon(),

                  // Top framing
                  const SizedBox(height: AppSpacing.md),
                  // Heading + Subheading (includeHeadingSubheading: true)
                  _HeadingBlock(title: title, subtitle: message),
                  const SizedBox(height: AppSpacing.md), // section gap
                  // Summary Card (card token)
                  // Updated card snippet: columns justified between and visible full-width outline bar
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          onTap: () {
                            setState(
                              () => _showSessionDetails = !_showSessionDetails,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Session details",
                                    style: textTheme.titleSmall!.copyWith(
                                      fontWeight: AppTypography.wSemibold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _showSessionDetails
                                      ? PhosphorIconsRegular.caretUp
                                      : PhosphorIconsRegular.caretDown,
                                  size: 18,
                                  color: scheme.onSurface.withOpacity(
                                    AppOpacities.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showSessionDetails) ...[
                          const SizedBox(height: AppSpacing.sm),

                          // Row 1: Duration ↔ Total Volume
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${durationMin} min',
                                      style: textTheme.titleMedium!.copyWith(
                                        fontWeight: AppTypography.wBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Volume',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${totalVolumeKg.toStringAsFixed(0)} kg',
                                      style: textTheme.titleMedium!.copyWith(
                                        fontWeight: AppTypography.wBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Row 2: Sets Completed ↔ Total Reps
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sets Completed',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '$totalSets',
                                      style: textTheme.titleMedium!.copyWith(
                                        fontWeight: AppTypography.wBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Reps',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '$totalReps',
                                      style: textTheme.titleMedium!.copyWith(
                                        fontWeight: AppTypography.wBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // How are you feeling? (chips)
                  // Section: How are you feeling?
                  // Section: How are you feeling?
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 👈 ensures left alignment
                    children: [
                      Text(
                        'How are you feeling?',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Wrap directly without extra padding so first/last card align properly
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        alignment: WrapAlignment.start,
                        children: [
                          _MoodCard(
                            emoji: '😄',
                            label: 'Great',
                            isSelected: _selectedMood == "GREAT",
                            onTap: () =>
                                setState(() => _selectedMood = "GREAT"),
                          ),
                          _MoodCard(
                            emoji: '😊',
                            label: 'Good',
                            isSelected: _selectedMood == "GOOD",
                            onTap: () => setState(() => _selectedMood = "GOOD"),
                          ),
                          _MoodCard(
                            emoji: '😐',
                            label: 'Okay',
                            isSelected: _selectedMood == "OKAY",
                            onTap: () => setState(() => _selectedMood = "OKAY"),
                          ),
                          _MoodCard(
                            emoji: '😩',
                            label: 'Tough',
                            isSelected: _selectedMood == "TOUGH",
                            onTap: () =>
                                setState(() => _selectedMood = "TOUGH"),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 👈 ensures left alignment
                    children: [
                      // How challenging (slider mimic static)
                      Text(
                        'How challenging was this session?',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final barWidth = constraints.maxWidth;
                                  final knobSize = 20.0;

                                  // convert 1..10 -> 0..1
                                  final t = (_challenge10 - 1) / 9;

                                  // knob x position within bar
                                  final knobLeft =
                                      (barWidth * t) - (knobSize / 2);

                                  void updateFromDx(double dx) {
                                    // dx is tap position inside the bar [0..barWidth]
                                    final clamped = dx.clamp(0.0, barWidth);
                                    final ratio = clamped / barWidth; // 0..1

                                    // snap to 1..10
                                    final next = (1 + (ratio * 9))
                                        .round()
                                        .clamp(1, 10);

                                    setState(() {
                                      _challengeTouched = true;
                                      _challenge10 = next;
                                    });
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // scale labels row
                                      Row(
                                        children: [
                                          Text(
                                            'Easy',
                                            style: textTheme.bodySmall,
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Hard',
                                            style: textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),

                                      // interactive bar area
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (d) {
                                          final dx = d.localPosition.dx;
                                          updateFromDx(dx);
                                        },
                                        onPanUpdate: (d) {
                                          final dx = d.localPosition.dx;
                                          updateFromDx(dx);
                                        },
                                        child: SizedBox(
                                          height:
                                              32, // gives touch room for drag
                                          width: double.infinity,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.centerLeft,
                                            children: [
                                              // Gradient bar
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadii.md,
                                                      ),
                                                  child: Container(
                                                    height: 8.0,
                                                    width: double.infinity,
                                                    decoration:
                                                        const BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                begin: Alignment
                                                                    .centerLeft,
                                                                end: Alignment
                                                                    .centerRight,
                                                                colors: [
                                                                  AppColors
                                                                      .accent,
                                                                  AppColors
                                                                      .positive,
                                                                ],
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ),

                                              // Knob (moves)
                                              Positioned(
                                                top:
                                                    6, // centers knob nicely inside 32 height
                                                left: knobLeft.clamp(
                                                  0.0,
                                                  barWidth - knobSize,
                                                ),
                                                child: CustomPaint(
                                                  painter:
                                                      _GradientRingPainter(),
                                                  child: Container(
                                                    width: knobSize,
                                                    height: knobSize,
                                                    alignment: Alignment.center,
                                                    child: Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .whiteUtility,
                                                        shape: BoxShape.circle,
                                                        boxShadow:
                                                            AppShadows.e1(
                                                              scheme,
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

                                      const SizedBox(height: AppSpacing.sm),

                                      // tick marks (1–10)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: List.generate(10, (i) {
                                          return Container(
                                            width: 1,
                                            height: 6,
                                            color: scheme.outline.withOpacity(
                                              AppOpacities.secondary,
                                            ),
                                          );
                                        }),
                                      ),

                                      const SizedBox(height: AppSpacing.xs),

                                      // numbers (1–10)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: List.generate(10, (i) {
                                          final value = i + 1;
                                          final isActive =
                                              value == _challenge10;

                                          return Text(
                                            '$value',
                                            style: textTheme.bodySmall!
                                                .copyWith(
                                                  color: isActive
                                                      ? scheme.onSurface
                                                      : scheme.onSurface
                                                            .withOpacity(
                                                              AppOpacities
                                                                  .secondary,
                                                            ),
                                                  fontWeight: isActive
                                                      ? AppTypography.wBold
                                                      : AppTypography.wSemibold,
                                                ),
                                          );
                                        }),
                                      ),

                                      const SizedBox(height: AppSpacing.sm),

                                      Text(
                                        "Selected: $_challenge10/10",
                                        style: textTheme.bodySmall!.copyWith(
                                          color: scheme.onSurface.withOpacity(
                                            AppOpacities.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 👈 ensures left alignment
                    children: [
                      // Session notes (static text area)
                      Text(
                        'Session notes (optional)',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      TextField(
                        controller: _notesController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Add a quick note about today...",
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.light
                              ? AppColors.neutralLight
                              : AppColors.neutralDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(color: scheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(color: scheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(color: scheme.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // CTA Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56, // allowed literal for minHeight
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                    scheme.primary,
                                  ),
                                  elevation: MaterialStateProperty.all(0),
                                  padding: MaterialStateProperty.all(
                                    const EdgeInsets.all(AppSpacing.sm),
                                  ),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.lg,
                                      ),
                                    ),
                                  ),
                                  shadowColor: MaterialStateProperty.all(
                                    scheme.secondary.withOpacity(0.25),
                                  ),
                                ),

                                // onPressed: () => context.push('/workout/session-summary'),
                                // onPressed: () {
                                //   showGeneralDialog(
                                //     context: context,
                                //     barrierDismissible: false,
                                //     barrierLabel: 'reward-overlay',
                                //     // Overlay handles its own dim; keep the barrier transparent via tokens
                                //     barrierColor: Theme.of(context)
                                //         .colorScheme
                                //         .onSurface
                                //         .withValues(alpha: 0.0),
                                //     transitionDuration: AppDurations.medium,
                                //     pageBuilder: (_, __, ___) =>
                                //         const RewardOverlay(),
                                //     transitionBuilder: (_, anim, __, child) {
                                //       // subtle scale + fade (token-friendly)
                                //       final scale = 0.96 + (0.04 * anim.value);
                                //       return Transform.scale(
                                //         scale: scale,
                                //         child: Opacity(
                                //           opacity: anim.value,
                                //           child: child,
                                //         ),
                                //       );
                                //     },
                                //   );
                                // },
                                onPressed: _submitting
                                    ? null
                                    : _onContinuePressed,

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_submitting) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Saving...',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: scheme.onSecondary,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Continue',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: scheme.onSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(
                                        PhosphorIconsRegular.arrowRight,
                                        size: 24,
                                        color: scheme.onSecondary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Secondary small text
                  Center(
                    child: Text(
                      'Continue when you’re ready',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(
                          AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl), // bottom framing
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// -------------------- Helpers --------------------

class _HeadingBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeadingBlock({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withOpacity(AppOpacities.secondary),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: AppBorders.boxCard(scheme),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: child,
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = isSelected ? scheme.primary : scheme.outline;
    final bgColor = isSelected
        ? scheme.primary.withOpacity(0.10)
        : scheme.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: AnimatedContainer(
        duration: AppDurations.xShort,
        curve: Curves.easeOut,
        width: 72,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium!.copyWith(
                color: isSelected
                    ? scheme.onSurface
                    : scheme.onSurface.withOpacity(AppOpacities.secondary),
                fontWeight: AppTypography.wSemibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final ColorScheme scheme;

  const _ProgressBar({required this.progress, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.sm,
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(AppOpacities.tertiary),
        borderRadius: BorderRadius.circular(AppRadii.xxl),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.secondary,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            boxShadow: AppShadows.e1(scheme),
          ),
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 2.0; // 2px gradient border
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Define gradient shader (accent → positive)
    final gradient = const SweepGradient(
      colors: [AppColors.accent, AppColors.positive],
      startAngle: 0.0,
      endAngle: 3.14 * 2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the gradient ring
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuccessCheckIcon extends StatefulWidget {
  const _SuccessCheckIcon();

  @override
  State<_SuccessCheckIcon> createState() => _SuccessCheckIconState();
}

class _SuccessCheckIconState extends State<_SuccessCheckIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Gentle pulse only 2 times then stop
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // second cycle
        if (_controller.value == 0) {
          _controller.forward();
        }
      }
    });

    // Stop after ~2 pulses
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.positive, width: 8),
        ),
        child: Center(
          child: Icon(
            PhosphorIconsFill.checkFat,
            size: 40,
            color: AppColors.positive,
          ),
        ),
      ),
    );
  }
}
