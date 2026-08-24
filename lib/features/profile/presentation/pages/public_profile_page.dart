// PublicProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';
import 'package:reptran_app/features/profile/services/profile_service.dart';

class PublicProfilePage extends StatefulWidget {
  final String username;

  const PublicProfilePage({super.key, required this.username});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isFollowLoading = false;

  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isError = false;

  static const _kAuthTokenKey = 'auth_token';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _attachToken() async {
    final token = await _storage.read(key: _kAuthTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> _fetchProfile() async {
    try {
      await _attachToken();

      final res = await _dio.get('/user/${widget.username}');
      final data = res.data as Map<String, dynamic>;

      setState(() {
        profile = data['result'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (profile == null || isFollowLoading) return;

    final userId = profile!['user']?['id'];
    if (userId == null) return;

    final current = profile!['isFollowing'] ?? false;

    // 🔥 Start loading + optimistic UI
    setState(() {
      isFollowLoading = true;
      profile = {...profile!, 'isFollowing': !current};
    });

    try {
      final result = await ActivityService().toggleFollow(userId);

      setState(() {
        profile = {...profile!, 'isFollowing': result['following']};
      });
    } catch (e) {
      // ❌ revert if failed
      setState(() {
        profile = {...profile!, 'isFollowing': current};
      });
    } finally {
      setState(() {
        isFollowLoading = false;
      });
    }
  }

  String _safeString(dynamic val, {String fallback = ''}) {
    if (val == null) return fallback;
    return val.toString();
  }

  String _initials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    return parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
  }

  Widget _buildInitialsFallback(
    String name,
    ColorScheme scheme,
    TextTheme text,
  ) {
    return Container(
      color: scheme.surface,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: text.headlineLarge!.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _blockUser(String userId) async {
    try {
      await _attachToken();

      await _dio.post('/block', data: {'blockedUserId': userId});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User blocked')));

        Navigator.pop(context); // go back after block
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to block user')));
    }
  }

  Future<void> _handleReport(String userId, String reason) async {
    try {
      await ProfileService().reportUser(targetUserId: userId, reason: reason);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to report')));
    }
  }

  void _showReportSheet(String userId) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // allows rounded corners
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔹 Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              /// 🔹 Title
              Text(
                'Report User',
                style: text.titleMedium!.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              /// 🔹 Options
              _buildReportTile(
                context,
                label: 'Spam',
                onTap: () {
                  Navigator.pop(context);
                  _handleReport(userId, 'spam');
                },
              ),

              const SizedBox(height: 8),

              _buildReportTile(
                context,
                label: 'Abuse',
                onTap: () {
                  Navigator.pop(context);
                  _handleReport(userId, 'abuse');
                },
              ),

              const SizedBox(height: 8),

              _buildReportTile(
                context,
                label: 'Inappropriate',
                onTap: () {
                  Navigator.pop(context);
                  _handleReport(userId, 'inappropriate');
                },
              ),
            ],
          ),
        );
      },
    );
  }

Widget _buildReportTile(
  BuildContext context, {
  required String label,
  required VoidCallback onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),

          // 🔹 subtle background
          color: scheme.surfaceVariant.withOpacity(0.25),

          // 🔥 border added here
          border: Border.all(
            color: scheme.outline.withOpacity(0.2), // very subtle
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: text.bodyMedium,
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isError || profile == null) {
      return Scaffold(body: Center(child: Text('Failed to load profile')));
    }

    final user = profile!['user'] ?? {};
    final identity = profile!['identity'] ?? {};
    final stats = profile!['stats'] ?? {};
    final activities = profile!['recentActivity'] ?? [];

    final name = _safeString(user['name'], fallback: 'User');
    final username = _safeString(user['username']);
    final avatarUrl = _safeString(user['avatarUrl']);
    final statement = _safeString(
      identity['statement'],
      fallback: 'No identity statement yet',
    );
    final archetype = _safeString(identity['archetype'], fallback: 'User');

    final streak = _safeString(stats['streakDays'], fallback: '0');
    final total = _safeString(stats['totalSessions'], fallback: '0');
    final badges = _safeString(stats['badgesEarned'], fallback: '0');
    final isBlocked = profile!['isBlocked'] ?? false;

    final isFollowing = profile!['isFollowing'] ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// ================= HERO =================
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [scheme.primary, scheme.secondary],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 4,
                                  color: AppColors.whiteUtility.withValues(
                                    alpha: AppOpacities.disabled,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: ClipOval(
                                child: avatarUrl.isNotEmpty
                                    ? Image.network(
                                        avatarUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return _buildInitialsFallback(
                                                name,
                                                scheme,
                                                text,
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: scheme.primary,
                                                      ),
                                                ),
                                              );
                                            },
                                      )
                                    : _buildInitialsFallback(
                                        name,
                                        scheme,
                                        text,
                                      ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            Text(
                              name,
                              style: text.bodyMedium!.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: AppTypography.wBold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            Text(
                              '@$username',
                              style: text.bodySmall!.copyWith(
                                color: scheme.onPrimary.withValues(
                                  alpha: AppOpacities.secondary,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.whiteUtility.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                border: Border.all(
                                  color: AppColors.whiteUtility.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Text(
                                statement,
                                style: text.bodySmall!.copyWith(
                                  color: AppColors.whiteUtility,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.whiteUtility.withValues(
                                  alpha: 0.30,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                                border: Border.all(
                                  color: AppColors.whiteUtility.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                '🏷️  $archetype',
                                style: text.bodySmall!.copyWith(
                                  color: AppColors.whiteUtility,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      /// ================= BODY =================
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                border: AppBorders.boxCard(scheme),
                                boxShadow: AppShadows.e1(scheme),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatColumn(
                                          iconColor: scheme.tertiary,
                                          icon: PhosphorIconsRegular.flame,
                                          label: 'STREAK\nDAYS',
                                          value: streak,
                                        ),
                                      ),
                                      Expanded(
                                        child: _StatColumn(
                                          iconColor: scheme.secondary,
                                          icon: PhosphorIconsRegular.barbell,
                                          label: 'TOTAL\nWORKOUTS',
                                          value: total,
                                        ),
                                      ),
                                      Expanded(
                                        child: _StatColumn(
                                          iconColor: scheme.primary,
                                          icon: PhosphorIconsRegular.medal,
                                          label: 'BADGES\nEARNED',
                                          value: badges,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Divider(),
                                  const SizedBox(height: AppSpacing.sm),
                                  _PrimaryButton(
                                    label: isFollowLoading
                                        ? 'Loading...'
                                        : isFollowing
                                        ? 'Following'
                                        : 'Follow',
                                    icon: isFollowing
                                        ? PhosphorIconsRegular.check
                                        : PhosphorIconsRegular.userPlus,
                                    onPressed: isFollowLoading
                                        ? () {}
                                        : _toggleFollow,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            Text('Recent Activity', style: text.titleMedium),
                            const SizedBox(height: AppSpacing.sm),

                            Container(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                border: AppBorders.boxCard(scheme),
                                boxShadow: AppShadows.e1(scheme),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: activities.isEmpty
                                  ? _EmptyActivityState()
                                  : Column(
                                      children: activities.map<Widget>((a) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.xs,
                                          ),
                                          child: _ActivityItem(
                                            icon:
                                                PhosphorIconsRegular.lightning,
                                            iconTintKey: _Tint.secondary,
                                            title: _safeString(
                                              a['type'],
                                              fallback: 'Activity',
                                            ),
                                            meta: '',
                                            time: _formatTimeAgo(
                                              a['createdAt'],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        PhosphorIconsRegular.dotsThreeVertical,
                        color: scheme.onPrimary,
                      ),
                    onSelected: (value) async {
  final userId = user['id'];

  if (value == 'block') {
    try {
      await ProfileService().blockUser(blockedUserId: userId);

      setState(() {
        profile = {...profile!, 'isBlocked': true};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User blocked')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to block user')),
      );
    }
  } else if (value == 'unblock') {
    try {
      await ProfileService().unblockUser(blockedUserId: userId);

      setState(() {
        profile = {...profile!, 'isBlocked': false};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unblock user')),
      );
    }
  } else if (value == 'report') {
    _showReportSheet(userId);
  }
},
                    itemBuilder: (context) {
  final isBlocked = profile!['isBlocked'] ?? false;

  return [
    const PopupMenuItem(
      value: 'report',
      child: Text('Report User'),
    ),
    PopupMenuItem(
      value: isBlocked ? 'unblock' : 'block',
      child: Text(isBlocked ? 'Unblock User' : 'Block User'),
    ),
  ];
},
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

/// =====================
/// Helpers / Widgets
/// =====================

class _StatColumn extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;

  const _StatColumn({
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        // Soft circular icon background
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10), // <<< 10% for background
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: iconColor, // <<< Full-strength icon
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(label, textAlign: TextAlign.center, style: text.bodySmall),
      ],
    );
  }
}

enum _Tint { secondary, tertiary }

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final _Tint iconTintKey;
  final String title;
  final String meta;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconTintKey,
    required this.title,
    required this.meta,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Base icon color (full strength)
    final Color iconColor = switch (iconTintKey) {
      _Tint.secondary => scheme.secondary,
      _Tint.tertiary => scheme.tertiary,
    };

    // Background = icon color @ 10% opacity
    final Color iconBg = iconColor.withOpacity(0.10);

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon chip
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: iconColor, // <<< Full color icon
            ),
          ),

          const SizedBox(width: AppSpacing.sm),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + meta
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.bodyMedium,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        meta,
                        style: text.bodySmall!.copyWith(
                          color: scheme.onSurface.withValues(
                            alpha: AppOpacities.secondary,
                          ),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.clock,
                      size: 18,
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        time,
                        style: text.bodySmall,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
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
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 24, color: scheme.onSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          label.toUpperCase(),
                          style: text.titleMedium!.copyWith(
                            color: scheme.onSecondary,
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

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity, // ✅ ensures full width
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // ✅ center content nicely
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              alignment: Alignment.center,
              child: Icon(
                PhosphorIconsRegular.clock,
                size: 24,
                color: scheme.primary.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              'No activity yet',
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle (public profile tone)
            Text(
              'This user is getting started. Activity will appear here.',
              style: text.bodySmall!.copyWith(
                color: scheme.onSurface.withValues(
                  alpha: AppOpacities.secondary,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimeAgo(String? isoTime) {
  if (isoTime == null || isoTime.isEmpty) return '';

  final dateTime = DateTime.tryParse(isoTime)?.toLocal();
  if (dateTime == null) return '';

  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds} sec${diff.inSeconds == 1 ? '' : 's'} ago';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'} ago';
  } else {
    final years = (diff.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}
