import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_theme.dart';
import '../auth/session_provider.dart';
import 'account_menu.dart';

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
                      if (isAdministrator)
                        const PopupMenuItem(
                          value: RouteNames.usersPath,
                          child: Text('Usuarios'),
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
                  _accountMenu(context, ref, alignRight: true),
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
    bool alignRight = false,
  }) {
    final session = ref.watch(sessionProvider);
    final userName = session?.user?.displayName.trim().isNotEmpty == true
        ? session!.user!.displayName.trim()
        : 'Mi cuenta';
    final email = session?.user?.email ?? '';
    final role = session?.isAdmin == true ? 'Administrador' : 'Lector';
    return AccountMenu(
      userName: userName,
      email: email,
      role: role,
      expanded: expanded,
      alignRight: alignRight,
      onChangePassword: () => context.go(RouteNames.changePasswordPath),
      onLogout: () => ref.read(sessionProvider.notifier).clearSession(),
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
    if (isAdministrator)
      const _NavigationDestination(
        label: 'Usuarios',
        path: RouteNames.usersPath,
        icon: Icons.people_outline,
      ),
  ];

  int _selectedIndex(BuildContext context, bool isAdministrator) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteNames.processesPath)) return 1;
    if (location == RouteNames.registryPath) return 2;
    if (location.startsWith(RouteNames.servicesPath)) return 3;
    if (location.startsWith(RouteNames.verificationsPath)) return 4;
    if (isAdministrator && location == RouteNames.integrationsPath) return 5;
    if (isAdministrator && location.startsWith(RouteNames.usersPath)) return 6;
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
