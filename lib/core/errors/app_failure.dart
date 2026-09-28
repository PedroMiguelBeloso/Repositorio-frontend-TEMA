sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}

final class ServiceFailure extends AppFailure {
  const ServiceFailure(super.message);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message);
}
