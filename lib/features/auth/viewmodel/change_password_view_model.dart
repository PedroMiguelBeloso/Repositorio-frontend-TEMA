import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../data/auth_repository.dart';
import '../data/dto/auth_dtos.dart';

class ChangePasswordViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword, 
          newPassword: newPassword,
        ),
      );
      
      // Limpiar sesión local al tener éxito (204)
      ref.read(sessionProvider.notifier).clearSession();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(
        ValidationFailure(
          'Error al cambiar la contraseña. Verifique su contraseña actual.',
        ),
        st
      );
      return false;
    }
  }
}

final changePasswordViewModelProvider = 
    AsyncNotifierProvider.autoDispose<ChangePasswordViewModel, void>(
  ChangePasswordViewModel.new,
);