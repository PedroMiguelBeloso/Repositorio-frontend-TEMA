enum UserRole { reader, administrator }

class Session {
  const Session({required this.role, this.token});

  final UserRole role;
  final String? token;
}
