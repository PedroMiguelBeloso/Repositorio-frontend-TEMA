enum Role {
  admin('ADMIN'),
  reader('READER'),
  unknown('UNKNOWN');

  final String value;
  const Role(this.value);

  factory Role.fromString(String value) {
    return Role.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Role.unknown,
    );
  }
}

class User {
  final String id;
  final String email;
  final String displayName;
  final Role role;
  final bool active;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: Role.fromString(json['role'] as String),
      active: json['active'] as bool,
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final User user;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}