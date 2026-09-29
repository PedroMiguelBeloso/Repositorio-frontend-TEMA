import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Lector'),
            onPressed: () => context.push('/users/new'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: usersState.when(
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No hay usuarios.'));
          return RefreshIndicator(
            onRefresh: () => ref.read(usersListViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  title: Text(u.displayName),
                  subtitle: Text('${u.email} • Rol: ${u.role.value}'),
                  trailing: Text(u.active ? 'Activo' : 'Inactivo', 
                    style: TextStyle(color: u.active ? Colors.green : Colors.red),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              TextButton(
                onPressed: () => ref.read(usersListViewModelProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}