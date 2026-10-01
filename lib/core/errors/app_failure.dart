sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppFailure($statusCode): $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(String message) : super(message: message);
}

final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure(String message) : super(message: message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(String message) : super(message: message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(
    String message, {
    this.fieldErrors = const {},
  }) : super(message: message);

  final Map<String, String> fieldErrors;
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(String message) : super(message: message);
}

final class ServiceFailure extends AppFailure {
  const ServiceFailure(String message) : super(message: message);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(String message) : super(message: message);
}
