import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isAdmin = session?.isAdmin == true;
    final theme = Theme.of(context);
    final name = session?.user?.displayName.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola${name?.isNotEmpty == true ? ', $name' : ''}',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isAdmin
                      ? 'Configurá procesos y servicios para preparar las verificaciones.'
                      : 'Consultá los procesos, servicios y verificaciones disponibles.',
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _HomeAction(
                      icon: Icons.account_tree_outlined,
                      title: 'Procesos',
                      description: isAdmin
                          ? 'Crear borradores, cargar actividades y publicar versiones.'
                          : 'Consultar procesos y versiones publicadas.',
                      label: 'Ver procesos',
                      onTap: () => context.go(RouteNames.processesPath),
                    ),
                    _HomeAction(
                      icon: Icons.menu_book_outlined,
                      title: 'Índice de registros',
                      description:
                          'Consultar los registros de referencia para entradas, salidas y actividades.',
                      label: 'Abrir índice',
                      onTap: () => context.go(RouteNames.registryPath),
                    ),
                    _HomeAction(
                      icon: Icons.miscellaneous_services_outlined,
                      title: 'Servicios',
                      description:
                          'Consultar los servicios y sus procesos asignados.',
                      label: 'Ver servicios',
                      onTap: () => context.go(RouteNames.servicesPath),
                    ),
                    if (isAdmin)
                      _HomeAction(
                        icon: Icons.extension_outlined,
                        title: 'Fuentes externas',
                        description:
                            'Revisar la disponibilidad de Drive y Redmine.',
                        label: 'Ver integraciones',
                        onTap: () => context.go(RouteNames.integrationsPath),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 330,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(description),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onTap, child: Text(label)),
          ],
        ),
      ),
    ),
  );
}
