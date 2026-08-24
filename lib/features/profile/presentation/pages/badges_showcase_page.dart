// BadgesRewardsPage.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'dart:ui';

import 'package:reptran_app/features/profile/presentation/pages/badge_modal.dart'; // add this at file top for ImageFilter

class BadgesShowcasePage extends StatelessWidget {
  const BadgesShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top framing

                // FIRST SECTION (hasBg: true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heading + Subheading
                    // FIRST SECTION (header area)
                    Container(
                      color: scheme.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // icon + title stacked vertically
                          Icon(
                            PhosphorIconsRegular.arrowLeft,
                            size: 24,
                            color: scheme.onSurface,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Your Badges 🏅',
                            style: textTheme.headlineSmall!.copyWith(
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Proof of your consistency, recovery, and growth.',
                            style: textTheme.bodyMedium?.copyWith(height: 1.2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Horizontal badges scroller
                          Text(
                            "Who You're Becoming",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _BadgeMiniCard(
                                  emoji: '🏗️',
                                  title: '4x Builder',
                                  subtitle:
                                      'Maintained 4x/week identity for 4 weeks',
                                  scheme: scheme,
                                  textTheme: textTheme,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _BadgeMiniCard(
                                  emoji: '🏃‍♂️',
                                  title: '5x Athlete',
                                  subtitle: 'Hit 5 sessions/week for 3 weeks',
                                  scheme: scheme,
                                  textTheme: textTheme,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _BadgeMiniCard(
                                  emoji: '🌟',
                                  title: '3x Consistent',
                                  subtitle: 'Tried 3x weekly workouts',
                                  scheme: scheme,
                                  textTheme: textTheme,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Showing Up, Day by Day (2x2 grid using Rows + Flexible)
                          Text(
                            "Showing Up, Day by Day",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Column(
                            children: [
                              IntrinsicHeight(
                                // ensures equal height across cards in this row
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .stretch, // fill vertical space
                                  children: [
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _AchievementTile(
                                          icon: PhosphorIconsRegular.fire,
                                          title: 'Streak Master',
                                          subtitle: 'Earned Oct 2025',
                                          isEarned: true,
                                          usePrimaryForAccent: false,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _AchievementTile(
                                          icon: PhosphorIconsRegular.calendar,
                                          title: 'Week Warrior',
                                          subtitle: '7 days away',
                                          isEarned: false,
                                          usePrimaryForAccent: false,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _AchievementTile(
                                          icon: PhosphorIconsRegular.brain,
                                          title: 'Habit Legend',
                                          subtitle: 'Earned Sep 2025',
                                          isEarned: true,
                                          usePrimaryForAccent: true,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _AchievementTile(
                                          icon: PhosphorIconsRegular.crown,
                                          title: 'Monthly Champion',
                                          subtitle: '15 days away',
                                          isEarned: false,
                                          usePrimaryForAccent: false,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.md),
                          // Bounce-back section (paste where appropriate)
                          Text(
                            'Your Bounce-Back Moments',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _BounceCard(
                                      icon: PhosphorIconsRegular
                                          .leaf, // swap icon as needed
                                      title: 'Bounce Back Hero',
                                      subtitle: 'Recovered after 3 missed days',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16), // 16px gap
                                // 2
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _BounceCard(
                                      icon: PhosphorIconsRegular
                                          .repeat, // swap icon
                                      title: 'Comeback Champ',
                                      subtitle: 'Rebuilt momentum twice',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16), // 16px gap
                                // 3
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _BounceCard(
                                      icon: PhosphorIconsRegular
                                          .lightning, // swap icon
                                      title: 'Momentum Rebuilder',
                                      subtitle: 'Got back on track in 24h',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Challenges Completed section
                          Text(
                            "Challenges You've Completed",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _ChallengeTile(
                                          emoji: '☀️',
                                          title: 'Summer Streak 2025',
                                          isLocked: false,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _ChallengeTile(
                                          emoji: '🎯',
                                          title: 'RepTran Challenge #3',
                                          isLocked: false,
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _ChallengeTile(
                                          emoji: '☀️',
                                          title: 'Summer Streak 2025',
                                          isLocked:
                                              true, // blurred/locked duplicate
                                          scheme: scheme,
                                          textTheme: textTheme,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _Card(
                                        scheme: scheme,
                                        child: _ChallengeTile(
                                          emoji: '☀️',
                                          title: 'Summer Streak 2025',
                                          isLocked:
                                              true, // blurred/locked duplicate
                                          scheme: scheme,
                                          textTheme: textTheme,
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
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // SECOND SECTION (rewards area) — normal page padding applies
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Compact progress banner (card-like)
                      // Gradient reward card (replace _Card(...) with this)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-0.819, -0.574), // ≈35°
                            end: const Alignment(0.819, 0.574),
                            colors: [scheme.primary, scheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: AppBorders.boxCard(scheme),
                          boxShadow: AppShadows.e1(scheme),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header row: text left, icon right
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Badges Earned: 12 / 24',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.whiteUtility,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        "Next Unlock: 'Diamond Elite' — 85% complete",
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.whiteUtility,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Icon(
                                  PhosphorIconsRegular.medal,
                                  size: 24,
                                  color: AppColors.whiteUtility,
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // Buttons row
                            Row(
                              children: [
                                // Primary button (white bg, primary text)
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () {}, // must not be null
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.whiteUtility,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.md,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Keep Building',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: AppSpacing.xs),

                                // Secondary button (20% neutral dark bg, whiteUtility text)
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () {}, // must not be null
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neutralDark
                                            .withOpacity(0.20),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.md,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'See Reward Store',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.whiteUtility,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Divider(color: scheme.outline),
                      const SizedBox(height: AppSpacing.xl),

                      // Rewards & Upgrades header
                      Text(
                        'Rewards & Upgrades 🎁',
                        style: textTheme.headlineSmall!.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Earn points and unlock identity upgrades as you stay consistent.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withOpacity(
                            AppOpacities.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Points summary card + progress
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-0.819, -0.574), // ≈35°
                            end: const Alignment(0.819, 0.574),
                            colors: [scheme.primary, scheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: AppBorders.boxCard(scheme),
                          boxShadow: AppShadows.e1(scheme),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top row: left = headline + tier, right = progress circle
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // left texts (headline + tier)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '2,450 Points',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: AppColors.whiteUtility,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Tier: Silver Builder 🏁',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.whiteUtility,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: AppSpacing.sm),

                                // progress circle (aligned with the top group)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // outer border 4px with positive color
                                    border: Border.all(
                                      color: AppColors.positive,
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    // inner filled ring to give a filled look while keeping a border
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors
                                            .transparent, // filled with positive color
                                      ),
                                      child: Center(
                                        child: Text(
                                          '85%',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: AppColors.whiteUtility,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // subtitle (below the top row)
                            Text(
                              'Earn points from workouts, streaks, and recoveries.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.whiteUtility,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // full width button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.whiteUtility
                                      .withOpacity(0.20),
                                  foregroundColor: AppColors.whiteUtility,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'View Reward History',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.whiteUtility,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Redeemable Rewards grid (2-column)
                      Text('Redeemable Rewards', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),

                      // 2-column rows with Flexible children
                      // Redeemable Rewards grid (2 columns x 3 rows)
                      Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '🎨',
                                      title: 'Identity Avatar Upgrade',
                                      subtitle: 'New Builder badge border',
                                      pointsText: '800pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '💪',
                                      title: 'Motivation Pack',
                                      subtitle: 'Animated streak flames',
                                      pointsText: '1200pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '🧘',
                                      title: 'Calm Recovery Theme',
                                      subtitle: 'Soft green layout skin',
                                      pointsText: '1500pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '🏆',
                                      title: 'Champion Frame',
                                      subtitle: 'Profile ring for 60 days',
                                      pointsText: '2000pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '🔁',
                                      title: 'Re-entry Boost',
                                      subtitle: 'Extra recovery bonus points',
                                      pointsText: '600pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _Card(
                                    scheme: scheme,
                                    child: _RedeemableTile(
                                      emoji: '✨',
                                      title: 'Premium Celebrations',
                                      subtitle: 'Custom confetti effects',
                                      pointsText: '3000pts',
                                      scheme: scheme,
                                      textTheme: textTheme,
                                      locked:
                                          true, // if you want last one locked you can set this
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Info banner + buttons stacked vertically
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info card with left border accent
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors
                                      .accent, // Accent color for border
                                  width: 4,
                                ),
                              ),
                              boxShadow: AppShadows.e1(scheme),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                              horizontal: AppSpacing.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💪',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    "You're 120 pts away from the 'Builder Gold' tier. Keep showing up!",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Two buttons side-by-side
                          Row(
                            children: [
                              // Primary button (filled)
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: scheme.secondary,
                                      foregroundColor: AppColors.whiteUtility,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.md,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Redeem Now',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.whiteUtility,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: AppSpacing.sm),

                              // Outline button
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isLight
                                            ? scheme.primary
                                            : scheme.onSurface,
                                        width: 1,
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.md,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Earn More Points',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isLight
                                            ? scheme.primary
                                            : scheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl), // bottom framing
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Private helpers ----------

class _Card extends StatelessWidget {
  const _Card({required this.scheme, required this.child, super.key});
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: child,
    );
  }
}

class _BadgeMiniCard extends StatelessWidget {
  const _BadgeMiniCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () {
        showDialog(context: context, builder: (_) => const BadgeModal());
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.positive,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                'Unlocked',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary button (tokenized)
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // allowed literal
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          elevation: 4, // allow AppShadows.button effect via elevation
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(color: scheme.onSecondary),
          ),
        ),
      ),
    );
  }
}

/// Outline button
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // allowed literal
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: AppBorders.sideOnePx(scheme),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Text(label, style: textTheme.titleMedium),
      ),
    );
  }
}

/// Small Redeem button inside cards
/// Small Redeem button inside cards
class _SmallRedeemButton extends StatelessWidget {
  const _SmallRedeemButton({
    required this.label,
    required this.scheme,
    super.key,
  });

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // IntrinsicWidth protects the button from unbounded Row constraints by
    // sizing it to its intrinsic width, while SizedBox enforces token-compliant height.
    return IntrinsicWidth(
      child: SizedBox(
        height: 48, // allowed literal (control height)
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: AppBorders.sideOnePx(scheme),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEarned,
    required this.usePrimaryForAccent,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEarned;
  final bool usePrimaryForAccent;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final Color accentBase = usePrimaryForAccent
        ? scheme.primary
        : AppColors.accent;
    final Color iconBg = isEarned
        ? accentBase.withOpacity(0.20)
        : (isLight ? AppColors.neutralLight : AppColors.neutralDark);
    final Color iconColor = isEarned
        ? accentBase
        : scheme.onSurface.withOpacity(0.20);
    final Color upcomingTextColor = scheme.onSurface.withOpacity(0.60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 22, color: iconColor)),
        ),
        const SizedBox(height: AppSpacing.sm),

        // title
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isEarned ? scheme.onSurface : upcomingTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),

        // subtitle
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: isEarned ? scheme.onSurface : upcomingTextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // sparkle icon (only for earned)
        if (isEarned) ...[
          const SizedBox(height: AppSpacing.xs),
          Icon(
            PhosphorIconsRegular.sparkle,
            size: 14,
            color: usePrimaryForAccent ? scheme.primary : AppColors.accent,
          ),
        ],
      ],
    );
  }
}

class _BounceCard extends StatelessWidget {
  const _BounceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    // rely on _Card for padding; this widget should be left-aligned and compact
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // icon container (40x40)
        Container(
          width: AppSpacing.xl,
          height: AppSpacing.xl,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 20, color: scheme.primary)),
        ),

        const SizedBox(height: AppSpacing.sm),

        // title (left-aligned)
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.start,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppSpacing.xs),

        // subtitle (left-aligned, muted)
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.60),
          ),
          textAlign: TextAlign.start,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.emoji,
    required this.title,
    required this.isLocked,
    required this.scheme,
    required this.textTheme,
    super.key,
  });

  final String emoji;
  final String title;
  final bool isLocked;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main card content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji at top (no container)
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),

        // Locked overlay with real blur + lock icon
        if (isLocked)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Container(
                  color: scheme.surface.withOpacity(0.6),
                  child: Center(
                    child: Icon(
                      PhosphorIconsRegular.lock,
                      size: 28,
                      color: scheme.onSurface.withOpacity(0.20),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RedeemableTile extends StatelessWidget {
  const _RedeemableTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.pointsText,
    required this.scheme,
    required this.textTheme,
    this.locked = false,
    super.key,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String pointsText;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final chipBg = scheme.primary.withOpacity(0.10);
    final chipTextColor = scheme.primary;
    final isLight = scheme.brightness == Brightness.light;

    return Stack(
      children: [
        // Main vertical content (relies on _Card padding)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // spacing top to allow chip to sit in the corner visually if needed
            // (optional - you can remove this SizedBox if card padding already provides space)
            const SizedBox(height: AppSpacing.xs),

            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 22)),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.75),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // push button to bottom (gives natural spacing)
            const SizedBox(height: AppSpacing.sm),

            // Full-width redeem button (guaranteed spacing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: locked ? null : () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    40,
                  ), // ensures readable height
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: AppSpacing.sm,
                  ),
                  backgroundColor: scheme.primary,
                  foregroundColor: AppColors.whiteUtility,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  locked ? 'Locked' : 'Redeem',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.whiteUtility,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Points chip at top-right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isLight ? chipBg : AppColors.neutralDark,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              pointsText,
              style: textTheme.labelSmall?.copyWith(
                color: isLight ? chipTextColor : scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Optional locked overlay (subtle)
        if (locked)
          Positioned.fill(
            child: Container(
              color: scheme.surface.withOpacity(0.40),
              child:
                  const Center(), // preserves hit area; lock icon could be top-right as before
            ),
          ),
      ],
    );
  }
}
