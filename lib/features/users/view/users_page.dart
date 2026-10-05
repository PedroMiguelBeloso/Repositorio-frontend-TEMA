import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/model/auth_models.dart';
import '../viewmodel/users_list_view_model.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersListViewModelProvider);
    final notifier = ref.read(usersListViewModelProvider.notifier);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Gestión de usuarios',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Consultá los usuarios del sistema y creá cuentas con rol Lector.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Lector'),
                    onPressed: () => context.push(RouteNames.createReaderPath),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: usersState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            safeAppFailure(
                              error,
                              fallbackMessage:
                                  'No se pudieron cargar los usuarios.',
                            ).message,
                          ),
                          TextButton(
                            onPressed: notifier.refresh,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    data: (users) => users.isEmpty
                        ? const Center(
                            child: Text(
                              'Todavía no hay usuarios para mostrar.',
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 760;
                              return RefreshIndicator(
                                onRefresh: notifier.refresh,
                                child: ListView(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.card,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (wide) const _UsersHeader(),
                                          for (
                                            var index = 0;
                                            index < users.length;
                                            index++
                                          ) ...[
                                            if (index > 0)
                                              const Divider(height: 1),
                                            _UserRow(
                                              user: users[index],
                                              wide: wide,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text('Usuario', style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          flex: 4,
          child: Text('Correo', style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          flex: 2,
          child: Text('Rol', style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          flex: 2,
          child: Text('Estado', style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    ),
  );
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.wide});

  final User user;
  final bool wide;

  String get _roleLabel => switch (user.role) {
    Role.admin => 'Administrador',
    Role.reader => 'Lector',
    Role.unknown => 'Desconocido',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = Row(
      children: [
        const Icon(Icons.person_outline, size: 20, color: AppColors.info),
        const SizedBox(width: 10),
        Expanded(
          child: Text(user.displayName, style: theme.textTheme.titleSmall),
        ),
      ],
    );
    final email = Text(
      user.email,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
    final status = StatusChip(
      label: user.active ? 'Activo' : 'Inactivo',
      tone: user.active ? StatusTone.success : StatusTone.danger,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 3, child: name),
                Expanded(flex: 4, child: email),
                Expanded(flex: 2, child: Text(_roleLabel)),
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.centerLeft, child: status),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                const SizedBox(height: AppSpacing.sm),
                email,
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [Text('Rol: $_roleLabel'), status],
                ),
              ],
            ),
    );
  }
}
