import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/app.dart';
import 'package:proyecto_tema_frontend/app/router/app_router.dart';
import 'package:proyecto_tema_frontend/app/router/route_names.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';

void main() {
  testWidgets('all configured authenticated routes resolve', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    final router = container.read(appRouterProvider);
    const routes = <(String, String)>[
      (RouteNames.homePath, 'Inicio'),
      (RouteNames.processesPath, 'Procesos'),
      ('/processes/process-42', 'Detalle del proceso'),
      ('/processes/process-42/history', 'Historial del proceso'),
      (RouteNames.servicesPath, 'Servicios'),
      (RouteNames.verificationsPath, 'Verificaciones'),
      (RouteNames.newVerificationPath, 'Nueva verificación'),
      ('/verifications/run-42', 'Detalle de verificación'),
      ('/verifications/run-42/results', 'Resultados de verificación'),
      (RouteNames.integrationsPath, 'Integraciones'),
    ];

    for (final (path, title) in routes) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(title), findsAtLeastNWidgets(1), reason: path);
      expect(find.text('Funcionalidad en desarrollo'), findsOneWidget);
    }
  });

  testWidgets('unknown routes show an error and can return home', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );

    container.read(appRouterProvider).go('/unknown-route');
    await tester.pumpAndSettle();

    expect(find.text('Página no encontrada'), findsOneWidget);
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsAtLeastNWidgets(1));
  });

  testWidgets('no session redirects to login', (tester) async {
    final container = await _pumpApp(tester);
    final router = container.read(appRouterProvider);

    expect(router.routeInformationProvider.value.uri.path, RouteNames.loginPath);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    router.go(RouteNames.integrationsPath);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RouteNames.loginPath);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Integraciones'), findsNothing);

    router.go(RouteNames.newVerificationPath);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RouteNames.loginPath);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Nueva verificación'), findsNothing);
  });

  testWidgets('reader is redirected from new verification', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.newVerificationPath);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RouteNames.homePath);
    expect(find.text('Nueva verificación'), findsNothing);
    expect(find.text('Inicio'), findsAtLeastNWidgets(1));
  });

  testWidgets('administrator can access new verification', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.newVerificationPath);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.newVerificationPath,
    );
    expect(find.text('Nueva verificación'), findsOneWidget);
  });

  testWidgets('reader can access verification details and results', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);
    const routes = <(String, String)>[
      ('/verifications/run-42', 'Detalle de verificación'),
      ('/verifications/run-42/results', 'Resultados de verificación'),
    ];

    for (final (path, title) in routes) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.text(title), findsOneWidget, reason: path);
    }
  });

  testWidgets('reader is redirected from every administrator-only route', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);

    for (final path in RouteNames.adminOnlyPaths) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.homePath,
        reason: path,
      );
      expect(find.text('Inicio'), findsAtLeastNWidgets(1), reason: path);
    }
  });

  testWidgets('session changes refresh the router', (tester) async {
    final container = await _pumpApp(tester);

    expect(find.text('Iniciar sesión'), findsOneWidget);
    container
        .read(sessionProvider.notifier)
        .setSession(const Session(role: UserRole.reader));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsAtLeastNWidgets(1));
  });

  testWidgets('administrator can see and access integrations', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );

    expect(find.text('Integraciones'), findsOneWidget);
    container.read(appRouterProvider).go(RouteNames.integrationsPath);
    await tester.pumpAndSettle();

    expect(find.text('Funcionalidad en desarrollo'), findsOneWidget);
    expect(find.text('Integraciones'), findsNWidgets(2));
  });

  testWidgets('reader cannot see or access integrations', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );

    expect(find.text('Integraciones'), findsNothing);
    container.read(appRouterProvider).go(RouteNames.integrationsPath);
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsAtLeastNWidgets(1));
    expect(find.text('Integraciones'), findsNothing);
  });

  testWidgets('narrow layout uses bottom navigation without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester, session: const Session(role: UserRole.reader));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout uses navigation rail without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester, session: const Session(role: UserRole.reader));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Session? session,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.initialSession);

  final Session? initialSession;

  @override
  Session? build() => initialSession;
}
