// FollowersFollowingScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';


class FollowersFollowingPage extends StatefulWidget {
  const FollowersFollowingPage({super.key});

  @override
  State<FollowersFollowingPage> createState() =>
      _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> {
  String currentTab = 'followers';

  // 🔥 Separate states
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];

  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  bool isLoading = true;

  int followersCount = 0;
  int followingCount = 0;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // =====================
  // FETCH DATA
  // =====================
  Future<void> _fetchAll() async {
    setState(() => isLoading = true);

    final resFollowers =
        await ActivityService().getFollowersFollowing('followers');
    final resFollowing =
        await ActivityService().getFollowersFollowing('following');

    setState(() {
      followers = resFollowers.map((u) {
        return {...u, 'isFollowing': false, 'isUpdating': false};
      }).toList();

      following = resFollowing.map((u) {
        return {...u, 'isFollowing': true, 'isUpdating': false};
      }).toList();

      followersCount = followers.length;
      followingCount = following.length;

      isLoading = false;
    });
  }

  // =====================
  // SEARCH
  // =====================
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
      });
      return;
    }

    final res = await ActivityService().searchUsers(query);

    setState(() {
      isSearching = true;
      searchResults = res.map((u) {
        return {
          ...u,
          'isFollowing': u['isFollowing'] ?? false,
          'isUpdating': false,
        };
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value);
    });
  }

  // =====================
  // ACTIVE LIST
  // =====================
  List<Map<String, dynamic>> get _activeList {
    if (isSearching) return searchResults;
    return currentTab == 'followers' ? followers : following;
  }

  // =====================
  // TOGGLE FOLLOW
  // =====================
  Future<void> _toggleFollow(int index) async {
    final list = _activeList;

    if (list[index]['isUpdating'] == true) return;

    setState(() {
      list[index]['isUpdating'] = true;
    });

    final res =
        await ActivityService().toggleFollow(list[index]['id']);

    setState(() {
      list[index]['isFollowing'] = res['following'];
      list[index]['isUpdating'] = false;

      _syncUserFollowState(list[index]['id'], res['following']);
    });
  }

void _syncUserFollowState(String userId, bool isFollowingNow) {
  Map<String, dynamic>? updatedUser;

  // Find user from any source
  for (var u in searchResults) {
    if (u['id'] == userId) updatedUser = u;
  }
  for (var u in followers) {
    if (u['id'] == userId) updatedUser = u;
  }
  for (var u in following) {
    if (u['id'] == userId) updatedUser = u;
  }

  if (updatedUser == null) return;

  // Update flags everywhere
  for (var u in followers) {
    if (u['id'] == userId) u['isFollowing'] = isFollowingNow;
  }
  for (var u in following) {
    if (u['id'] == userId) u['isFollowing'] = isFollowingNow;
  }
  for (var u in searchResults) {
    if (u['id'] == userId) u['isFollowing'] = isFollowingNow;
  }

  // =====================
  // 🔥 MOVE BETWEEN LISTS
  // =====================

  if (isFollowingNow) {
    // Add to following if not exists
    final exists =
        following.any((u) => u['id'] == userId);

    if (!exists) {
      following.insert(0, {
        ...updatedUser,
        'isFollowing': true,
      });
      followingCount++;
    }
  } else {
    // Remove from following
    following.removeWhere((u) => u['id'] == userId);
    followingCount = following.length;
  }
}
  // =====================
  // TAB SWITCH
  // =====================
  void _switchTab(String tab) {
    setState(() {
      currentTab = tab;
      isSearching = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayList = _activeList;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: AppBorders.boxCard(scheme),
                      boxShadow: AppShadows.e1(scheme),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.usersThree,
                              size: 24,
                              color: scheme.onSurface,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Followers & Following',
                                style: textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // SEARCH
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search people...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // TABS (FIXED COUNTS)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _switchTab('followers'),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Followers ($followersCount)',
                                    style: textTheme.bodyMedium!
                                        .copyWith(
                                      color: currentTab == 'followers'
                                          ? scheme.primary
                                          : scheme.onSurface
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: AppSpacing.xs),
                                  if (currentTab == 'followers')
                                    Container(
                                      height: AppSpacing.xxs,
                                      width: 100,
                                      color: scheme.primary,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            GestureDetector(
                              onTap: () => _switchTab('following'),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Following ($followingCount)',
                                    style: textTheme.bodyMedium!
                                        .copyWith(
                                      color: currentTab == 'following'
                                          ? scheme.primary
                                          : scheme.onSurface
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: AppSpacing.xs),
                                  if (currentTab == 'following')
                                    Container(
                                      height: AppSpacing.xxs,
                                      width: 100,
                                      color: scheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (isSearching)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Search Results (${searchResults.length})',
                              style: textTheme.bodySmall!.copyWith(
                                color:
                                    scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // USER LIST
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator())
                        : Column(
                            children: [
                              for (int i = 0;
                                  i < displayList.length;
                                  i++) ...[
                                _UserCard(
                                  user: displayList[i],
                                  onToggleFollow: () =>
                                      _toggleFollow(i),
                                ),
                                if (i != displayList.length - 1)
                                  const SizedBox(
                                      height: AppSpacing.xs),
                              ],
                            ],
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

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleFollow;

  const _UserCard({
    required this.user,
    required this.onToggleFollow,
  });

@override
Widget build(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  final isLight = Theme.of(context).brightness == Brightness.light;

  final name = user['name'] ?? 'User';
  final avatarUrl = user['avatarUrl'];

  void handleProfileTap() {
    final username = user['username'];
    if (username != null && username.isNotEmpty) {
      context.push('/profile/$username');
    }
  }

  return Container(
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: AppBorders.boxCard(scheme),
      boxShadow: AppShadows.e1(scheme),
    ),
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      children: [
        // Avatar (CLICKABLE)
        GestureDetector(
          onTap: handleProfileTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                width: 2,
                color: isLight
                    ? AppColors.neutralLight
                    : AppColors.neutralDark,
              ),
            ),
            alignment: Alignment.center,
           child: ClipRRect(
  borderRadius: BorderRadius.circular(AppRadii.full),
  child: avatarUrl != null && avatarUrl.toString().isNotEmpty
      ? Image.network(
          avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _buildInitialsFallback(name, text, scheme);
          },
        )
      : _buildInitialsFallback(name, text, scheme),
),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Name (CLICKABLE)
        Expanded(
          child: GestureDetector(
            onTap: handleProfileTap,
            child: Text(
              name,
              style: text.bodyMedium,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Follow button (UNCHANGED)
        GestureDetector(
          onTap: onToggleFollow,
          child: user['isUpdating'] == true
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : user['isFollowing'] == true
                  ? _PillFilled(label: 'Following')
                  : _PillOutline(label: 'Follow'),
        ),
      ],
    ),
  );
}
}

class _PillFilled extends StatelessWidget {
  final String label;
  const _PillFilled({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.userCheck,
            size: 24,
            color: scheme.onSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style:
                text.bodySmall!.copyWith(color: scheme.onSecondary),
          ),
        ],
      ),
    );
  }
}

class _PillOutline extends StatelessWidget {
  final String label;
  const _PillOutline({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: scheme.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.userPlus,
            size: 24,
            color: scheme.secondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style:
                text.bodySmall!.copyWith(color: scheme.secondary),
          ),
        ],
      ),
    );
  }
}

Widget _buildInitialsFallback(
  String name,
  TextTheme text,
  ColorScheme scheme,
) {
  return Container(
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: text.titleMedium!.copyWith(color: scheme.onPrimary),
    ),
  );
}