import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart'; 
import 'package:reptran_app/features/workout/services/user_workout_service.dart';



class WorkoutHistoryDetailsPage extends StatefulWidget {
  final String sessionId;

  const WorkoutHistoryDetailsPage({
    super.key,
    required this.sessionId,
  });

  @override
  State<WorkoutHistoryDetailsPage> createState() =>
      _WorkoutHistoryDetailsPageState();
}

class _WorkoutHistoryDetailsPageState extends State<WorkoutHistoryDetailsPage> {
  final _service = UserWorkoutService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _service.getSessionHistoryDetails(widget.sessionId);
      setState(() => _data = res);
    } catch (e) {
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest, // ✅ match history
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _data!;
    final exercises = session['exercises'] as List? ?? [];

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest, // ✅ match history
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: true,
        title: Text(
          session['title']?.toUpperCase() ?? 'WORKOUT',
          style: const TextStyle(
            fontWeight: FontWeight.w800, // 🔧 toned down
            letterSpacing: 1,
            fontSize: 15,
          ),
        ),
      
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BentoSummary(session: session),

            const SizedBox(height: 28),

            _SectionHeader(
              title: "Performance", 
              icon: PhosphorIcons.chartLineUp(),
            ),

            const SizedBox(height: 12),

            ...exercises.map((ex) => _ModernExerciseCard(exercise: ex)),

            if (session['reflection'] != null) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                title: "Athlete Notes", 
                icon: PhosphorIcons.quotes(),
              ),
              const SizedBox(height: 12),
              _PremiumReflection(reflection: session['reflection']),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
// ─── BENTO SUMMARY ───────────────────────────────────────────────────────────

class _BentoSummary extends StatelessWidget {
  final Map session;
  const _BentoSummary({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(context, "Duration", "${session['durationMin'] ?? 0}", "MIN"),
              _verticalDivider(context),
              _stat(context, "Volume", "${session['totalReps'] ?? 0}", "REPS"),
              _verticalDivider(context),
              _stat(context, "Intensity", "${session['totalSets'] ?? 0}", "SETS"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(BuildContext context) => Container(
    height: 40, 
    width: 1, 
    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
  );

  Widget _stat(BuildContext context, String label, String value, String unit) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        Text(label, style: TextStyle(color: onPrimary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(color: onPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
              TextSpan(text: " $unit", style: TextStyle(color: onPrimary.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── MODERN EXERCISE CARD ─────────────────────────────────────────────────────

class _ModernExerciseCard extends StatelessWidget {
  final Map exercise;
  const _ModernExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sets = exercise['sets'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow ?? cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: exercise['mediaUrl'] != null 
                  ? DecorationImage(image: NetworkImage(exercise['mediaUrl']), fit: BoxFit.cover)
                  : null,
                color: cs.secondaryContainer,
              ),
              child: exercise['mediaUrl'] == null ? Icon(PhosphorIcons.barbell(), color: cs.onSecondaryContainer) : null,
            ),
            title: Text(
              exercise['name'] ?? 'Exercise',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            subtitle: Text("${sets.length} Sets Completed", style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sets.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: cs.outlineVariant.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final set = sets[index];
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text("${index + 1}", style: TextStyle(color: cs.outline, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _setMetric(context, "WEIGHT", "${set['weightKg'] ?? '-'} KG"),
                        ),
                        Expanded(
                          child: _setMetric(context, "REPS", "${set['reps'] ?? '-'}"),
                        ),
                        Icon(PhosphorIcons.checkCircle(), color: Colors.green, size: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setMetric(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.outline, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── REFLECTION ──────────────────────────────────────────────────────────────

class _PremiumReflection extends StatelessWidget {
  final Map reflection;
  const _PremiumReflection({required this.reflection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.secondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reflection['challengeRating'] != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Intensity Rating", style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold)),
                Text("${reflection['challengeRating']}/10", style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (reflection['challengeRating'] as int) / 10,
              backgroundColor: cs.surface,
              color: cs.secondary,
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            reflection['note'] ?? "No notes provided.",
            style: TextStyle(color: cs.onSurface, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ─── UTILS ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        ),
      ],
    );
  }
}

