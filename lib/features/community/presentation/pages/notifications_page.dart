import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/community/services/activity_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ActivityService _service = ActivityService();
  late PageController _pageController;

  List<dynamic> notifications = [];
  bool loading = true;

  String selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchNotifications();
  }

  // ================= FETCH =================

  Future<void> _fetchNotifications() async {
    try {
      final data = await _service.getNotifications();

   setState(() {
  notifications = data['notifications']; // ✅ fix
  loading = false;
});
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();

    setState(() {
      notifications = notifications.map((n) {
        n['readAt'] = DateTime.now().toIso8601String();
        return n;
      }).toList();
    });
  }

  Future<void> _markOneRead(dynamic n) async {
    if (n['readAt'] != null) return;

    await _service.markAsRead(n['id']);

    setState(() {
      n['readAt'] = DateTime.now().toIso8601String();
    });
  }

  // ================= FILTER =================

  List<dynamic> _filterByTab(String tab) {
    if (tab == 'all') return notifications;

    if (tab == 'system') {
      return notifications.where((n) {
        return n['type'] == 'trigger.workout_nudge';
      }).toList();
    }

    if (tab == 'community') {
      return notifications.where((n) {
        return n['type'] == 'social.follow' ||
            n['type'] == 'social.reaction';
      }).toList();
    }

    return notifications;
  }

  // ================= HELPERS =================

  IconData _getIcon(String type) {
    switch (type) {
      case 'social.reaction':
        return PhosphorIconsRegular.fire;
      case 'social.follow':
        return PhosphorIconsRegular.userPlus;
      case 'trigger.workout_nudge':
        return PhosphorIconsRegular.bellRinging;
      default:
        return PhosphorIconsRegular.bell;
    }
  }

  String _buildTitle(dynamic n) {
    final payload = n['payload'];

    switch (n['type']) {
      case 'social.reaction':
        return '${payload['actorName']} reacted ${payload['reaction']} to your activity';
      case 'social.follow':
        return '${payload['actorName']} started following you';
      case 'trigger.workout_nudge':
        return payload['body'] ?? 'Workout reminder';
      default:
        return 'New notification';
    }
  }

  String _formatTime(String iso) {
    final date = DateTime.parse(iso);
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildList(String tab) {
    final list = _filterByTab(tab);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        children: list.map((n) {
          return GestureDetector(
            onTap: () => _markOneRead(n),
            child: Column(
              children: [
                _NotificationItem(
                  icon: _getIcon(n['type']),
                  title: _buildTitle(n),
                  time: _formatTime(n['createdAt']),
                  isUnread: n['readAt'] == null,
                ),
                _DividerToken(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      boxShadow: AppShadows.e0,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xxl,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Notifications',
                                style: tt.headlineSmall,
                              ),
                            ),
                            GestureDetector(
                              onTap: _markAllRead,
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.bellSimple,
                                    size: 24,
                                    color: scheme.onSurface,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Mark All Read',
                                    style: tt.bodySmall?.copyWith(
                                      color: scheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Recent alerts and updates across your account.',
                          style: tt.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _TabsRow(
                          selected: selectedTab,
                          onChange: (val) {
                            final index =
                                ['all', 'system', 'community'].indexOf(val);

                            _pageController.animateToPage(
                              index,
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );

                            setState(() {
                              selectedTab = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height * 0.7,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            selectedTab = [
                              'all',
                              'system',
                              'community'
                            ][index];
                          });
                        },
                        children: [
                          _buildList('all'),
                          _buildList('system'),
                          _buildList('community'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= TABS =================

class _TabsRow extends StatelessWidget {
  const _TabsRow({
    required this.selected,
    required this.onChange,
  });

  final String selected;
  final Function(String) onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget tab(String label, String value) {
      final isSelected = selected == value;

      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(value),
          child: Column(
            children: [
              Text(
                label,
                style: (isSelected ? tt.bodyMedium : tt.bodySmall)
                    ?.copyWith(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                color: isSelected
                    ? scheme.primary
                    : scheme.onSurface.withValues(
                        alpha: AppOpacities.disabled,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('All', 'all'),
        const SizedBox(width: AppSpacing.lg),
        tab('System', 'system'),
        const SizedBox(width: AppSpacing.lg),
        tab('Community', 'community'),
      ],
    );
  }
}

// ================= EMPTY =================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            PhosphorIconsRegular.bellSlash,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: tt.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ================= ITEM =================

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.isUnread,
  });

  final IconData icon;
  final String title;
  final String time;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.tertiary.withValues(alpha: 0.10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: scheme.tertiary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  time,
                  style: tt.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ================= DIVIDER =================

class _DividerToken extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: scheme.outline,
    );
  }
}