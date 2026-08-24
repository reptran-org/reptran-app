import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';
import 'package:reptran_app/features/home/services/home_card_service.dart';
import 'package:reptran_app/features/profile/services/profile_service.dart';
import 'package:reptran_app/shared/widgets/app_scaffold.dart';
import 'package:reptran_app/shared/widgets/tab_item.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<HomeCardData> _homeCardFuture;
  late Future<Map<String, dynamic>> _followStatsFuture;
  late Future<Map<String, dynamic>> _progressFuture;
  late Future<List<dynamic>> _badgesFuture;
  

  ColorScheme _cs(BuildContext c) => Theme.of(c).colorScheme;
  bool _isLight(BuildContext c) => Theme.of(c).brightness == Brightness.light;

  @override
  void initState() {
    super.initState();
    _homeCardFuture = HomeCardService().fetchHomeCardData();
    _followStatsFuture = ActivityService().getFollowStats();
    _progressFuture = ProfileService().getProfileProgress();
     _badgesFuture = ProfileService().getBadges();
  }

  @override
  Widget build(BuildContext context) {
    final cs = _cs(context);
    final isLight = _isLight(context);

    return AppScaffold(
      current: TabItem.profile,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─────────────────────────────────────────────
            // Header
            // ─────────────────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Row(
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────
            // Cards
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  // 🔹 Profile Identity Card (REAL DATA)
                  FutureBuilder<HomeCardData>(
                    future: _homeCardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Soft placeholder
                        return const SizedBox(height: 220);
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        // Fail silently — Profile still loads
                        return const SizedBox();
                      }

                      return _buildProfileCard(
                        context,
                        cs,
                        isLight,
                        snapshot.data!,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildProgressCard(context, cs, isLight),
                  const SizedBox(height: 24),
                  _buildAchievementsCard(context, cs, isLight),
                  const SizedBox(height: 24),
                  _buildSocialCard(context, cs, isLight),

                  const SizedBox(height: 24),

                  // 🔹 Settings Card (existing)
                  _buildSettingsCard(context, cs, isLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // class ProfilePage extends StatelessWidget {
  //   const ProfilePage({super.key});

  //   ColorScheme _cs(BuildContext c) => Theme.of(c).colorScheme;
  //   bool _isLight(BuildContext c) => Theme.of(c).brightness == Brightness.light;

  //   @override
  //   Widget build(BuildContext context) {
  //     final cs = _cs(context);
  //     final isLight = _isLight(context);

  //        return AppScaffold(
  //       current: TabItem.profile,
  //       body: SingleChildScrollView(
  //         child: Column(
  //           children: [
  //             // Top header (Profile title + edit icon)
  //   Container(
  //   color: cs.surface,
  //   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
  //   child: Row(
  //     children: [
  //       Text(
  //         'Profile',
  //         style: TextStyle(
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //           color: cs.onSurface,
  //           height: 1.2
  //         ),
  //       ),
  // //       const Spacer(),
  // //       InkWell(
  // //   borderRadius: BorderRadius.circular(8),
  // //   onTap: () => context.push('/profile/edit'),
  // //   child: Container(
  // //     width: 32,
  // //     height: 32,
  // //     decoration: BoxDecoration(
  // //       color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
  // //       borderRadius: BorderRadius.circular(8),
  // //       border: AppBorders.boxCard(cs),
  // //     ),
  // //     child: Icon(
  // //       PhosphorIconsRegular.notePencil,
  // //       size: 22,
  // //       color: cs.onSurface,
  // //     ),
  // //   ),
  // // )

  //     ],
  //   ),
  // ),

  //             const SizedBox(height: 24),

  //             // Cards section wrapper padding 24 left/right, 24 top, 48 bottom
  //             Padding(
  //               padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
  //               child: Column(
  //                 children: [
  //                   // _buildProfileCard(context, cs, isLight),

  //                   const SizedBox(height: 24),
  //                   // _buildProgressCard(context, cs, isLight),
  //                   // const SizedBox(height: 24),
  //                   // _buildAchievementsCard(context, cs, isLight),
  //                   // const SizedBox(height: 24),
  //                   // _buildSocialCard(context, cs, isLight),
  //                   // const SizedBox(height: 24),
  //                   _buildSettingsCard(context, cs, isLight),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  // Widget _buildProfileCard(BuildContext context, ColorScheme cs, bool isLight) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft, // approximation of 135deg
  //         end: Alignment.bottomRight,
  //         colors: [cs.primary, cs.secondary],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       border: AppBorders.boxCard(cs),
  //       boxShadow: AppShadows.e1(cs),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start, // Change to start to prevent the column from stretching
  //       children: [
  //         // Avatar column + text
  //         Expanded( // Wrap the content column in Expanded to take available space
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Avatar 80x80 circle with 3px white 30% border
  //               Container(
  //                 width: 80,
  //                 height: 80,
  //                 decoration: BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   color: Colors.white.withValues(alpha: 0.2),
  //                   border: Border.all(
  //                     color: Colors.white.withValues(alpha: 0.3),
  //                     width: 3,
  //                   ),
  //                 ),
  //                 alignment: Alignment.center,
  //                 child: Text(
  //                   'A',
  //                   style: const TextStyle(
  //                     fontSize: 32,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               SizedBox(
  //                 width: 220,
  //                 child: Text(
  //                   'I am the type of person who works out 4x/week',
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               // NEW ROW for "THIS WEEK" text and the progress circle
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.end, // Align the progress circle and text at the bottom
  //                 children: [
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       const Text(
  //                         'THIS WEEK',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 8),
  //                       const Text(
  //                         '3 of 4 done',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const Spacer(), // Pushes the progress circle to the right
  //                   // Progress circle 60x60 border 6px white 75% filled
  //                   _CircularProgressSmall(
  //                     size: 60,
  //                     strokeWidth: 6,
  //                     value: 0.75,
  //                     backgroundColor: AppColors.neutralLight,
  //                     progressColor: Colors.white,
  //                     text: '75%',
  //                     textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),

  //         // Removed the Spacer and the _CircularProgressSmall from the outer Row.
  //         // The outer Row now implicitly sizes to its children.
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProfileCard(
    BuildContext context,
    ColorScheme cs,
    bool isLight,
    HomeCardData data,
  ) {
    final weeklyGoal = data.weeklyIntent;

    final weeklyCount = data.weeklyCount;
    final progress = weeklyGoal > 0 ? weeklyCount / weeklyGoal : 0.0;
    final avatarUrl = data.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,

                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          (data.name?.isNotEmpty == true)
                              ? data.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Identity sentence
                SizedBox(
                  width: 220,
                  child: Text(
                    data.futureSelf ??
                        'I am the type of person who shows up consistently.',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Weekly progress row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THIS WEEK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$weeklyCount of $weeklyGoal done',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    _CircularProgressSmall(
                      size: 60,
                      strokeWidth: 6,
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      progressColor: Colors.white,
                      text: '${(progress * 100).round()}%',
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProgressCard(
  BuildContext context,
  ColorScheme cs,
  bool isLight,
) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _progressFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          // ✅ No fixed height — let content size it naturally
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: AppBorders.boxCard(cs),
            boxShadow: AppShadows.e1(cs),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: CircularProgressIndicator(
                  color: cs.primary, strokeWidth: 2),
            ),
          ),
        );
      }

      if (snapshot.hasError || !snapshot.hasData) return const SizedBox();

      final data        = snapshot.data!;
      final streak      = (data['streak']      as Map?) ?? {};
      final recovery    = (data['recovery']    as Map?) ?? {};
      final consistency = (data['consistency'] as Map?) ?? {};
      final weekly      = (data['weekly']      as Map?) ?? {};
      final totals      = (data['totals']      as Map?) ?? {};
      final rawBars     = (data['weeklyBars']  as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final currentStreak    = (streak['current']    as num?)?.toInt()    ?? 0;
      final longestStreak    = (streak['longest']    as num?)?.toInt()    ?? 0;
      final recoveryScore    = (recovery['score']    as num?)?.toDouble() ?? 0;
      final recoveryLabel    = (recovery['label']    as String?)          ?? '—';
      final consistencyScore = (consistency['score'] as num?)?.toDouble() ?? 0;
      final consistencyLabel = (consistency['label'] as String?)          ?? '—';
      final weeklyTarget     = (weekly['target']     as num?)?.toDouble() ?? 6;
      final weeklyStatus     = (weekly['status']     as String?)          ?? '';
      final sessions         = (totals['sessions']   as num?)?.toInt()    ?? 0;
      final volume           = (totals['volume']     as num?)?.toInt()    ?? 0;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ Shrink-wrap the card
          children: [
            // ── Title ─────────────────────────────────
            Text(
              'Progress Dashboard',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: AppTypography.wSemibold,
                color: cs.onSurface,
                height: AppTypography.lhTight,
              ),
            ),
            const SizedBox(height: 20),

            // ── 3-up metric strip ──────────────────────
            Container(
              decoration: BoxDecoration(
                color:
                    isLight ? AppColors.neutralLight : AppColors.neutralDark,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        cs: cs,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.accent,
                        label: 'Streak',
                        value: '$currentStreak days',
                        sub: 'Best $longestStreak',
                      ),
                    ),
                    _VDivider(cs: cs),
                    Expanded(
                      child: _StatTile(
                        cs: cs,
                        icon: Icons.favorite_rounded,
                        iconColor: cs.secondary,
                        label: 'Recovery',
                        value: recoveryLabel,
                        sub: '${(recoveryScore * 100).round()}%',
                      ),
                    ),
                    _VDivider(cs: cs),
                    Expanded(
                      child: _StatTile(
                        cs: cs,
                        icon: Icons.bolt_rounded,
                        iconColor: cs.primary,
                        label: 'Consistency',
                        value: consistencyLabel,
                        sub: '${(consistencyScore * 100).round()}%',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Totals ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TotalTile(
                    cs: cs,
                    isLight: isLight,
                    icon: Icons.fitness_center_rounded,
                    label: 'Total Sessions',
                    value: '$sessions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TotalTile(
                    cs: cs,
                    isLight: isLight,
                    icon: Icons.monitor_weight_outlined,
                    label: 'Total Volume',
                    value: _formatVolume(volume),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Weekly bar chart ───────────────────────
            if (rawBars.isNotEmpty)
              _WeeklyBarChart(
                bars: rawBars,
                target: weeklyTarget,
                status: weeklyStatus,
                cs: cs,
                isLight: isLight,
              ),
          ],
        ),
      );
    },
  );
}

String _formatVolume(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

 
 
 
 
 
 
 
 
 
Widget _buildAchievementsCard(
  BuildContext context,
  ColorScheme cs,
  bool isLight,
) {
  return FutureBuilder<List<dynamic>>(
    future: _badgesFuture,
    builder: (context, snapshot) {
      final isLoading = snapshot.connectionState == ConnectionState.waiting;
      final badges = snapshot.data ?? [];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: AppTypography.wSemibold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 80,
                    height: 110,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                ),
              )
            else if (badges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No achievements yet — keep going!',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: badges
                    .map<Widget>((b) => _AchievementItem(
                          label: b['title'] as String,
                          description: b['description'] as String,
                          iconUrl: b['iconUrl'] as String,
                          unlocked: b['unlocked'] as bool,
                          cs: cs,
                          isLight: isLight,
                        ))
                    .toList(),
              ),
          ],
        ),
      );
    },
  );
}



// ── Shimmer placeholder (3 ghost badges) ────────────────────
Widget _buildBadgeShimmer(ColorScheme cs) {
  return Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: List.generate(
      3,
      (_) => Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
  );
}

// ── Empty state ─────────────────────────────────────────────
Widget _buildBadgeEmpty(ColorScheme cs) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Center(
      child: Text(
        'No badges yet — keep going!',
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
      ),
    ),
  );
}


  Widget _buildSocialCard(BuildContext context, ColorScheme cs, bool isLight) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _followStatsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final following = snapshot.data?['followingCount'] ?? 0;
        final followers = snapshot.data?['followersCount'] ?? 0;
        final followerUsers = snapshot.data?['followers'] ?? [];
        final followingUsers = snapshot.data?['following'] ?? [];

        // 👇 fallback logic
        final displayUsers = followerUsers.isNotEmpty
            ? followerUsers
            : followingUsers;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: AppBorders.boxCard(cs),
            boxShadow: AppShadows.e1(cs),
          ),
          child: Column(
            children: [
              // Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Social',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Followers / Following
              GestureDetector(
                onTap: () => context.push('/profile/followers-following'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Following
                    Column(
                      children: [
                        isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                following.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                        const SizedBox(height: 8),
                        Text(
                          'FOLLOWING',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 48),

                    // Followers
                    Column(
                      children: [
                        isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                followers.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                        const SizedBox(height: 8),
                        Text(
                          'FOLLOWERS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (!isLoading && displayUsers.isNotEmpty)
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 40 + 3 * 24, // correct width for overlap
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int i = 0; i < displayUsers.length && i < 4; i++)
                          _stackedAvatar(i, cs, isLight, user: displayUsers[i]),

                        if (displayUsers.length > 4)
                          Positioned(
                            left: 3 * 24,
                            child: _moreAvatar(
                              '+${followerUsers.length - 4}',
                              cs,
                              isLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _socialAction(
                      context,
                      cs,
                      icon: '👥',
                      label: 'View Network',
                      onTap: () => context.push('/profile/followers-following'),
                    ),
                  ),
                  // const SizedBox(width: 12),
                  // Expanded(
                  //   child: _socialAction(
                  //     context,
                  //     cs,
                  //     icon: '➕',
                  //     label: 'Find People',
                  //     onTap: () => context.push('/profile/followers-following'),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _socialAction(
    BuildContext context,
    ColorScheme cs, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    ColorScheme cs,
    bool isLight,
  ) {
    Widget settingRow(
      IconData icon,
      String label, {
      String? route, // 👈 optional now
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadii.full),
        onTap: route != null
            ? () => context.push(route)
            : null, // 👈 disables tap if no route
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: cs.onSurface.withOpacity(AppOpacities.secondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.micro,
                fontWeight: AppTypography.wSemibold,
                color: cs.onSurface.withOpacity(AppOpacities.secondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: AppTypography.wSemibold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3 Settings Options Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              settingRow(
                Icons.notifications,
                'Notifications',
                 route: '/profile/notifications',
              ),
              settingRow(
                Icons.person,
                'Account',
                route: '/profile/settings/account',
              ),
              settingRow(
                Icons.settings,
                'Environment',
                route: '/profile/settings/environment',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stackedAvatar(
    int index,
    ColorScheme cs,
    bool isLight, {
    required dynamic user,
  }) {
    final left = index * 24.0; // clean overlap for 40px avatars

    final name = (user['name'] ?? 'U').toString();
    final avatarUrl = user['avatarUrl'];

    return Positioned(
      left: left,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.surface, width: 2),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(avatarUrl, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF38BFB2), Color(0xFF0F6F6E)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _moreAvatar(String label, ColorScheme cs, bool isLight) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BFB2), Color(0xFF0F6F6E)],
        ),
        border: Border.all(color: cs.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Small circular progress widget used in cards
class _CircularProgressSmall extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double value;
  final Color backgroundColor;
  final Color progressColor;
  final String text;
  final TextStyle textStyle;

  const _CircularProgressSmall({
    required this.size,
    required this.strokeWidth,
    required this.value,
    required this.backgroundColor,
    required this.progressColor,
    required this.text,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(backgroundColor),
            ),
          ),
          // foreground progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          // inner text
          Text(text, style: textStyle),
        ],
      ),
    );
  }
}

/// Simple vertical bar component for weekly consistency
class _BarColumn extends StatelessWidget {
  final double height;
  final Gradient gradient;

  const _BarColumn({required this.height, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: gradient,
      ),
    );
  }
}

/// Achievement item widget with unlocked/locked variants
// class _AchievementItem extends StatelessWidget {
//   final String label;
//   final bool unlocked;
//   final ColorScheme cs;
//   final bool isLight;

//   const _AchievementItem({
//     required this.label,
//     required this.unlocked,
//     required this.cs,
//     required this.isLight,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const double diameter = 60;
//     const double itemWidth = 72;

//     final Widget badge = Container(
//       width: diameter,
//       height: diameter,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: unlocked
//             ? LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [AppColors.accent, cs.primary],
//               )
//             : null,
//         color: unlocked
//             ? null
//             : (isLight ? AppColors.neutralLight : AppColors.neutralDark),
//         boxShadow: unlocked ? AppShadows.e1(cs) : null,
//         border: unlocked
//             ? null
//             : Border.all(color: cs.outline ?? Colors.grey, width: 2),
//       ),
//       child: Center(
//         child: unlocked
//             ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
//             : Icon(Icons.lock, color: cs.onSurface.withOpacity(0.6), size: 20),
//       ),
//     );

//     final Widget content = unlocked
//         ? badge
//         : DashedContainer(
//             diameter: diameter,
//             child: badge,
//             dashColor: cs.outline ?? Colors.grey,
//             strokeWidth: 2,
//           );

//     return SizedBox(
//       width: itemWidth,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           content,
//           const SizedBox(height: 8),
//           // Label under the badge
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: unlocked ? cs.onSurface : cs.onSurface.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class DashedContainer extends StatelessWidget {
  final Widget child;
  final double diameter;
  final Color dashColor;
  final double strokeWidth;
  final double dashLength; // px
  final double dashGap; // px

  const DashedContainer({
    required this.child,
    required this.diameter,
    required this.dashColor,
    required this.strokeWidth,
    this.dashLength = 6.0,
    this.dashGap = 4.0,
    super.key, // Added super.key for best practice
  });

  @override
  Widget build(BuildContext context) {
    // 1. Use a SizedBox to enforce the diameter constraint.
    return SizedBox(
      width: diameter,
      height: diameter,
      // 2. The CustomPaint will take the exact size of the SizedBox.
      child: CustomPaint(
        foregroundPainter: _DashedCirclePainter(
          color: dashColor,
          strokeWidth: strokeWidth,
          dashLength: dashLength,
          dashGap: dashGap,
        ),
        // 3. The child is placed directly, occupying the same diameter.
        child: child,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Calculate radius to keep the stroke inside the bounds.
    final double radius =
        (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final Rect rect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    );

    final double circumference = 2 * math.pi * radius;
    final double step = dashLength + dashGap;

    if (step <= 0) return;

    double drawn = 0.0;
    while (drawn < circumference) {
      final double currentDash = math.min(dashLength, circumference - drawn);
      final double startAngle =
          (drawn / radius) - (math.pi / 2); // Start at the top (12 o'clock)
      final double sweepAngle = currentDash / radius;

      // Draw the arc segment
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false, // useCenter: false
        paint,
      );
      drawn += step;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.dashLength != dashLength ||
        old.dashGap != dashGap;
  }
}

// ─────────────────────────────────────────────────────────────
// Progress card sub-widgets
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Progress Dashboard sub-widgets
// ─────────────────────────────────────────────────────────────

class _VDivider extends StatelessWidget {
  final ColorScheme cs;
  const _VDivider({required this.cs});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: cs.outline.withValues(alpha: 0.5),
      );
}

class _StatTile extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatTile({
    required this.cs,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
              height: AppTypography.lhTight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
              height: AppTypography.lhTight,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
              height: AppTypography.lhTight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final ColorScheme cs;
  final bool isLight;
  final IconData icon;
  final String label;
  final String value;

  const _TotalTile({
    required this.cs,
    required this.isLight,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, color: cs.primary, size: 16),
          ),
          const SizedBox(width: 12),
           Expanded(          // ← add this
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                  height: AppTypography.lhTight,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
                  height: AppTypography.lhTight,
                ),
              ),
            ],
          ),
           ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Weekly bar chart
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// _buildProgressCard  (drop-in replacement)
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// _WeeklyBarChart  (drop-in replacement)
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> bars;
  final double target;
  final String status;
  final ColorScheme cs;
  final bool isLight;

  const _WeeklyBarChart({
    required this.bars,
    required this.target,
    required this.status,
    required this.cs,
    required this.isLight,
  });

  @override
  State<_WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<_WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  static String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const mo = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${mo[dt.month]} ${dt.day}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs      = widget.cs;
    final isLight = widget.isLight;

    final counts  =
        widget.bars.map((b) => (b['count'] as num).toDouble()).toList();
    final dataMax = counts.isEmpty ? 0.0 : counts.reduce(math.max);
    final rawMax  = math.max(dataMax, widget.target);
    final yMax    = (((rawMax + 1) / 2).ceil() * 2.0).clamp(4.0, 100.0);
    final yLabels = List.generate(5, (i) => yMax - (yMax / 4 * i));

    final isBehind    = widget.status == 'behind';
    final statusColor = isBehind ? AppColors.accent : AppColors.positive;
    final statusLabel = isBehind ? 'Behind target' : 'On track';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────
          Row(
            children: [
              Flexible(
                child: Text(
                  'Weekly Sessions',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.wSemibold,
                    color: cs.onSurface,
                    height: AppTypography.lhTight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Status badge no longer in the Row—moved to Wrap below
              // so it never overflows on narrow screens
              _StatusBadge(color: statusColor, label: statusLabel),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chart area (fully responsive via LayoutBuilder) ──────────
          LayoutBuilder(
            builder: (context, constraints) {
              final availableW = constraints.maxWidth;

              // ✅ Responsive dimensions derived from available width
              final yAxisW   = availableW < 280 ? 16.0 : 24.0;
              final axisGap  = 6.0;
              final barAreaH = (availableW * 0.38).clamp(90.0, 200.0);
              const barPadH  = 2.5;

              return AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Y-axis labels ──────────────────────
                          SizedBox(
                            width: yAxisW,
                            height: barAreaH,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: yLabels
                                  .map(
                                    (v) => Text(
                                      v.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        height: 1,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          SizedBox(width: axisGap),

                          // ── Bars ───────────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bar area
                                SizedBox(
                                  height: barAreaH,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Mid grid line
                                      Positioned(
                                        bottom: barAreaH * 0.5,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),

                                      // Target dashed line
                                      Positioned(
                                        bottom: (widget.target / yMax) *
                                            barAreaH,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: CustomPaint(
                                                size: const Size(
                                                    double.infinity, 1),
                                                painter: _DashedLinePainter(
                                                  color: cs.primary
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Goal ${widget.target.toInt()}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                height: 1,
                                                fontWeight:
                                                    AppTypography.wSemibold,
                                                color: cs.primary
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Bars
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children:
                                            widget.bars.map((bar) {
                                          final count = (bar['count'] as num)
                                              .toDouble();
                                          final isCurrent =
                                              bar['isCurrent'] as bool? ??
                                                  false;
                                          final ratio = yMax > 0
                                              ? (count / yMax)
                                                  .clamp(0.0, 1.0)
                                              : 0.0;
                                          final barH = isCurrent
                                              ? barAreaH
                                              : math.max(
                                                  ratio *
                                                      barAreaH *
                                                      _anim.value,
                                                  count > 0 ? 2.0 : 0.0,
                                                );
                                          final metTarget =
                                              count >= widget.target;

                                          return Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: barPadH),
                                              child: isCurrent
                                                  ? Container(
                                                      height: barAreaH,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                AppRadii.xs),
                                                        color: cs.onSurface
                                                            .withValues(
                                                                alpha: 0.04),
                                                        border: Border.all(
                                                          color: cs.onSurface
                                                              .withValues(
                                                                  alpha: 0.10),
                                                          width: 1,
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: barH,
                                                      decoration:
                                                          BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              AppRadii.xs),
                                                        ),
                                                        gradient: metTarget
                                                            ? LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  cs.primary,
                                                                  cs.secondary,
                                                                ],
                                                              )
                                                            : LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  AppColors
                                                                      .accent,
                                                                  AppColors
                                                                      .accentDark,
                                                                ],
                                                              ),
                                                      ),
                                                    ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── X-axis labels ───────────────
                                const SizedBox(height: 7),
                                Row(
                                  children: widget.bars.map((bar) {
                                    final count = (bar['count'] as num)
                                        .toDouble();
                                    final isCurrent =
                                        bar['isCurrent'] as bool? ?? false;
                                    final start =
                                        bar['start'] as String? ?? '';
                                    final metTarget =
                                        count >= widget.target;

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: barPadH),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // ✅ FittedBox prevents count
                                            // text from overflowing narrow bars
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                isCurrent
                                                    ? '—'
                                                    : '${count.toInt()}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  height: 1,
                                                  fontWeight:
                                                      AppTypography.wSemibold,
                                                  color: isCurrent
                                                      ? cs.onSurface
                                                          .withValues(
                                                              alpha: 0.2)
                                                      : metTarget
                                                          ? cs.primary
                                                          : AppColors.accent,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            // ✅ FittedBox prevents date
                                            // label from overflowing
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                _shortDate(start),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  height: 1,
                                                  fontWeight: isCurrent
                                                      ? AppTypography.wSemibold
                                                      : AppTypography.wRegular,
                                                  color: isCurrent
                                                      ? cs.primary
                                                      : cs.onSurface
                                                          .withValues(
                                                              alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // ── Legend ──────────────────────────────────
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(cs: cs, color: cs.primary, label: 'Met target'),
              _LegendItem(
                  cs: cs, color: AppColors.accent, label: 'Below target'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    child: CustomPaint(
                      size: const Size(18, 1),
                      painter: _DashedLinePainter(
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Target (${widget.target.toInt()})',
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      color: cs.onSurface
                          .withValues(alpha: AppOpacities.secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Small helper widget extracted to avoid Row overflow in the chart header
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Color  color;
  final String label;
  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: AppTypography.wSemibold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashW = 4.0;
    const gapW  = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dashW).clamp(0, size.width), 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _LegendItem extends StatelessWidget {
  final ColorScheme cs;
  final Color color;
  final String label;

  const _LegendItem({
    required this.cs,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.micro,
            color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String title;
  final String description;
  final String iconUrl;
  final bool unlocked;
  final String? earnedAt;
  final ColorScheme cs;
  final bool isLight;

  const _BadgeItem({
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.unlocked,
    required this.cs,
    required this.isLight,
    this.earnedAt,
  });

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnedLabel = _formatDate(earnedAt);

    return Tooltip(
      message: description,
      preferBelow: true,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: unlocked
              ? cs.primary.withValues(alpha: isLight ? 0.06 : 0.12)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: unlocked
                ? cs.primary.withValues(alpha: isLight ? 0.20 : 0.28)
                : cs.onSurface.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────
            SizedBox(
              width: 48,
              height: 48,
              child: unlocked
                  ? Image.network(
                      iconUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_events_rounded,
                        size: 32,
                        color: cs.primary,
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                      child: Opacity(
                        opacity: 0.30,
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.lock_outline_rounded,
                            size: 28,
                            color: cs.onSurface.withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: AppSpacing.xxs),

            // ── Title ─────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTypography.micro,
                fontWeight: unlocked
                    ? AppTypography.wSemibold
                    : AppTypography.wRegular,
                color: unlocked
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: AppOpacities.tertiary),
                height: AppTypography.lhTight,
              ),
            ),

            // ── Date chip (unlocked only) ─────────────
            if (unlocked && earnedLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                earnedLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: AppTypography.wMedium,
                  color: cs.primary.withValues(alpha: 0.70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final String label;
  final String description;
  final String iconUrl;
  final bool unlocked;
  final ColorScheme cs;
  final bool isLight;

  const _AchievementItem({
    required this.label,
    required this.description,
    required this.iconUrl,
    required this.unlocked,
    required this.cs,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ──────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: unlocked
                    ? cs.primary.withValues(alpha: isLight ? 0.08 : 0.15)
                    : cs.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked
                      ? cs.primary.withValues(alpha: isLight ? 0.25 : 0.35)
                      : cs.onSurface.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: unlocked
                  ? Image.network(
                      iconUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_events_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.lock_outline_rounded,
                            size: 32,
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 8),

            // ── Label ───────────────────────────────────
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTypography.micro,
                fontWeight: unlocked
                    ? AppTypography.wMedium
                    : AppTypography.wRegular,
                color: unlocked
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: AppOpacities.tertiary),
                height: AppTypography.lhTight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}