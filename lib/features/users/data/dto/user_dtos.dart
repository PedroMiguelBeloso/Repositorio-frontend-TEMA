import '../../../auth/model/auth_models.dart';
class CreateReaderRequest {
  final String email;
  final String displayName;
  final String initialPassword;

  CreateReaderRequest({
    required this.email,
    required this.displayName,
    required this.initialPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'displayName': displayName,
    'initialPassword': initialPassword,
    // No se envía el rol, el endpoint siempre crea Lector.
  };
}

class PaginatedUsers {
  final List<User> items;
  // page y size pueden omitirse en este DTO simple si no usamos la metadata visualmente aún

  PaginatedUsers({required this.items});

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List;
    return PaginatedUsers(
      items: list.map((e) => User.fromJson(e)).toList(),
    );
  }
}