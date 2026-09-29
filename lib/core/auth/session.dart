import '../../features/auth/model/auth_models.dart';

enum UserRole { reader, administrator }

class Session {
  const Session({
    UserRole? role,
    String? token,
    String? accessToken,
    this.user,
    this.expiresAt,
  }) : _legacyRole = role,
       accessToken = accessToken ?? token;

  final UserRole? _legacyRole;
  final String? accessToken;
  final User? user;
  final DateTime? expiresAt;

  String? get token => accessToken;

  UserRole? get role {
    if (user == null) return _legacyRole;
    return switch (user!.role) {
      Role.reader => UserRole.reader,
      Role.admin => UserRole.administrator,
      Role.unknown => null,
    };
  }

  bool get isValid {
    final currentUser = user;
    if (currentUser == null) return _legacyRole != null;
    return accessToken != null &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt!) &&
        currentUser.active &&
        currentUser.role != Role.unknown;
  }

  bool get isAdmin => isValid && role == UserRole.administrator;
  bool get isReader => isValid && role == UserRole.reader;
}
