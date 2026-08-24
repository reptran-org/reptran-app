class WorkoutTemplateModel {
  final String id;
  final String key;
  final String title;
  final String? description;
  final String category; // STARTER | STANDARD | QUICK
  final List<String> tags;
  final int exerciseCount;
  final int? estimatedMinutes;
  final String? imageUrl; // optional (if you add later)

  WorkoutTemplateModel({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.imageUrl,
  });

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateModel(
      id: json['id'] as String,
      key: (json['key'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      category: (json['category'] ?? 'STANDARD') as String,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      exerciseCount: (json['exerciseCount'] ?? 0) as int,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class WorkoutTemplateExerciseModel {
  final String id;
  final int orderIndex;
  final int? restSeconds;
  final String? notes;
  final Map<String, dynamic>? recommended;

  final String? exerciseId;
  final String name;
  final String? mediaUrl;

  WorkoutTemplateExerciseModel({
    required this.id,
    required this.orderIndex,
    required this.restSeconds,
    required this.notes,
    required this.recommended,
    required this.exerciseId,
    required this.name,
    required this.mediaUrl,
  });

  factory WorkoutTemplateExerciseModel.fromJson(Map<String, dynamic> json) {
    final ex = json['exercise'] as Map<String, dynamic>?;

    return WorkoutTemplateExerciseModel(
      id: json['id'] as String,
      orderIndex: (json['orderIndex'] ?? 0) as int,
      restSeconds: json['restSeconds'] as int?,
      notes: json['notes'] as String?,
      recommended: json['recommended'] as Map<String, dynamic>?,
      exerciseId: ex?['id'] as String?,
      name: (ex?['name'] ?? json['customName'] ?? 'Exercise') as String,
      mediaUrl: ex?['mediaUrl'] as String?,
    );
  }

  int get sets => (recommended?['sets'] ?? 0) as int;
  int get reps => (recommended?['reps'] ?? 0) as int;
  int get seconds => (recommended?['seconds'] ?? 0) as int;
}

class WorkoutTemplateDetailsModel {
  final String id;
  final String title;
  final String? description;
  final String category;
  final List<String> tags;

  final int exerciseCount;
  final int? estimatedMinutes;
  final String? coverImageUrl;

  final List<WorkoutTemplateExerciseModel> exercises;

  WorkoutTemplateDetailsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.coverImageUrl,
    required this.exercises,
  });

  factory WorkoutTemplateDetailsModel.fromJson(Map<String, dynamic> json) {
    final list = (json['exercises'] as List<dynamic>? ?? []);

    return WorkoutTemplateDetailsModel(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      category: (json['category'] ?? 'STANDARD') as String,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      exerciseCount: (json['exerciseCount'] ?? 0) as int,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      exercises: list.map((e) => WorkoutTemplateExerciseModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
