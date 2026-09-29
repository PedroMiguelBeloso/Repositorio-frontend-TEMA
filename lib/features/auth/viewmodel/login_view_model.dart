import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/session_provider.dart';
import '../data/auth_repository.dart';
import '../model/auth_models.dart';
import '../../../core/errors/app_failure.dart';

class LoginViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final repo = ref.read(authRepositoryProvider);
      final request = LoginRequest(email: email, password: password);
      
      final response = await repo.login(request);
      
      // Validaciones defensivas de negocio
      if (!response.user.active || response.user.role == Role.unknown || response.expiresAt.isBefore(DateTime.now())) {
        state = AsyncValue.error(
          UnauthenticatedFailure('Credenciales inválidas o cuenta inactiva.'),
          StackTrace.current,
        );
        return;
      }

      // Actualizar única fuente de verdad
      ref.read(sessionProvider.notifier).setSessionFromResponse(response);
      state = const AsyncValue.data(null);

    } catch (e, st) {
      // Mapear el error (ej. 401) a un AppFailure seguro
      state = AsyncValue.error(
        UnexpectedFailure('Credenciales inválidas o error de red.'),
        st,
      );
    }
  }
}

final loginViewModelProvider =
    AsyncNotifierProvider.autoDispose<LoginViewModel, void>(
  LoginViewModel.new,
);