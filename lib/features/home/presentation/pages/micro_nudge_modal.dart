

// import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:reptran_app/core/constants/tokens.dart';

// class MicroNudgeModal extends StatefulWidget {
//   const MicroNudgeModal({super.key});

//   @override
//   State<MicroNudgeModal> createState() => _MicroNudgeModalState();
// }

// class _MicroNudgeModalState extends State<MicroNudgeModal>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final Animation<double> _fade;
//   late final Animation<Offset> _slide;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 320),
//     );
//     final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
//     _fade = Tween<double>(begin: 0, end: 1).animate(curve);
//     _slide = Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(curve);
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final maxH = MediaQuery.of(context).size.height * 0.90;

//     return Align(
//       alignment: Alignment.topCenter,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 640).copyWith(maxHeight: maxH),
//           child: FadeTransition(
//             opacity: _fade,
//             child: SlideTransition(
//               position: _slide,
//               child: Material(
//                 color: Colors.transparent,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(AppRadii.lg),
//                   child: SingleChildScrollView(
//                     child: _NudgeCard(scheme: scheme),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NudgeCard extends StatelessWidget {
//   final ColorScheme scheme;
//   const _NudgeCard({required this.scheme});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: scheme.surface,
//         borderRadius: BorderRadius.circular(AppRadii.lg),
//         border: AppBorders.boxCard(scheme),
//         boxShadow: AppShadows.e2(scheme),
//       ),
//       padding: const EdgeInsets.all(AppSpacing.sm), // 16px all around
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _CloseX(scheme: scheme),
//           const SizedBox(height: AppSpacing.sm), // gap below X
//           _NudgeHeader(scheme: scheme),
//           const SizedBox(height: AppSpacing.md),
//           _NudgeCTAs(scheme: scheme),
//         ],
//       ),
//     );
//   }
// }

// class _CloseX extends StatelessWidget {
//   final ColorScheme scheme;
//   const _CloseX({required this.scheme});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Spacer(),
//         Icon(
//           PhosphorIconsLight.x,
//           size: 24,
//           color: scheme.onSurface.withOpacity(AppOpacities.secondary),
//         ),
//       ],
//     );
//   }
// }

// class _NudgeHeader extends StatelessWidget {
//   final ColorScheme scheme;
//   const _NudgeHeader({required this.scheme});

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: scheme.secondary.withValues(alpha: 0.10),
//             shape: BoxShape.circle,
//           ),
//           alignment: Alignment.center,
//           child: Icon(
//             PhosphorIconsRegular.fire,
//             size: 24,
//             color: scheme.secondary,
//           ),
//         ),
//         const SizedBox(width: AppSpacing.sm),
//         Expanded(
//           child: Text(
//             "Hey Alex — your 20-min session's due. Want the usual or a 10-min express?",
//             style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _NudgeCTAs extends StatelessWidget {
//   final ColorScheme scheme;
//   const _NudgeCTAs({required this.scheme});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(child: _PrimaryButton(scheme: scheme, label: "Start")),
//         const SizedBox(width: AppSpacing.sm),
//         Expanded(child: _OutlineButton(scheme: scheme, label: "Snooze")),
//       ],
//     );
//   }
// }

// class _PrimaryButton extends StatelessWidget {
//   final ColorScheme scheme;
//   final String label;
//   const _PrimaryButton({required this.scheme, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return Container(
//       height: 48,
//       decoration: BoxDecoration(
//         color: scheme.primary,
//         borderRadius: BorderRadius.circular(AppRadii.md),
//         boxShadow: AppShadows.e1(scheme),
//       ),
//       child: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
//           child: Text(
//             label,
//             style: textTheme.labelLarge?.copyWith(
//               color: scheme.onPrimary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _OutlineButton extends StatelessWidget {
//   final ColorScheme scheme;
//   final String label;
//   const _OutlineButton({required this.scheme, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return Container(
//       height: 48,
//       decoration: BoxDecoration(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(AppRadii.md),
//         border: Border.all(color: scheme.primary, width: 2),
//       ),
//       child: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
//           child: Text(
//             label,
//             style: textTheme.labelLarge?.copyWith(
//               color: scheme.primary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class MicroNudgeModal extends StatefulWidget {
  final String notificationId;
  final String title;
  final String body;

  final String? templateId;
  final String? userWorkoutId;
  final String? routineDayId;

  final VoidCallback onClose;
  final VoidCallback onStart;
  final void Function(BuildContext context) onSnooze;

  const MicroNudgeModal({
    super.key,
    required this.notificationId,
    required this.title,
    required this.body,
    this.templateId,
    this.userWorkoutId,
    this.routineDayId,
    required this.onClose,
    required this.onStart,
    required this.onSnooze,
  });

  @override
  State<MicroNudgeModal> createState() => _MicroNudgeModalState();
}

class _MicroNudgeModalState extends State<MicroNudgeModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero)
            .animate(curve);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 640).copyWith(maxHeight: maxH),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: _NudgeCard(
                    scheme: scheme,
                    title: widget.title,
                    body: widget.body,
                    onClose: widget.onClose,
                    onStart: widget.onStart,
                    onSnooze: () => widget.onSnooze(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- CARD ---------------- */

class _NudgeCard extends StatelessWidget {
  final ColorScheme scheme;
  final String title;
  final String body;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onSnooze;

  const _NudgeCard({
    required this.scheme,
    required this.title,
    required this.body,
    required this.onClose,
    required this.onStart,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e2(scheme),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CloseX(scheme: scheme, onClose: onClose),
          const SizedBox(height: AppSpacing.sm),
          _NudgeHeader(scheme: scheme, title: title, body: body),
          const SizedBox(height: AppSpacing.md),
          _NudgeCTAs(
            scheme: scheme,
            onStart: onStart,
            onSnooze: onSnooze,
          ),
        ],
      ),
    );
  }
}


class _CloseX extends StatelessWidget {
  final ColorScheme scheme;
  final VoidCallback onClose;

  const _CloseX({
    required this.scheme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Icon(
            PhosphorIconsLight.x,
            size: 24,
            color: scheme.onSurface.withOpacity(AppOpacities.secondary),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */

class _NudgeHeader extends StatelessWidget {
  final ColorScheme scheme;
  final String title;
  final String body;

  const _NudgeHeader({
    required this.scheme,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            PhosphorIconsRegular.fire,
            size: 24,
            color: scheme.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      scheme.onSurface.withOpacity(AppOpacities.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */

class _NudgeCTAs extends StatelessWidget {
  final ColorScheme scheme;
  final VoidCallback onStart;
  final VoidCallback onSnooze;

  const _NudgeCTAs({
    required this.scheme,
    required this.onStart,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryButton(
            scheme: scheme,
            label: 'Start',
            onTap: onStart,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _OutlineButton(
            scheme: scheme,
            label: 'Snooze',
            onTap: onSnooze,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */

class _PrimaryButton extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.scheme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.e1(scheme),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.scheme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: scheme.primary),
        ),
      ),
    );
  }
}
