import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/model/auth_models.dart';
import '../viewmodel/users_list_view_model.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Lector'),
            onPressed: () => context.push('/users/new'),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: AsyncContent<List<User>>(
        value: usersState,
        errorMessage: 'No se pudieron cargar los usuarios.',
        emptyMessage: 'No hay usuarios.',
        isEmpty: (users) => users.isEmpty,
        onRetry: () => ref.read(usersListViewModelProvider.notifier).refresh(),
        builder: (users) => RefreshIndicator(
          onRefresh: () =>
              ref.read(usersListViewModelProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.displayName),
                subtitle: Text('${user.email} • Rol: ${user.role.value}'),
                trailing: StatusChip(
                  label: user.active ? 'Activo' : 'Inactivo',
                  tone: user.active ? StatusTone.success : StatusTone.danger,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
