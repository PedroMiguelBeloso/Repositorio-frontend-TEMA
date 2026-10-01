import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/auth/session_provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/placeholder_page.dart';
import '../../features/auth/view/change_password_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/users/view/create_reader_page.dart';
import '../../features/users/view/users_page.dart';
import '../../features/processes/view/process_pages.dart';
import '../../features/processes/view/process_editor_page.dart' as m1_editor;
import '../../features/processes/view/process_list_page.dart' as m1_list;
import '../../features/processes/viewmodel/process_editor_view_model.dart'
  as m1_editor_vm;
import '../../features/services/view/service_detail_page.dart';
import '../../features/services/view/service_form_page.dart';
import '../../features/services/view/service_list_page.dart';
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

      if (session?.isValid != true) {
        return isLoginRoute ? null : RouteNames.loginPath;
      }
      if (isLoginRoute) return RouteNames.homePath;
      if (session!.isReader && RouteNames.isAdminOnly(state.matchedLocation)) {
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
        builder: (context, state) => const LoginPage(),
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
            builder: (context, state) => const m1_list.ProcessListPage(),
          ),
          GoRoute(
            name: RouteNames.processDetailsName,
            path: RouteNames.processDetailsPath,
            builder: (context, state) =>
                ProcessDetailPage(processId: state.pathParameters['id']!),
          ),
          GoRoute(
            name: RouteNames.processHistoryName,
            path: RouteNames.processHistoryPath,
            builder: (context, state) =>
                ProcessHistoryPage(processId: state.pathParameters['id']!),
          ),
          GoRoute(
            name: RouteNames.processStructureName,
            path: RouteNames.processStructurePath,
            builder: (context, state) => ProcessEditorPage(
              processId: state.pathParameters['processId']!,
              versionId: state.pathParameters['versionId']!,
            ),
          ),
          GoRoute(
            name: RouteNames.processVersionName,
            path: RouteNames.processVersionPath,
            builder: (context, state) => m1_editor.ProcessEditorPage(
              processId: state.pathParameters['id']!,
              versionId: state.pathParameters['versionId']!,
            ),
            onExit: (context, state) async {
              final processId = state.pathParameters['id'];
              final versionId = state.pathParameters['versionId'];
              if (processId == null || versionId == null) return true;

              final notifier = ref.read(
                m1_editor_vm.processEditorViewModelProvider((
                  processId: processId,
                  versionId: versionId,
                )).notifier,
              );
              if (!notifier.hasUnsavedChanges) return true;

              return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cambios sin guardar'),
                      content: const Text(
                        'Hay cambios sin guardar. Si salís ahora, se perderán.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Seguir editando'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Salir sin guardar'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
          ),
          GoRoute(
            name: RouteNames.servicesName,
            path: RouteNames.servicesPath,
            builder: (context, state) => const ServiceListPage(),
          ),
          GoRoute(
            name: RouteNames.servicesNewName,
            path: RouteNames.servicesNewPath,
            builder: (context, state) => const ServiceFormPage(),
          ),
          GoRoute(
            name: RouteNames.serviceEditName,
            path: RouteNames.serviceEditPath,
            builder: (context, state) =>
                ServiceFormPage(serviceId: state.pathParameters['id']),
          ),
          GoRoute(
            name: RouteNames.serviceDetailsName,
            path: RouteNames.serviceDetailsPath,
            builder: (context, state) =>
                ServiceDetailPage(serviceId: state.pathParameters['id']!),
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
          GoRoute(
            name: RouteNames.usersName,
            path: RouteNames.usersPath,
            builder: (context, state) => const UsersPage(),
            routes: [
              GoRoute(
                name: RouteNames.createReaderName,
                path: 'new',
                builder: (context, state) => const CreateReaderPage(),
              ),
            ],
          ),
          GoRoute(
            name: RouteNames.changePasswordName,
            path: RouteNames.changePasswordPath,
            builder: (context, state) => const ChangePasswordPage(),
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
