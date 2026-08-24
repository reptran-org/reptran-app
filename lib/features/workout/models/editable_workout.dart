class EditableWorkout {
  final String id;
  String title;
  String? description;

  List<EditableWorkoutExercise> exercises;

  EditableWorkout({
    required this.id,
    required this.title,
    required this.exercises,
    this.description,
  });

  /// Convert API response → editable state
  factory EditableWorkout.fromApi(Map<String, dynamic> json) {
    final exercisesJson = (json["exercises"] ?? []) as List;

    return EditableWorkout(
      id: json["id"].toString(),
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString(),
      exercises: exercisesJson
          .map(
            (e) =>
                EditableWorkoutExercise.fromApi(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  /// Convert editable state → payload for backend
  Map<String, dynamic> toPayload() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "exercises": exercises.map((e) => e.toPayload()).toList(),
    };
  }
}

class EditableWorkoutExercise {
  final String id;
  String trackingType;

  int orderIndex;

  String? exerciseId;
  String name;
  String? mediaUrl;

  int? restSeconds;
  String? supersetGroup;
  String? notes;

  List<EditableWorkoutSet> sets;

  EditableWorkoutExercise({
    required this.id,
    required this.trackingType,
    required this.orderIndex,
    required this.name,
    required this.sets,
    this.exerciseId,
    this.mediaUrl,
    this.restSeconds,
    this.supersetGroup,
    this.notes,
  });

  factory EditableWorkoutExercise.fromApi(Map<String, dynamic> json) {
    final setsJson = (json["sets"] ?? []) as List;

    final name =
        json["customName"] ??
        json["exercise"]?["name"] ??
        json["name"] ??
        "Exercise";

    return EditableWorkoutExercise(
      id: json["id"].toString(),
      trackingType: json["exercise"]?["trackingType"] ?? "REPS_WEIGHT",
      orderIndex: json["orderIndex"] ?? 0,
      exerciseId: json["exerciseId"]?.toString(),
      name: name.toString(),
      mediaUrl: json["exercise"]?["mediaUrl"]?.toString(),
      restSeconds: json["restSeconds"],
      supersetGroup: json["supersetGroup"]?.toString(),
      notes: json["notes"]?.toString(),
      sets: setsJson
          .map((s) => EditableWorkoutSet.fromApi(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      "id": id,
      "trackingType": trackingType,
      "orderIndex": orderIndex,
      "exerciseId": exerciseId,
      "customName": name,
      "restSeconds": restSeconds,
      "supersetGroup": supersetGroup,
      "notes": notes,
      "sets": sets.map((s) => s.toPayload()).toList(),
    };
  }
}

class EditableWorkoutSet {
  final String id;

  int setIndex;

  int? reps;
  double? weightKg;
  int? durationSec;
  String? tempo;

  bool isWarmup;
  bool isDropSet;
  String? dropOfSetId;

  int? restSec;
  bool isFailure;

  EditableWorkoutSet({
    required this.id,
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSec,
    this.tempo,
    this.isWarmup = false,
    this.isDropSet = false,
    this.dropOfSetId,
    this.restSec,
    this.isFailure = false,
  });

  factory EditableWorkoutSet.fromApi(Map<String, dynamic> json) {
    return EditableWorkoutSet(
      id: json["id"].toString(),
      setIndex: json["setIndex"] ?? 0,
      reps: json["reps"],
      weightKg: (json["weightKg"] as num?)?.toDouble(),
      durationSec: json["durationSec"],
      tempo: json["tempo"]?.toString(),
      isWarmup: json["isWarmup"] ?? false,
      isDropSet: json["isDropSet"] ?? false,
      dropOfSetId: json["dropOfSetId"]?.toString(),
      restSec: json["restSec"],
      isFailure: json["isFailure"] ?? false,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      "id": id,
      "setIndex": setIndex,
      "reps": reps,
      "weightKg": weightKg,
      "durationSec": durationSec,
      "tempo": tempo,
      "isWarmup": isWarmup,
      "isDropSet": isDropSet,
      "dropOfSetId": dropOfSetId,
      "restSec": restSec,
      "isFailure": isFailure,
    };
  }
}
