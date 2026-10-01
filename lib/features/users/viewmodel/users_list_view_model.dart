import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../data/user_repository.dart';
import '../../../features/auth/model/auth_models.dart';

class UsersListViewModel extends AsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> build() async {
    return _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    try {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.listUsers(0, 50);
      return result.items;
    } catch (error) {
      throw const ApiExceptionMapper().mapError(
        error,
        fallbackMessage: 'No se pudieron cargar los usuarios.',
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }
}

final usersListViewModelProvider =
    AsyncNotifierProvider.autoDispose<UsersListViewModel, List<User>>(
      UsersListViewModel.new,
    );
