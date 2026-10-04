import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_theme.dart';
import '../auth/session_provider.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdministrator = ref.watch(sessionProvider)?.isAdmin == true;
    final destinations = _destinations(isAdministrator);
    final selectedIndex = _selectedIndex(context, isAdministrator);
    final mobileDestinations = [
      destinations[0],
      destinations[1],
      destinations[3],
      destinations[4],
    ];
    final mobileSelected = switch (selectedIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Scaffold(
            body: child,
            bottomNavigationBar: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: NavigationBar(
                      selectedIndex: mobileSelected,
                      onDestinationSelected: (index) =>
                          context.go(mobileDestinations[index].path),
                      destinations: [
                        for (final destination in mobileDestinations)
                          NavigationDestination(
                            icon: Icon(destination.icon),
                            label: destination.label,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Más opciones',
                    onSelected: context.go,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: RouteNames.registryPath,
                        child: Text('Índice de registros'),
                      ),
                      if (isAdministrator)
                        const PopupMenuItem(
                          value: RouteNames.integrationsPath,
                          child: Text('Integraciones'),
                        ),
                    ],
                    child: const SizedBox(
                      width: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.more_horiz), Text('Más')],
                      ),
                    ),
                  ),
                  _accountMenu(context, ref),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1100,
                trailingAtBottom: true,
                scrollable: true,
                labelType: constraints.maxWidth >= 1100
                    ? null
                    : NavigationRailLabelType.all,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    context.go(destinations[index].path),
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: _accountMenu(
                    context,
                    ref,
                    expanded: constraints.maxWidth >= 1100,
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _accountMenu(
    BuildContext context,
    WidgetRef ref, {
    bool expanded = false,
  }) {
    final session = ref.watch(sessionProvider);
    final userName = session?.user?.displayName.trim().isNotEmpty == true
        ? session!.user!.displayName.trim()
        : 'Mi cuenta';
    final email = session?.user?.email ?? '';
    final role = session?.isAdmin == true ? 'Administrador' : 'Lector';
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Perfil',
      position: PopupMenuPosition.over,
      offset: const Offset(0, -176),
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 280),
      color: AppColors.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: expanded
            ? Container(
                width: 228,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppColors.surfaceWhite,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            'Perfil',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              )
            : const SizedBox(
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle_outlined),
                    SizedBox(height: AppSpacing.xs),
                    Text('Perfil'),
                  ],
                ),
              ),
      ),
      onSelected: (action) {
        switch (action) {
          case _AccountAction.changePassword:
            context.go(RouteNames.changePasswordPath);
          case _AccountAction.logout:
            ref.read(sessionProvider.notifier).clearSession();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_AccountAction>(
          enabled: false,
          height: 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              Text(
                role,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: _AccountAction.changePassword,
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 20),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Cambiar contraseña')),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _AccountAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Cerrar sesión')),
            ],
          ),
        ),
      ],
    );
  }

  List<_NavigationDestination> _destinations(bool isAdministrator) => [
    const _NavigationDestination(
      label: 'Inicio',
      path: RouteNames.homePath,
      icon: Icons.home_outlined,
    ),
    const _NavigationDestination(
      label: 'Procesos',
      path: RouteNames.processesPath,
      icon: Icons.account_tree_outlined,
    ),
    const _NavigationDestination(
      label: 'Registros',
      path: RouteNames.registryPath,
      icon: Icons.menu_book_outlined,
    ),
    const _NavigationDestination(
      label: 'Servicios',
      path: RouteNames.servicesPath,
      icon: Icons.miscellaneous_services_outlined,
    ),
    const _NavigationDestination(
      label: 'Verificaciones',
      path: RouteNames.verificationsPath,
      icon: Icons.fact_check_outlined,
    ),
    if (isAdministrator)
      const _NavigationDestination(
        label: 'Integraciones',
        path: RouteNames.integrationsPath,
        icon: Icons.extension_outlined,
      ),
  ];

  int _selectedIndex(BuildContext context, bool isAdministrator) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteNames.processesPath)) return 1;
    if (location == RouteNames.registryPath) return 2;
    if (location.startsWith(RouteNames.servicesPath)) return 3;
    if (location.startsWith(RouteNames.verificationsPath)) return 4;
    if (isAdministrator && location == RouteNames.integrationsPath) return 5;
    return 0;
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}

enum _AccountAction { changePassword, logout }
