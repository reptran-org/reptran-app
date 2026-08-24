import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/community/presentation/pages/activity_and_reactions_modal.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';
import 'package:reptran_app/shared/widgets/app_scaffold.dart';
import 'package:reptran_app/shared/widgets/tab_item.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

class IdentityStyle {
  static Color getColor(String? archetype) {
    switch (archetype?.toUpperCase()) {
      case 'STARTER':
        return AppColors.secondary;
      // softer, inviting → starting phase

      case 'RETURNER':
        return AppColors.accentDark;
      // stronger comeback energy

      case 'STABILIZER':
        return AppColors.positive;
      // green → balance & consistency

      case 'BUILDER':
        return AppColors.accent;
      // core RepTran identity

      case 'INTEGRATOR':
        return AppColors.primary;
      // deep, grounded → identity locked in

      default:
        return AppColors.accent; // ✅ fallback = BUILDER
    }
  }

  static String getLabel(String? archetype) {
    if (archetype == null || archetype.isEmpty) {
      return 'BUILDER';
    }
    return archetype.toUpperCase();
  }
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<_ActivityItem> activities = [];
  bool isLoading = true;
  int unreadCount = 0;

  String getMessage(String emoji, bool isAdding) {
    if (!isAdding) return 'Reaction removed';

    switch (emoji) {
      case '🔥':
        return 'You backed their comeback';
      case '💪':
        return 'You supported consistency';
      case '👏':
        return 'You showed appreciation';
      case '💯':
        return 'You gave full respect';
      default:
        return 'Support sent';
    }
  }

  Future<void> _fetchNotificationsCount() async {
    try {
      final res = await ActivityService().getNotifications();

      setState(() {
        unreadCount = res['unreadCount'] ?? 0;
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    Future.wait([
      _fetchActivities(),
      _fetchNotificationsCount(),
      _fetchCommunityStats(),
    ]);
  }

  Map<String, dynamic>? stats;

  Future<void> _fetchCommunityStats() async {
    try {
      final res = await ActivityService().getCommunityStats();

      setState(() {
        stats = res;
      });
    } catch (_) {}
  }

  Future<void> _fetchActivities() async {
    try {
      final res = await ActivityService().getFeed();

      final mapped = res.map<_ActivityItem>((a) {
        final actor = a['actor'];

        final payload = a['payload'] is String
            ? jsonDecode(a['payload'])
            : a['payload'];

        String text = '';

        switch (a['type']) {
          case 'SESSION_SHOWED_UP':
            final duration = payload?['durationMin'] ?? 0;
            text = '💪  showed up (${duration} min)';
            break;
          default:
            text = 'did something';
        }

        // ✅ summary from backend
        final raw = a['reactionsSummary'] as Map<String, dynamic>? ?? {};

        final counts = raw.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        );

        // ✅ user reactions
        final userReactions = (a['reactions'] as List<dynamic>? ?? [])
            .map((r) => r['emoji'] as String)
            .toSet();

        final archetype = actor?['identity']?['archetype'];

        return _ActivityItem(
          id: a['id'],
          name: (actor?['name'] ?? 'User').toString(),
          time: _timeAgo(a['createdAt'].replaceFirst(' ', 'T')),
          tag: IdentityStyle.getLabel(archetype),
          tagBg: IdentityStyle.getColor(archetype),
          text: text,
          avatarUrl: actor?['avatarUrl'],
          username: actor?['username'], // 👈 add this
          reactionCounts: counts,
          userReactions: userReactions,
        );
      }).toList();
      setState(() {
        activities = mapped;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _timeAgo(String iso) {
    final dt = DateTime.parse(iso);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final didToday = stats?['userDidToday'] ?? false;
    final todayCount = stats?['todayCount'] ?? 0;

    final others = didToday ? (todayCount - 1) : todayCount;

    final title = didToday
        ? '💪 You showed up today'
        : '⚡ Show up today — even 5 min counts';

    final subtitle = others > 0
        ? '$others others showed up today'
        : 'Be the first to show up today';

    final weekly = stats?['weeklyCount'] ?? 0;
    final userWeekly = stats?['userWeeklyCount'] ?? 0;

    const goal = 20;

    final progress = (weekly / goal).clamp(0.0, 1.0);
    final remaining = (goal - weekly).clamp(0, goal);

    // --- sample feed data (replace with real) ---

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return AppScaffold(
      current: TabItem.community,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ======= HEADER SECTION =======
            Container(
              color: schema.surface,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
              child: Column(
                children: [
                  // Title + bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: schema.onSurface,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/community/notifications'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.neutralDark
                                    : AppColors.neutralLight,
                                borderRadius: BorderRadius.circular(8),
                                border: AppBorders.boxCard(schema),
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.bell,
                                size: 22,
                              ),
                            ),

                            // 🔥 Notification dot
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: schema.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🌍 3,240 workouts logged today (gradient card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft, // ~135°
                        colors: [schema.primary, schema.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: AppBorders.boxCard(schema),
                      boxShadow: AppShadows.e1(schema),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Community Goal card (transparent bg)
                  GestureDetector(
                    // onTap: () => context.push('/community/community-pulse'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: schema.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: AppBorders.boxCard(schema),
                        boxShadow: AppShadows.e1(schema),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Community Goal: $goal sessions this week',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: schema.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '$weekly / $goal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.positive,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(color: schema.outline),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [
                                            schema.primary,
                                            schema.secondary,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '$weekly done',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: schema.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$remaining to go',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: schema.onSurface.withValues(
                                    alpha: 0.60,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: schema.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userWeekly > 0
                                  ? 'Your contribution: $userWeekly 💪'
                                  : 'Start contributing 💪',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: schema.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======= ACTIVITY FEED =======
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: schema.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...activities.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ActivityCard(
                        item: item,
                        schema: schema,
                        onReact: (emoji) async {
                          final isAdding = !item.userReactions.contains(emoji);

                          final updated = await ActivityService().react(
                            activityId: item.id,
                            emoji: emoji,
                          );

                          setState(() {
                            item.reactionCounts
                              ..clear()
                              ..addAll(
                                (updated as Map<String, dynamic>).map(
                                  (key, value) =>
                                      MapEntry(key, (value as num).toInt()),
                                ),
                              );

                            if (item.userReactions.contains(emoji)) {
                              item.userReactions.clear();
                            } else {
                              item.userReactions
                                ..clear()
                                ..add(emoji);
                            }
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(AppSpacing.sm),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                content: Row(
                                  children: [
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        getMessage(emoji, isAdding),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onInverseSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // ======= SUGGESTED TO FOLLOW (separate padding: 24,24,24,48) =======
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: _SuggestedFollowCard(schema: schema),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== REUSABLE MAJOR CARDS ==================

class _ActivityItem {
  final String id;
  final String name;
  final String time;
  final String tag;
  final Color tagBg;
  final String text;

  final String? avatarUrl;
  final String? username; // ✅ ADD THIS

  Map<String, int> reactionCounts;
  Set<String> userReactions;

  _ActivityItem({
    required this.id,
    required this.name,
    required this.time,
    required this.tag,
    required this.tagBg,
    required this.text,
    required this.reactionCounts,
    required this.userReactions,
    this.avatarUrl,
    this.username, // ✅
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final ColorScheme schema;
  final Function(String emoji) onReact;
  const _ActivityCard({
    required this.item,
    required this.schema,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void handleProfileTap() {
      final username = item.username;
      if (username != null && username.isNotEmpty) {
        context.push('/profile/$username');
      }
    }

    return GestureDetector(
      // onTap: () {
      //   showDialog(
      //     context: context,
      //     builder: (_) => const ActivityAndReactionsModal(),
      //   );
      // },
      child: Container(
        decoration: BoxDecoration(
          color: schema.surface,
          borderRadius: BorderRadius.circular(16),
          border: AppBorders.boxCard(schema),
          boxShadow: AppShadows.e1(schema),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: handleProfileTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: item.avatarUrl == null
                          ? LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [schema.primary, schema.secondary],
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              item.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            item.name.isNotEmpty
                                ? item.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: handleProfileTap,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: schema.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: schema.onSurface.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.tagBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.tag.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: schema.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final emoji in ['🔥', '💪', '👏', '💯']) ...[
                  _ReactionChip(
                    emoji: emoji,
                    active: item.userReactions.contains(emoji),
                    schema: schema,
                    isDark: isDark,
                    onTap: () => onReact(emoji),
                  ),
                  if (emoji != '💯') const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  item.reactionCounts.values
                      .fold(0, (a, b) => a + b)
                      .toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: schema.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final bool active;
  final ColorScheme schema;
  final bool isDark;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.emoji,
    required this.active,
    required this.schema,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48, // using circle (spec said 40x48 but “circle” => square)
        decoration: BoxDecoration(
          color: active
              ? const Color(0xCCEB4335) // EB4335 @ 80% opacity
              : (isDark ? AppColors.neutralDark : AppColors.neutralLight),
          shape: BoxShape.circle,
          border: AppBorders.boxCard(schema),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  final String text;
  final ColorScheme schema;
  const _HighlightBanner({required this.text, required this.schema});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/community/mini-challenge'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [schema.primary, schema.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          border: AppBorders.boxCard(schema),
          boxShadow: AppShadows.e1(schema),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SuggestedFollowCard extends StatefulWidget {
  final ColorScheme schema;
  const _SuggestedFollowCard({required this.schema});

  @override
  State<_SuggestedFollowCard> createState() => _SuggestedFollowCardState();
}

class _SuggestedFollowCardState extends State<_SuggestedFollowCard> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ActivityService().getSuggestedUsers();

      setState(() {
        users = res.map<Map<String, dynamic>>((u) {
          return {...u, 'isFollowing': false, 'isUpdating': false};
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    final user = users[index];

    if (user['isUpdating'] == true) return;

    setState(() {
      users[index]['isUpdating'] = true;
    });

    try {
      final res = await ActivityService().toggleFollow(user['id']);
      final isFollowing = res['following'] as bool;

      setState(() {
        users[index]['isFollowing'] = isFollowing;
      });
    } finally {
      setState(() {
        users[index]['isUpdating'] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = widget.schema;

    final displayUsers = users.length > 6 ? users.sublist(0, 6) : users;

    return Container(
      decoration: BoxDecoration(
        color: schema.surface,
        borderRadius: BorderRadius.circular(20),
        border: AppBorders.boxCard(schema),
        boxShadow: AppShadows.e1(schema),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested for you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: schema.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (displayUsers.isEmpty)
            Center(
              child: Text(
                'No suggestions yet',
                style: TextStyle(color: schema.onSurface.withOpacity(0.6)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayUsers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // 👈 reduced height
              ),
              itemBuilder: (context, index) {
                final u = displayUsers[index];
                final name = (u['name'] ?? 'User').toString();

                return _UserCard(
                  user: u,
                  name: name,
                  schema: schema,
                  onFollow: () => _toggleFollow(index),
                );
              },
            ),

          // Optional "See more"
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String name;
  final ColorScheme schema;
  final VoidCallback onFollow;

  const _UserCard({
    required this.user,
    required this.name,
    required this.schema,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final isFollowing = user['isFollowing'] == true;
    final isUpdating = user['isUpdating'] == true;
    final avatarUrl = user['avatarUrl'];

    return GestureDetector(
      onTap: () {
        final username = user['username'];
        if (username != null && username.isNotEmpty) {
          context.push('/profile/$username');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutralDark
              : AppColors.neutralLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: schema.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (avatarUrl == null || avatarUrl.isEmpty)
                    ? LinearGradient(colors: [schema.primary, schema.secondary])
                    : null,
              ),
              alignment: Alignment.center,
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
            ),
            const SizedBox(height: 6),

            // Name
            SizedBox(
              height: 40, // 👈 consistent space for 2 lines
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: schema.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Follow Button
            GestureDetector(
              onTap: isUpdating ? null : onFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? Colors.transparent
                      : schema.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: isFollowing
                      ? Border.all(color: schema.outline)
                      : null,
                ),
                child: isUpdating
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: schema.primary,
                        ),
                      )
                    : Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: schema.primary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:reptran_app/core/constants/tokens.dart';
// import 'package:reptran_app/features/community/presentation/pages/activity_and_reactions_modal.dart';
// import 'package:reptran_app/shared/widgets/app_scaffold.dart';
// import 'package:reptran_app/shared/widgets/tab_item.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:go_router/go_router.dart';

// class CommunityPage extends StatelessWidget {
//   const CommunityPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final schema = Theme.of(context).colorScheme;

//     // --- sample feed data (replace with real) ---
//     final activities = <_ActivityItem>[
//       _ActivityItem(
//         name: 'Alex',
//         time: '2h ago',
//         tag: 'BUILDER',
//         tagBg: AppColors.accent,
//         text: '✅  completed Push Day (45 min)',
//       ),
//       _ActivityItem(
//         name: 'Mia',
//         time: '3h ago',
//         tag: 'ATHLETE',
//         tagBg: schema.primary,
//         text: '🔥  reached a 7-day streak',
//       ),
//       _ActivityItem(
//         name: 'Sara',
//         time: '4h ago',
//         tag: 'WARRIOR',
//         tagBg: schema.secondary,
//         text: '👏  bounced back after missing yesterday',
//       ),
//       _ActivityItem(
//         name: 'John',
//         time: '6h ago',
//         tag: 'BUILDER',
//         tagBg: AppColors.accent,
//         text: '🏅  unlocked Bronze Badge',
//       ),
//       _ActivityItem(
//         name: 'Emma',
//         time: '8h ago',
//         tag: 'ATHLETE',
//         tagBg: schema.primary,
//         text: '✅  completed Morning Yoga (30 min)',
//       ),
//       _ActivityItem(
//         name: 'Luna',
//         time: '9h ago',
//         tag: 'MVP',
//         tagBg: AppColors.positive,
//         text: '💯  logged 30/30 days this month',
//       ),
//     ];

//     return AppScaffold(
//       current: TabItem.community,
//       body: SingleChildScrollView(
//         padding: EdgeInsets.zero,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // ======= HEADER SECTION =======
//             Container(
//               color: schema.surface,
//               padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
//               child: Column(
//                 children: [
//                   // Title + bell
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Community',
//                         style: Theme.of(context).textTheme.headlineSmall
//                             ?.copyWith(
//                               fontSize: 22,
//                               fontWeight: FontWeight.w700,
//                               height: 1.2,
//                               color: schema.onSurface,
//                             ),
//                       ),
//                       GestureDetector(
//                         onTap: () => context.push('/community/notifications'),
//                         child: Container(
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             color:
//                                 Theme.of(context).brightness == Brightness.dark
//                                 ? AppColors.neutralDark
//                                 : AppColors.neutralLight,
//                             borderRadius: BorderRadius.circular(8),
//                             border: AppBorders.boxCard(schema),
//                           ),
//                           child: const Icon(
//                             PhosphorIconsRegular.bell,
//                             size: 22,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // 🌍 3,240 workouts logged today (gradient card)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topRight,
//                         end: Alignment.bottomLeft, // ~135°
//                         colors: [schema.primary, schema.secondary],
//                       ),
//                       borderRadius: BorderRadius.circular(16),
//                       border: AppBorders.boxCard(schema),
//                       boxShadow: AppShadows.e1(schema),
//                     ),
//                     child: const Text(
//                       '🌍  3,240 workouts logged today',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Community Goal card (transparent bg)
//                   GestureDetector(
//                     onTap: () => context.push('/community/community-pulse'),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: schema.surface,
//                         borderRadius: BorderRadius.circular(16),
//                         border: AppBorders.boxCard(schema),
//                         boxShadow: AppShadows.e1(schema),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   'Community Goal: 10,000 this week',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: schema.onSurface,
//                                   ),
//                                 ),
//                               ),
//                               Text(
//                                 '83% ✅',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: AppColors.positive,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: SizedBox(
//                               height: 8,
//                               child: Stack(
//                                 children: [
//                                   Container(color: schema.outline),
//                                   FractionallySizedBox(
//                                     widthFactor: 0.83,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           begin: Alignment.topRight,
//                                           end: Alignment.bottomLeft,
//                                           colors: [
//                                             schema.primary,
//                                             schema.secondary,
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Text(
//                                 '8,320 done',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: schema.primary,
//                                 ),
//                               ),
//                               const Spacer(),
//                               Text(
//                                 '1,680 to go',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w400,
//                                   color: schema.onSurface.withValues(
//                                     alpha: 0.60,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // ======= ACTIVITY FEED =======
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Activity',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: schema.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   ...List.generate(
//                     activities.length + (activities.length ~/ 2),
//                     (i) {
//                       final insertHighlight = (i + 1) % 3 == 0;
//                       final isLast =
//                           i == activities.length + (activities.length ~/ 2) - 1;

//                       if (insertHighlight) {
//                         return Padding(
//                           padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
//                           child: _HighlightBanner(
//                             text: '🎯  100k total workouts logged on RepTran!',
//                             schema: schema,
//                           ),
//                         );
//                       }
//                       final idx = i - (i ~/ 3);
//                       final item = activities[idx];
//                       return Padding(
//                         padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
//                         child: _ActivityCard(item: item, schema: schema),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             // ======= SUGGESTED TO FOLLOW (separate padding: 24,24,24,48) =======
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
//               child: _SuggestedFollowCard(schema: schema),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== REUSABLE MAJOR CARDS ==================

// class _ActivityItem {
//   final String name;
//   final String time;
//   final String tag;
//   final Color tagBg;
//   final String text;
//   _ActivityItem({
//     required this.name,
//     required this.time,
//     required this.tag,
//     required this.tagBg,
//     required this.text,
//   });
// }

// class _ActivityCard extends StatelessWidget {
//   final _ActivityItem item;
//   final ColorScheme schema;
//   const _ActivityCard({required this.item, required this.schema});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return GestureDetector(
//       onTap: () {
//         showDialog(
//           context: context,
//           builder: (_) => const ActivityAndReactionsModal(),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: schema.surface,
//           borderRadius: BorderRadius.circular(16),
//           border: AppBorders.boxCard(schema),
//           boxShadow: AppShadows.e1(schema),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topRight,
//                       end: Alignment.bottomLeft,
//                       colors: [schema.primary, schema.secondary],
//                     ),
//                     shape: BoxShape.circle,
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.name,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: schema.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         item.time,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: schema.onSurface.withValues(alpha: 0.60),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: item.tagBg,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Text(
//                     item.tag.toUpperCase(),
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 item.text,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: schema.onSurface,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 for (int i = 0; i < 4; i++) ...[
//                   _ReactionChip(
//                     emoji: const ['🔥', '💪', '👏', '💯'][i],
//                     active: i == 0,
//                     schema: schema,
//                     isDark: isDark,
//                   ),
//                   if (i != 3) const SizedBox(width: 8),
//                 ],
//                 const Spacer(),
//                 Text(
//                   '35',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: schema.onSurface.withValues(alpha: 0.60),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ReactionChip extends StatelessWidget {
//   final String emoji;
//   final bool active;
//   final ColorScheme schema;
//   final bool isDark;

//   const _ReactionChip({
//     required this.emoji,
//     required this.active,
//     required this.schema,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 48,
//       height: 48, // using circle (spec said 40x48 but “circle” => square)
//       decoration: BoxDecoration(
//         color: active
//             ? const Color(0xCCEB4335) // EB4335 @ 80% opacity
//             : (isDark ? AppColors.neutralDark : AppColors.neutralLight),
//         shape: BoxShape.circle,
//         border: AppBorders.boxCard(schema),
//       ),
//       alignment: Alignment.center,
//       child: Text(emoji, style: const TextStyle(fontSize: 22)),
//     );
//   }
// }

// class _HighlightBanner extends StatelessWidget {
//   final String text;
//   final ColorScheme schema;
//   const _HighlightBanner({required this.text, required this.schema});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => context.push('/community/mini-challenge'),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topRight,
//             end: Alignment.bottomLeft,
//             colors: [schema.primary, schema.secondary],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: AppBorders.boxCard(schema),
//           boxShadow: AppShadows.e1(schema),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SuggestedFollowCard extends StatelessWidget {
//   final ColorScheme schema;
//   const _SuggestedFollowCard({required this.schema});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final people = const [
//       ('Ryan', 'Follow'),
//       ('Alan', 'Follow'),
//       ('David', 'Follow'),
//       ('Ria', 'Follow'),
//     ];

//     return GestureDetector(
//       onTap: () => context.push('/community/suggested-users'),
//       child: Container(
//         decoration: BoxDecoration(
//           color: schema.surface,
//           borderRadius: BorderRadius.circular(16),
//           border: AppBorders.boxCard(schema),
//           boxShadow: AppShadows.e1(schema),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Suggested to Follow',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: schema.onSurface,
//               ),
//             ),
//             const SizedBox(height: 16),

//             Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 16,
//               runSpacing: 16,
//               children: people.map((p) {
//                 final name = p.$1;
//                 return GestureDetector(
//                   onTap: () {
//                     context.push('/profile/public-profile');
//                   },
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topRight,
//                             end: Alignment.bottomLeft,
//                             colors: [schema.primary, schema.secondary],
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           name[0].toUpperCase(),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         name,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: schema.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: schema.primary,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: const Text(
//                           'Follow',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
