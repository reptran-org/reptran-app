import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:reptran_app/features/notifications/services/local_notification_service.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';

enum WorkoutNotificationState { activeSet, recovery }

class ActiveWorkoutController extends ChangeNotifier {
  static ActiveWorkoutController? instance;

  bool _actionInProgress = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? _sessionMeta;

  ActiveWorkoutController() {
    _configurePlayerAudioContext();
  }

  Future<void> _configurePlayerAudioContext() async {
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (_) {}
  }

  // ✅ ADD THIS
  Map<String, dynamic>? get sessionMeta => _sessionMeta;
  void setSessionMeta(Map<String, dynamic> data) {
    _sessionMeta = data;
    notifyListeners(); // optional
  }

  final Map<String, Timer> _setTimers = {};
  final Map<String, int> _setElapsedSeconds = {};

  int getElapsedTime(String setId) {
    return _setElapsedSeconds[setId] ?? 0;
  }

  bool isTimerRunning(String setId) {
    return _setTimers.containsKey(setId);
  }

  List<Map<String, dynamic>> _supersets = [];
  List<Map<String, dynamic>> _exercises = [];

  List<_ExecutionStep> _executionQueue = [];

  String? _sessionId;
  DateTime? _startedAt;
  String? _workoutName;

  bool _restWasSkipped = false;

  Timer? _recoveryLoop;

  DateTime? _restEndTime;
  int _restTotal = 0;

  WorkoutNotificationState _notificationState =
      WorkoutNotificationState.activeSet;

  List<Map<String, dynamic>> get exercises => _exercises;
  String? get sessionId => _sessionId;
  DateTime? get startedAt => _startedAt;
  bool get isActive => _sessionId != null;

  bool get isResting => restRemaining > 0;

  int get restRemaining {
    if (_restEndTime == null) return 0;
    final diff = _restEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  int get restTotal => _restTotal;

  void startSetTimer({required String setId, int? initialDuration}) {
    if (_setTimers.containsKey(setId)) return;

    _setElapsedSeconds[setId] ??= initialDuration ?? getBackendDuration(setId);

    _setTimers[setId] = Timer.periodic(const Duration(seconds: 1), (_) {
      _setElapsedSeconds[setId] = (_setElapsedSeconds[setId] ?? 0) + 1;
      notifyListeners();
    });
  }

  int getBackendDuration(String setId) {
    for (final ex in _exercises) {
      final sets = (ex["sets"] ?? []) as List;

      for (final s in sets) {
        if (s["id"].toString() == setId) {
          return s["durationSec"] ?? 0;
        }
      }
    }

    return 0;
  }

  Future<void> stopSetTimer({
    required String sessionExerciseId,
    required String setId,
  }) async {
    final timer = _setTimers.remove(setId);
    timer?.cancel();

    final duration = _setElapsedSeconds[setId] ?? 0;

    try {
      await SessionService().updateSet(
        sessionId: _sessionId!,
        sessionExerciseId: sessionExerciseId,
        setId: setId,
        durationSec: duration, // ✅ SAVED HERE
      );

      await refreshFromBackend();
    } catch (e) {}
  }

  Future<void> toggleSetTimer({
    required String sessionExerciseId,
    required String setId,
    int initialDuration = 0,
  }) async {
    if (isTimerRunning(setId)) {
      await stopSetTimer(sessionExerciseId: sessionExerciseId, setId: setId);
    } else {
      startSetTimer(setId: setId, initialDuration: initialDuration);
    }
  }

  /// -------------------------
  /// START WORKOUT
  /// -------------------------
  void start({
    required String sessionId,
    required DateTime startedAt,
    required String workoutName,
    required List<Map<String, dynamic>> exercises,
  }) {
    instance = this;

    _sessionId = sessionId;
    _startedAt = startedAt;
    _workoutName = workoutName;

    _exercises = exercises;

    _buildExecutionQueue();

    notifyListeners();

    updateNotificationActiveSet();
  }

  /// -------------------------
  /// REORDER EXERCISES
  /// -------------------------
  Future<void> reorderExercises(List<String> orderedExerciseIds) async {
    if (_sessionId == null) return;

    try {
      _recoveryLoop?.cancel();

      await SessionService().reorderExercises(
        sessionId: _sessionId!,
        exerciseIds: orderedExerciseIds,
      );

      final map = {for (final e in _exercises) e["id"].toString(): e};

      final reordered = <Map<String, dynamic>>[];

      for (int i = 0; i < orderedExerciseIds.length; i++) {
        final ex = map[orderedExerciseIds[i]];
        if (ex != null) {
          ex["orderIndex"] = (i + 1) * 1000;
          reordered.add(ex);
        }
      }

      _exercises = reordered;

      _buildExecutionQueue();

      notifyListeners();

      updateNotificationActiveSet();
    } catch (e) {}
  }

  /// -------------------------
  /// REFRESH FROM BACKEND
  /// -------------------------
  Future<void> refreshFromBackend() async {
    if (_sessionId == null) return;

    try {
      final res = await SessionService().getSession(_sessionId!);

      _sessionMeta = res;

      // 🔥 FULL RESPONSE LOG

      final startedAtStr = res["startedAt"]?.toString();
      if (startedAtStr != null) {
        _startedAt = DateTime.parse(startedAtStr).toLocal();
      }

      final exercises = (res["exercises"] ?? []) as List;

      // 🔥 DETAILED LOGGING
      for (final ex in exercises) {
        final map = ex as Map<String, dynamic>;

        final sets = (map["sets"] ?? []) as List;

        for (final s in sets) {
          final prev = s["previous"];
          if (prev != null) {
          } else {}
        }
      }

      // 🔧 Your existing normalization
      for (final ex in exercises) {
        final map = ex as Map<String, dynamic>;

        map["notes"] ??= "";

        if (map["restSeconds"] is! int || map["restSeconds"] < 5) {
          map["restSeconds"] = null;
        } else {
          map["restSeconds"] = (map["restSeconds"] as int).clamp(5, 300);
        }
      }

      _exercises = exercises.cast<Map<String, dynamic>>();
      _supersets = (res["supersets"] ?? []).cast<Map<String, dynamic>>();

      _buildExecutionQueue();

      notifyListeners();

      updateNotificationActiveSet();
    } catch (e) {}
  }

  /// -------------------------
  /// TOGGLE SET
  /// -------------------------

  Future<void> toggleSetCompletion({
    required String sessionExerciseId,
    required String setId,
    required bool completed,
    double? weightKg,
    int? reps,
  }) async {
    if (_sessionId == null) return;

    int? durationSec;

    /// 🟢 If timer running for this set → stop it first
    if (_setTimers.containsKey(setId)) {
      final timer = _setTimers.remove(setId);
      timer?.cancel();

      durationSec = _setElapsedSeconds[setId] ?? 0;
    }

    await SessionService().updateSet(
      sessionId: _sessionId!,
      sessionExerciseId: sessionExerciseId,
      setId: setId,
      weightKg: weightKg,
      reps: reps,
      durationSec: durationSec, // ✅ NEW
      completed: completed,
    );

    await refreshFromBackend();

    if (!completed) return;

    final exercise = _exercises.firstWhere(
      (e) => e["id"].toString() == sessionExerciseId,
    );

    final sets = (exercise["sets"] ?? []) as List;

    final set = sets.firstWhere((s) => s["id"].toString() == setId);

    final rest = _resolveRest(exercise, set);

    if (rest != null && rest >= 5 && _shouldStartRest(exercise, set)) {
      startRest(rest);
    }
  }

  // Future<void> toggleSetCompletion({
  //   required String sessionExerciseId,
  //   required String setId,
  //   required bool completed,
  //   double? weightKg,
  //   int? reps,
  // }) async {
  //   if (_sessionId == null) return;

  //   await SessionService().updateSet(
  //     sessionId: _sessionId!,
  //     sessionExerciseId: sessionExerciseId,
  //     setId: setId,
  //     weightKg: weightKg,
  //     reps: reps,
  //     completed: completed,
  //   );

  //   await refreshFromBackend();

  //   if (!completed) return;

  //   final exercise = _exercises.firstWhere(
  //     (e) => e["id"].toString() == sessionExerciseId,
  //   );

  //   final sets = (exercise["sets"] ?? []) as List;

  //   final set = sets.firstWhere((s) => s["id"].toString() == setId);

  //   final rest = _resolveRest(exercise, set);

  //   if (rest != null && rest >= 5 && _shouldStartRest(exercise, set)) {
  //     startRest(rest);
  //   }
  // }

  /// -------------------------
  /// BUILD EXECUTION QUEUE
  /// -------------------------
  void _buildExecutionQueue() {
    _executionQueue.clear();

    if (_exercises.isEmpty) return;

    final sorted = [..._exercises]
      ..sort((a, b) => (a["orderIndex"] ?? 0).compareTo(b["orderIndex"] ?? 0));

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final ex in sorted) {
      final supersetGroup = ex["supersetGroup"];
      final key = supersetGroup ?? "single_${ex["id"]}";
      groups.putIfAbsent(key, () => []).add(ex);
    }

    for (final entry in groups.entries) {
      final exercises = entry.value;

      int maxSets = 0;

      for (final ex in exercises) {
        final sets = (ex["sets"] ?? []) as List;
        if (sets.length > maxSets) maxSets = sets.length;
      }

      for (int round = 0; round < maxSets; round++) {
        for (final ex in exercises) {
          final sets = (ex["sets"] ?? []) as List;

          if (round >= sets.length) continue;

          final set = sets[round];

          _executionQueue.add(
            _ExecutionStep(
              exerciseId: ex["id"].toString(),
              exerciseName: ex["name"] ?? "Exercise",
              setId: set["id"].toString(),
              setNumber: round + 1,
              totalSets: sets.length,
              weight: set["weightKg"]?.toString() ?? "--",
              reps: set["reps"] ?? 0,
              durationSec: set["durationSec"],
              completed: set["completed"] == true,
              imageUrl: ex["exercise"]?["mediaUrl"], // ✅ FIX
            ),
          );
        }
      }
    }
  }

  void resetSetTimer(String setId, int newDuration) {
    _setTimers.remove(setId)?.cancel();
    _setElapsedSeconds[setId] = newDuration;
    notifyListeners();
  }

  Future<void> setExerciseEffort({
    required String sessionExerciseId,
    required int? howHard,
  }) async {
    if (_sessionId == null) return;

    try {
      await SessionService().updateExerciseEffort(
        sessionId: _sessionId!,
        sessionExerciseId: sessionExerciseId,
        howHard: howHard,
      );

      final exercise = _exercises.firstWhere(
        (e) => e["id"].toString() == sessionExerciseId,
        orElse: () => {},
      );

      if (exercise.isNotEmpty) {
        exercise["howHard"] = howHard;
      }

      notifyListeners();
    } catch (e) {}
  }

  /// -------------------------
  /// REST RESOLUTION
  /// -------------------------
  int? _resolveRest(Map<String, dynamic> exercise, Map<String, dynamic> set) {
    final supersetGroup = exercise["supersetGroup"];

    if (supersetGroup == null) {
      return exercise["restSeconds"];
    }

    final groupExercises = _exercises
        .where((e) => e["supersetGroup"] == supersetGroup)
        .toList();

    final currentRest = exercise["restSeconds"];
    if (currentRest != null && currentRest >= 5) {
      return currentRest;
    }

    for (final ex in groupExercises) {
      final r = ex["restSeconds"];
      if (r != null && r >= 5) {
        return r;
      }
    }

    return null;
  }

  /// -------------------------
  /// REST DECISION
  /// -------------------------
  bool _shouldStartRest(
    Map<String, dynamic> exercise,
    Map<String, dynamic> set,
  ) {
    final sets = (exercise["sets"] ?? []) as List;

    final setId = set["id"].toString();
    final setIndex = sets.indexWhere((s) => s["id"].toString() == setId);

    final isDropSet = set["isDropSet"] == true;
    final supersetGroup = exercise["supersetGroup"];

    if (isDropSet) {
      final parentId = set["dropOfSetId"];

      final dropSets = sets.where(
        (s) =>
            s["isDropSet"] == true &&
            s["dropOfSetId"]?.toString() == parentId.toString(),
      );

      for (final s in dropSets) {
        if (s["completed"] != true && s["id"].toString() != setId) {
          return false;
        }
      }

      return true;
    }

    if (supersetGroup != null) {
      final groupExercises = _exercises.where(
        (e) => e["supersetGroup"] == supersetGroup,
      );

      for (final ex in groupExercises) {
        final groupSets = (ex["sets"] ?? []) as List;

        if (setIndex >= groupSets.length) continue;

        final s = groupSets[setIndex];

        if (s["completed"] != true) {
          return false;
        }
      }

      return true;
    }

    final hasDrops = sets.any(
      (s) => s["isDropSet"] == true && s["dropOfSetId"]?.toString() == setId,
    );

    return !hasDrops;
  }

  int getDisplayDuration(String setId) {
    if (_setTimers.containsKey(setId)) {
      return _setElapsedSeconds[setId] ?? 0;
    }

    return getBackendDuration(setId);
  }

  /// -------------------------
  /// NEXT SET INFO
  /// -------------------------
  _NextSetInfo? _getNextSetInfo() {
    for (final step in _executionQueue) {
      if (!step.completed) {
        return _NextSetInfo(
          exercise: step.exerciseName,
          exerciseId: step.exerciseId,
          setId: step.setId,
          set: step.setNumber,
          totalSets: step.totalSets,
          weight: step.weight,
          reps: step.reps,
          durationSec: step.durationSec,
          imageUrl: step.imageUrl, // ✅ ADD
        );
      }
    }

    return null;
  }

  /// -------------------------
  /// START REST
  /// -------------------------
  void startRest(int seconds) {
    _restTotal = seconds;

    _restEndTime = DateTime.now().add(Duration(seconds: seconds));

    _notificationState = WorkoutNotificationState.recovery;

    _recoveryLoop?.cancel();

    _recoveryLoop = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = restRemaining;

      if (remaining <= 3 && remaining > 0) {
        HapticFeedback.lightImpact();
      }

      if (remaining <= 0) {
        _recoveryLoop?.cancel();

        HapticFeedback.mediumImpact();

        try {
          await _audioPlayer.play(
            AssetSource('sounds/workout-timer-complete-sound.mp3'),
          );
        } catch (_) {}
        updateNotificationActiveSet();
        notifyListeners();
        return;
      }

      refreshRecoveryNotification();
    });

    notifyListeners();
  }

  /// -------------------------
  /// ADJUST REST
  /// -------------------------
  void adjustRest(int delta) {
    if (!isResting) return;

    final newRemaining = (restRemaining + delta).clamp(5, 600);

    _restEndTime = DateTime.now().add(Duration(seconds: newRemaining));

    refreshRecoveryNotification();

    notifyListeners();
  }

  /// -------------------------
  /// RECOVERY NOTIFICATION
  /// -------------------------
  void refreshRecoveryNotification() {
    if (!isResting) return;

    final next = _getNextSetInfo();

    if (next == null) return;

    LocalNotificationService.showRecovery(
      exercise: next.exercise,
      nextSet: next.set,
      totalSets: next.totalSets,
      weight: next.weight,
      reps: next.reps,
      remaining: restRemaining,
      total: _restTotal,
      imageUrl: next.imageUrl,
    );
  }

  /// -------------------------
  /// ACTIVE SET NOTIFICATION
  /// -------------------------
  void updateNotificationActiveSet() {
    if (!isActive) return;

    // 🟡 CASE 1: workout has no exercises
    if (_exercises.isEmpty) {
      LocalNotificationService.showNoExercise(sessionId: sessionId!);
      return;
    }

    final next = _getNextSetInfo();

    // 🟢 CASE 2: workout completed
    if (next == null) {
      LocalNotificationService.showActiveSet(
        sessionId: sessionId!,
        exercise: "Workout Complete",
        set: 0,
        totalSets: 0,
        valueText: "All sets completed",
      );
      return;
    }
    String valueText;

    if (next.durationSec != null && next.durationSec! > 0) {
      valueText = formatDuration(next.durationSec!);
    } else if (next.weight == "--") {
      valueText = "${next.reps} reps";
    } else {
      valueText = "${next.weight} × ${next.reps}";
    }
    LocalNotificationService.showActiveSet(
      sessionId: sessionId!,
      exercise: next.exercise,
      set: next.set,
      totalSets: next.totalSets,
      valueText: valueText,
      imageUrl: next.imageUrl,
    );
  }

  /// -------------------------
  /// SKIP REST
  /// -------------------------
  void skipRest() {
    _recoveryLoop?.cancel();
    _recoveryLoop = null;

    _restWasSkipped = true;

    _restEndTime = null;

    _notificationState = WorkoutNotificationState.activeSet;

    updateNotificationActiveSet();

    notifyListeners();
  }

  /// -------------------------
  /// COMPLETE NEXT SET
  /// -------------------------
  Future<void> completeNextSet() async {
    if (_actionInProgress) return;

    _actionInProgress = true;

    try {
      final next = _getNextSetInfo();

      if (next == null || _sessionId == null) return;

      await SessionService().updateSet(
        sessionId: _sessionId!,
        sessionExerciseId: next.exerciseId,
        setId: next.setId,
        completed: true,
      );

      await refreshFromBackend();

      final exercise = _exercises.firstWhere(
        (e) => e["id"].toString() == next.exerciseId,
      );

      final sets = (exercise["sets"] ?? []) as List;

      final set = sets.firstWhere((s) => s["id"].toString() == next.setId);

      final rest = _resolveRest(exercise, set);

      if (rest != null && rest >= 5 && _shouldStartRest(exercise, set)) {
        startRest(rest);
      }
    } catch (e) {
    } finally {
      _actionInProgress = false;
    }
  }

  /// -------------------------
  /// CLEAR
  /// -------------------------
  void clear() {
    _sessionId = null;
    _startedAt = null;
    _workoutName = null;
    _exercises = [];

    _recoveryLoop?.cancel();

    _restEndTime = null;

    instance = null;

    notifyListeners();

    LocalNotificationService.stopActiveWorkout();
  }

  String get nextExerciseName {
    final next = _getNextSetInfo();

    if (next == null) return "Workout Complete";

    return next.exercise;
  }
}

class _ExecutionStep {
  final String exerciseId;
  final String exerciseName;
  final String setId;
  final int setNumber;
  final int totalSets;
  final String weight;
  final int reps;
  final int? durationSec;
  final String? imageUrl; // ✅ ADD
  bool completed;

  _ExecutionStep({
    required this.exerciseId,
    required this.exerciseName,
    required this.setId,
    required this.setNumber,
    required this.totalSets,
    required this.weight,
    required this.reps,
    this.durationSec,
    required this.completed,
    this.imageUrl, // ✅ ADD
  });
}

class _NextSetInfo {
  final String exercise;
  final String exerciseId;
  final String setId;
  final int set;
  final int totalSets;
  final String weight;
  final int reps;
  final int? durationSec;
  final String? imageUrl; // ✅ ADD THIS

  _NextSetInfo({
    required this.exercise,
    required this.exerciseId,
    required this.setId,
    required this.set,
    required this.totalSets,
    required this.weight,
    required this.reps,
    this.durationSec,
    this.imageUrl, // ✅ ADD THIS
  });
}

String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  if (hours > 0) {
    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  return "${minutes.toString().padLeft(2, '0')}:"
      "${secs.toString().padLeft(2, '0')}";
}
