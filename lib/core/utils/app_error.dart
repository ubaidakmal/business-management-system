import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract final class AppError {
  static String messageOf(Object error) {
    if (error is AppException) return error.message;
    if (error is AuthException) return error.message;
    if (error is PostgrestException) {
      return error.message.isEmpty ? 'Database request failed.' : error.message;
    }
    if (error is FunctionException) return 'Server function failed.';
    final type = error.runtimeType.toString();
    if (type.contains('Socket') || type.contains('ClientException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
