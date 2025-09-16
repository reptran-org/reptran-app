String? requiredValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'This field is required';
  return null;
}

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  final email = v.trim();
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
  return null;
}

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}
