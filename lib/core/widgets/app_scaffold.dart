import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../auth/session.dart';
import '../auth/session_provider.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdministrator =
        ref.watch(sessionProvider)?.role == UserRole.administrator;
    final destinations = _destinations(isAdministrator);
    final selectedIndex = _selectedIndex(context, isAdministrator);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1100,
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
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
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
    if (location.startsWith(RouteNames.servicesPath)) return 2;
    if (location.startsWith(RouteNames.verificationsPath)) return 3;
    if (isAdministrator && location == RouteNames.integrationsPath) return 4;
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
