final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _wholeNumber = RegExp(r'^\d+$');

/// Form validators. The messages are the exact texts required by the exam.
class Validators {
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length > 80) return 'Name must be at most 80 characters';
    return null;
  }

  static String? category(String? value) =>
      value == null ? 'Please choose a category' : null;

  static String? difficulty(String? value) =>
      value == null ? 'Please choose a difficulty' : null;

  static String? cookTime(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Cook time is required';
    if (!_inRange(v, 1, 600)) {
      return 'Cook time must be a whole number from 1 to 600';
    }
    return null;
  }

  static String? servings(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_inRange(v, 1, 20)) return 'Servings must be a whole number from 1 to 20';
    return null;
  }

  static String? notes(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 300) return 'Notes must be at most 300 characters';
    return null;
  }

  static bool _inRange(String v, int min, int max) {
    if (!_wholeNumber.hasMatch(v)) return false;
    final n = int.tryParse(v);
    return n != null && n >= min && n <= max;
  }
}
