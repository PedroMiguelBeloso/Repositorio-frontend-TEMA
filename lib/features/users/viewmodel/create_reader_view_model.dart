import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../data/dto/user_dtos.dart';
import '../data/user_repository.dart';
import 'users_list_view_model.dart';

class CreateReaderViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createReader(String email, String displayName, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.createReader(
        CreateReaderRequest(
          email: email,
          displayName: displayName,
          initialPassword: password,
        ),
      );
      
      // Invalidar y refrescar la lista de usuarios al crear exitosamente
      ref.invalidate(usersListViewModelProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // Un 409 o 400 se mapeará a un AppFailure generalizado mediante ApiExceptionMapper
      state = AsyncValue.error(
        ConflictFailure(
          'Error al crear usuario. Compruebe los datos o si el correo ya existe.',
        ),
        st
      );
      return false;
    }
  }
}

final createReaderViewModelProvider = 
    AsyncNotifierProvider.autoDispose<CreateReaderViewModel, void>(
  CreateReaderViewModel.new,
);