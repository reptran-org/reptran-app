import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import '../state/active_workout_controller.dart';
import '../../../../routes/app_router.dart';
import 'package:reptran_app/features/notifications/services/nudge_intent_handler.dart';

class ActiveWorkoutBar extends StatefulWidget {
  const ActiveWorkoutBar({super.key});

  @override
  State<ActiveWorkoutBar> createState() => _ActiveWorkoutBarState();
}

class _ActiveWorkoutBarState extends State<ActiveWorkoutBar>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();

    // Timer for updating duration every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Safe animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  String _formatDuration(DateTime startedAt) {
    final diff = DateTime.now().difference(startedAt);
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _buildActiveIndicator() {
    if (_pulseController == null) {
      return const SizedBox(width: 12, height: 12);
    }

    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        final animationValue = _pulseController!.value;
        final glowScale = 1 + (animationValue * 0.6);

        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse
              Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive.withOpacity(
                      0.25 * (1 - animationValue),
                    ),
                  ),
                ),
              ),

              // Solid core dot
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.positive,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appRouter.routerDelegate,
      builder: (context, _) {
        final active = context.watch<ActiveWorkoutController>();
        final scheme = Theme.of(context).colorScheme;

        // No active session → hide
        if (!active.isActive || active.startedAt == null) {
          return const SizedBox.shrink();
        }

        // Detect current route
        final matches = appRouter.routerDelegate.currentConfiguration.matches;

        final topLocation = matches.isNotEmpty
            ? matches.last.matchedLocation
            : null;

        final shouldHideBar =
            topLocation != null &&
            topLocation.startsWith('/workout/') &&
            topLocation != '/workout';

        if (shouldHideBar) {
          return const SizedBox.shrink();
        }

        final isDark = scheme.brightness == Brightness.dark;

        final resumeColor = isDark ? AppColors.secondary : AppColors.primary;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          child: Material(
            elevation: 14,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.positive.withOpacity(0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.positive.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 🔼 Resume Capsule
                  Container(
                    decoration: BoxDecoration(
                      color: resumeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        appRouter.push(
                          '/workout/logger',
                          extra: active.sessionId,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 26,
                          color: resumeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 🟢 Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildActiveIndicator(),
                            const SizedBox(width: 8),
                            Text(
                              "Workout",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(active.startedAt!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.positive,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          active.nextExerciseName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 🗑 Delete Capsule
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _showDiscardDialog(active);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDiscardDialog(ActiveWorkoutController active) async {
    final navigatorKey = NudgeIntentHandler.navigatorKey;

    final context = navigatorKey.currentContext;

    if (context == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Discard workout?"),
        content: const Text(
          "This will delete the session and all logged sets.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Discard"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await SessionService().discardSession(sessionId: active.sessionId!);

      active.clear();
    }
  }
}
