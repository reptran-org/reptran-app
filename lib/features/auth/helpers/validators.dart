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

  final password = v.trim();

  if (password.length < 8) {
    return 'Must be at least 8 characters';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Must include a lowercase letter';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Must include an uppercase letter';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Must include a number';
  }
  if (!RegExp(r'[\W_]').hasMatch(password)) {
    return 'Must include a special character';
  }

  return null;
}