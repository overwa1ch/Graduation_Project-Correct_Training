import 'package:aiwa_core/fit_domain/fit_domain.dart';

T requireFound<T>(
  T? value, {
  required String errorCode,
  required String message,
  required Map<String, dynamic> context,
}) {
  if (value == null) {
    throw NotFoundException(errorCode, message, context);
  }
  return value;
}
