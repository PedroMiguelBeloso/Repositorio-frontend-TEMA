import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../data/dto/user_dtos.dart';
import '../data/user_repository.dart';
import 'users_list_view_model.dart';

class CreateReaderViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createReader(
    String email,
    String displayName,
    String password,
  ) async {
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        const ApiExceptionMapper().mapError(
          error,
          fallbackMessage: 'No se pudo crear el usuario. Revisá los datos.',
        ),
        stackTrace,
      );
      return false;
    }
  }
}

final createReaderViewModelProvider =
    AsyncNotifierProvider.autoDispose<CreateReaderViewModel, void>(
      CreateReaderViewModel.new,
    );
