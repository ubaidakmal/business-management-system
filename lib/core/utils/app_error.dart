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
      final code = error.code;
      final details =
          '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
              .toLowerCase();
      if (code == '23505' || details.contains('duplicate')) {
        if (details.contains('companies_code')) {
          return 'A company with this code already exists.';
        }
        if (details.contains('products_sku')) {
          return 'A product with this SKU already exists.';
        }
        if (details.contains('products_barcode')) {
          return 'A product with this barcode already exists.';
        }
        return 'This record already exists.';
      }
      if (code == '23503' || details.contains('foreign key')) {
        return 'This record is linked to other data and cannot be deleted. Deactivate it instead.';
      }
      return error.message.isEmpty ? 'Database request failed.' : error.message;
    }
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['message'] is String) {
        return details['message'] as String;
      }
      if (details is String && details.trim().isNotEmpty) return details;
      final reason = error.reasonPhrase;
      if (reason != null && reason.isNotEmpty) return reason;
      return 'Server function failed.';
    }
    final type = error.runtimeType.toString();
    if (type.contains('Socket') || type.contains('ClientException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
