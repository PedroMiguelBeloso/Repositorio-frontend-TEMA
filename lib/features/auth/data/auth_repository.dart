import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_tema_frontend/features/auth/data/dto/auth_dtos.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../model/auth_models.dart';

abstract interface class AuthRepository {
  Future<TokenResponse> login(LoginRequest request);
  Future<User> getCurrentUser();
  Future<void> changePassword(ChangePasswordRequest request);
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: request.toJson(),
      options: Options(
        headers: {'Requires-Auth': 'false'},
      ), // Evita el interceptor
    );
    return TokenResponse.fromJson(response.data);
  }

  @override
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    return User.fromJson(response.data);
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _apiClient.put('/auth/password', data: request.toJson());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(apiClient);
});
