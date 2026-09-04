abstract final class Validators {
  static String? requiredField(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, 'Email');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, 'Password');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? phone(String? value) {
    final requiredError = requiredField(value, 'Phone');
    if (requiredError != null) return requiredError;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? number(String? value) {
    final requiredError = requiredField(value, 'Number');
    if (requiredError != null) return requiredError;
    if (num.tryParse(value!.trim()) == null) return 'Enter a valid number.';
    return null;
  }

  static String? positiveNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) return numberError;
    if (num.parse(value!.trim()) <= 0) return 'Enter a number greater than 0.';
    return null;
  }
}
