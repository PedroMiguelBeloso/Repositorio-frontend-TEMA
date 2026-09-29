import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_repository.dart';
import '../../../features/auth/model/auth_models.dart';

class UsersListViewModel extends AsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> build() async {
    return _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    final repo = ref.read(userRepositoryProvider);
    // Consumir GET /users respetando paginación inicial
    final result = await repo.listUsers(0, 50); 
    return result.items;
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