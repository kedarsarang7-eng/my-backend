/// Input validators
class Validators {
  /// Validate phone number (10 digits)
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 10;
  }

  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.isNotEmpty && password.length >= 4;
  }

  /// Validate name
  static bool isValidName(String name) {
    return name.isNotEmpty && name.length >= 2;
  }
}
