import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/auth/session_provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/placeholder_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable();
  ref.listen<Session?>(sessionProvider, (previous, next) {
    refreshListenable.refresh();
  });

  final router = GoRouter(
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isLoginRoute = state.matchedLocation == RouteNames.loginPath;

      if (session == null) {
        return isLoginRoute ? null : RouteNames.loginPath;
      }
      if (isLoginRoute) return RouteNames.homePath;
      if (session.role == UserRole.reader &&
          RouteNames.isAdminOnly(state.matchedLocation)) {
        return RouteNames.homePath;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Página no encontrada'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(RouteNames.homePath),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        name: RouteNames.loginName,
        path: RouteNames.loginPath,
        builder: (context, state) =>
            const Scaffold(body: PlaceholderPage(title: 'Iniciar sesión')),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            name: RouteNames.homeName,
            path: RouteNames.homePath,
            builder: (context, state) => const PlaceholderPage(title: 'Inicio'),
          ),
          GoRoute(
            name: RouteNames.processesName,
            path: RouteNames.processesPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Procesos'),
          ),
          GoRoute(
            name: RouteNames.processDetailsName,
            path: RouteNames.processDetailsPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Detalle del proceso'),
          ),
          GoRoute(
            name: RouteNames.processHistoryName,
            path: RouteNames.processHistoryPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Historial del proceso'),
          ),
          GoRoute(
            name: RouteNames.servicesName,
            path: RouteNames.servicesPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Servicios'),
          ),
          GoRoute(
            name: RouteNames.verificationsName,
            path: RouteNames.verificationsPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Verificaciones'),
          ),
          GoRoute(
            name: RouteNames.newVerificationName,
            path: RouteNames.newVerificationPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Nueva verificación'),
          ),
          GoRoute(
            name: RouteNames.verificationDetailsName,
            path: RouteNames.verificationDetailsPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Detalle de verificación'),
          ),
          GoRoute(
            name: RouteNames.verificationResultsName,
            path: RouteNames.verificationResultsPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Resultados de verificación'),
          ),
          GoRoute(
            name: RouteNames.integrationsName,
            path: RouteNames.integrationsPath,
            builder: (context, state) =>
                const PlaceholderPage(title: 'Integraciones'),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshListenable.dispose();
  });
  return router;
});

class _RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
