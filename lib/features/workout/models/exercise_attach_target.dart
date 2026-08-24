enum ExerciseAttachTargetType { session, workout }

class ExerciseAttachTarget {
  final ExerciseAttachTargetType type;
  final String id;

  const ExerciseAttachTarget({
    required this.type,
    required this.id,
  });
}
