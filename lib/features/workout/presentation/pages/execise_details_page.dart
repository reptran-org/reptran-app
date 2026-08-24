import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/exercise_service.dart';

// ─── COLOR CONSTANTS ──────────────────────────────────────────────────────────

class AppColors {
  static const primary = Color(0xFF0F6F6E);
  static const primaryDark = Color(0xFF0A5655);
  static const secondary = Color(0xFF38BFB2);
  static const accent = Color(0xFFFF6B5A);
  static const accentDark = Color(0xFFE55A4A);
  static const positive = Color(0xFF4CD964);

  static const neutralDark = Color(0xFF1E1E1E);
  static const neutralLight = Color(0xFFF8F9FA);

  static const whiteUtility = Color(0xFFFFFFFF);
  static const whiteBorder = Color(0xFFE9ECEF);
  static const blackUtility = Color(0xFF2A2A2A);
  static const blackBorder = Color(0xFF404040);
}

// ─── THEME HELPERS ────────────────────────────────────────────────────────────

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => isDark ? AppColors.neutralDark : AppColors.whiteUtility;
  Color get surfaceElevated => isDark ? const Color(0xFF2A2A2A) : AppColors.neutralLight;
  Color get surfaceHighest => isDark ? const Color(0xFF333333) : AppColors.whiteBorder;
  Color get borderColor => isDark ? AppColors.blackBorder : AppColors.whiteBorder;
  Color get textPrimary => isDark ? AppColors.whiteUtility : AppColors.blackUtility;
  Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280);
  Color get textTertiary => isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9CA3AF);
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class ExerciseDetailsPage extends StatefulWidget {
  final String exerciseId;
  const ExerciseDetailsPage({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailsPage> createState() => _ExerciseDetailsPageState();
}

class _ExerciseDetailsPageState extends State<ExerciseDetailsPage>
    with SingleTickerProviderStateMixin {
  final _service = ExerciseService();
  Map<String, dynamic>? data;
  bool loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _service.getExerciseDetails(widget.exerciseId);
      if (mounted) {
        setState(() {
          data = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: context.surface,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (data == null) {
      return Scaffold(
        backgroundColor: context.surface,
        body: Center(
          child: Text('Failed to load exercise.',
              style: TextStyle(color: context.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(data: data!),
            _InstructionsTab(data: data!),
            _LogsTab(
              history: data!['history'] as List? ?? [],
              trackingType: data!['trackingType'] ?? 'REPS_WEIGHT',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: context.surface,
      surfaceTintColor: Colors.transparent,
      leading: _BackButton(),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        collapseMode: CollapseMode.parallax,
        background: _HeroImage(
          mediaUrl: data!['mediaUrl'] as String?,
          category: data!['category'] as String?,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: _ExerciseTabBar(controller: _tabController),
      ),
    );
  }
}

// ─── HERO IMAGE ───────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String? mediaUrl;
  final String? category;
  const _HeroImage({this.mediaUrl, this.category});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (mediaUrl != null)
          Image.network(mediaUrl!, fit: BoxFit.cover)
        else
          Container(
            color: context.isDark
                ? const Color(0xFF1A2A2A)
                : const Color(0xFFE0F2F1),
            child: Center(
              child: Icon(
                PhosphorIcons.barbell(),
                size: 64,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),
        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.transparent,
                context.surface,
              ],
            ),
          ),
        ),
        // Category badge at bottom
        if (category != null)
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.whiteUtility,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── BACK BUTTON ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── TAB BAR ─────────────────────────────────────────────────────────────────

class _ExerciseTabBar extends StatelessWidget {
  final TabController controller;
  const _ExerciseTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surface,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelColor: AppColors.primary,
        unselectedLabelColor: context.textTertiary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'INSTRUCTIONS'),
          Tab(text: 'LOGS'),
        ],
      ),
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final history = data['history'] as List? ?? [];
    final personalBests = _computePersonalBests(history, data['trackingType'] ?? 'REPS_WEIGHT');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name + description
          Text(
            (data['name'] as String? ?? '').toUpperCase(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (data['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              data['description'],
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.6,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Personal bests grid
          if (personalBests.isNotEmpty) ...[
            _SectionLabel(icon: PhosphorIcons.trophy(), label: 'Personal bests'),
            const SizedBox(height: 12),
            _StatsGrid(stats: personalBests),
            const SizedBox(height: 28),
          ],

          // Muscles
          if ((data['muscles'] as List?)?.isNotEmpty == true) ...[
            _SectionLabel(icon: PhosphorIcons.target(), label: 'Target muscles'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (data['muscles'] as List)
                  .map((m) => _Chip(label: m.toString(), isPrimary: true))
                  .toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Equipment
          if ((data['equipment'] as List?)?.isNotEmpty == true) ...[
            _SectionLabel(icon: PhosphorIcons.wrench(), label: 'Equipment'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (data['equipment'] as List)
                  .map((e) => _Chip(label: e.toString(), isPrimary: false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<_StatItem> _computePersonalBests(List history, String trackingType) {
    if (history.isEmpty) return [];

    double? maxWeight;
    int? maxReps;
    int? maxDuration;
    int totalSessions = history.length;

    for (final session in history) {
      final sets = session['sets'] as List? ?? [];
      for (final s in sets) {
        final w = (s['weightKg'] as num?)?.toDouble();
        final r = s['reps'] as int?;
        final d = s['durationSec'] as int?;
        if (w != null && (maxWeight == null || w > maxWeight!)) maxWeight = w;
        if (r != null && (maxReps == null || r > maxReps!)) maxReps = r;
        if (d != null && (maxDuration == null || d > maxDuration!)) maxDuration = d;
      }
    }

    final stats = <_StatItem>[];

    switch (trackingType) {
      case 'REPS_WEIGHT':
        if (maxWeight != null) stats.add(_StatItem('Best weight', '${maxWeight!.toStringAsFixed(maxWeight! % 1 == 0 ? 0 : 1)} kg'));
        if (maxReps != null) stats.add(_StatItem('Best reps', '$maxReps'));
        break;
      case 'REPS':
        if (maxReps != null) stats.add(_StatItem('Best reps', '$maxReps'));
        break;
      case 'TIME':
      case 'TIME_WEIGHT':
        if (maxDuration != null) stats.add(_StatItem('Best time', '${maxDuration}s'));
        if (trackingType == 'TIME_WEIGHT' && maxWeight != null) {
          stats.add(_StatItem('Best weight', '${maxWeight!.toStringAsFixed(maxWeight! % 1 == 0 ? 0 : 1)} kg'));
        }
        break;
    }

    stats.add(_StatItem('Sessions', '$totalSessions'));
    return stats;
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, i) {
        final s = stats[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── INSTRUCTIONS TAB ────────────────────────────────────────────────────────

class _InstructionsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InstructionsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawTips = data['tips'] as String? ?? '';
    final steps = rawTips.isNotEmpty
        ? rawTips.split('\n').where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: PhosphorIcons.listNumbers(), label: 'Step-by-step'),
          const SizedBox(height: 16),

          if (steps.isEmpty)
            _EmptyState(
              icon: PhosphorIcons.noteBlank(),
              message: 'No instructions provided for this exercise.',
            )
          else
            ...steps.asMap().entries.map((e) => _StepRow(
                  index: e.key,
                  text: e.value.trim(),
                  isLast: e.key == steps.length - 1,
                )),

          if (data['tips'] != null && steps.length == 1) ...[
            const SizedBox(height: 28),
            _SectionLabel(icon: PhosphorIcons.lightbulb(), label: 'Expert tip'),
            const SizedBox(height: 12),
            _TipCard(text: rawTips),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final bool isLast;
  const _StepRow({required this.index, required this.text, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: context.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: context.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(context.isDark ? 0.08 : 0.07),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          left: BorderSide(color: AppColors.secondary, width: 3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.65,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

// ─── LOGS TAB ────────────────────────────────────────────────────────────────

class _LogsTab extends StatelessWidget {
  final List history;
  final String trackingType;
  const _LogsTab({required this.history, required this.trackingType});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyState(
        icon: PhosphorIcons.clockCounterClockwise(),
        message: 'No workout history yet.\nComplete a session to see your logs.',
        centered: true,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final item = history[i] as Map;
        final sets = item['sets'] as List? ?? [];
        final rawDate = item['session']?['completedAt'] as String?;
        final date = rawDate != null ? DateTime.tryParse(rawDate)?.toLocal() : null;

        return _SessionCard(
          date: date,
          sets: sets,
          trackingType: trackingType,
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final DateTime? date;
  final List sets;
  final String trackingType;
  const _SessionCard({required this.date, required this.sets, required this.trackingType});

  String _formatDate(DateTime? d) {
    if (d == null) return 'Unknown date';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(PhosphorIcons.calendar(), size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sets.length} set${sets.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 0.5, color: context.borderColor),

          // Sets
          ...sets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value as Map;
            final isLast = i == sets.length - 1;
            return _SetRow(
              index: i,
              setData: s,
              trackingType: trackingType,
              isLast: isLast,
            );
          }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final Map setData;
  final String trackingType;
  final bool isLast;
  const _SetRow({
    required this.index,
    required this.setData,
    required this.trackingType,
    required this.isLast,
  });

  String _formatMain(Map s, String type) {
    final reps = s['reps'];
    final weight = s['weightKg'];
    final duration = s['durationSec'];

    switch (type) {
      case 'REPS_WEIGHT':
        return '${weight ?? '-'} kg  ×  ${reps ?? '-'} reps';
      case 'REPS':
        return '${reps ?? '-'} reps';
      case 'TIME':
        return '${duration ?? '-'} sec';
      case 'TIME_WEIGHT':
        return '${weight ?? '-'} kg  ×  ${duration ?? '-'} sec';
      default:
        return '-';
    }
  }

  String? _formatSub(Map s, String type) {
    if (s['note'] != null && (s['note'] as String).isNotEmpty) {
      return s['note'] as String;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mainText = _formatMain(setData, trackingType);
    final subText = _formatSub(setData, trackingType);
    final isCompleted = setData['completed'] != false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Set number badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: context.surfaceHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Set data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    if (subText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subText,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Completed indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.positive.withOpacity(0.12)
                      : AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                  size: 14,
                  color: isCompleted ? AppColors.positive : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: context.borderColor,
            indent: 56,
          ),
      ],
    );
  }
}

// ─── SHARED COMPONENTS ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _Chip({required this.label, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? AppColors.primary.withOpacity(context.isDark ? 0.15 : 0.08)
        : AppColors.secondary.withOpacity(context.isDark ? 0.15 : 0.08);
    final fg = isPrimary ? AppColors.primary : AppColors.primaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isPrimary ? AppColors.primary : AppColors.secondary).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool centered;
  const _EmptyState({required this.icon, required this.message, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: context.textTertiary),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: context.textSecondary,
          ),
        ),
      ],
    );

    if (centered) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: content));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: content),
    );
  }
}