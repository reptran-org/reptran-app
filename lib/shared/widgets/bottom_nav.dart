import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'tab_item.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.current});
  final TabItem current;

  void _go(BuildContext context, TabItem dest) {
    if (dest == current) return;
    context.go(dest.route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const items = [
      (PhosphorIconsFill.house, 'Home', TabItem.home),
      (PhosphorIconsFill.barbell, 'Workout', TabItem.workout),
      (PhosphorIconsFill.usersThree, 'Community', TabItem.community),
      (PhosphorIconsFill.userCircle, 'Profile', TabItem.profile),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(width: 1, color: cs.outline)),
          boxShadow: AppShadows.e1(cs),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6), // reduce only vertical
        child: Row(
          children: items.map((it) {
            final isActive = it.$3 == current;
            final color = isActive
                ? cs.onSurface
                : cs.onSurface.withValues(alpha: 0.6);

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _go(context, it.$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Keep original size
                      Icon(it.$1, size: 24, color: color),

                      const SizedBox(height: 4),

                      // ✅ Keep size but make safe
                      Text(
                        it.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}