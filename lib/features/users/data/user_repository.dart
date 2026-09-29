import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../features/auth/model/auth_models.dart';
import 'dto/user_dtos.dart';

abstract interface class UserRepository {
  Future<PaginatedUsers> listUsers(int page, int size);
  Future<User> createReader(CreateReaderRequest request);
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedUsers> listUsers(int page, int size) async {
    final response = await _apiClient.get(
      '/users',
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedUsers.fromJson(response.data);
  }

  @override
  Future<User> createReader(CreateReaderRequest request) async {
    final response = await _apiClient.post(
      '/users',
      data: request.toJson(),
    );
    return User.fromJson(response.data);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(apiClientProvider));
});