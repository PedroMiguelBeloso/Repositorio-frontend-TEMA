import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/app.dart';
import 'package:proyecto_tema_frontend/app/router/app_router.dart';
import 'package:proyecto_tema_frontend/app/router/route_names.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_status.dart';
import 'package:proyecto_tema_frontend/features/auth/model/auth_models.dart';
import 'package:proyecto_tema_frontend/features/processes/viewmodel/process_list_view_model.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart'
    hide ProcessStatus;
import 'package:proyecto_tema_frontend/features/services/viewmodel/service_list_view_model.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/new_verification_view_model.dart';
import 'package:proyecto_tema_frontend/features/users/data/dto/user_dtos.dart';
import 'package:proyecto_tema_frontend/features/users/data/user_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_structure_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_structure_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_structure_models.dart';

void main() {
  testWidgets('all configured authenticated routes resolve', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    final router = container.read(appRouterProvider);
    const routes = <(String, String, bool)>[
      (RouteNames.homePath, 'Inicio', false),
      (RouteNames.processesPath, 'Procesos', false),
      ('/processes/process-42', 'Detalle del proceso', false),
      ('/processes/process-42/history', 'Historial de versiones', false),
      (RouteNames.verificationsPath, 'Verificaciones', false),
      (RouteNames.newVerificationPath, 'Nueva verificación', false),
      ('/verifications/run-42', 'Detalle de verificación', true),
      ('/verifications/run-42/results', 'Resultados de verificación', true),
      (RouteNames.integrationsPath, 'Integraciones', false),
    ];

    for (final (path, title, isPlaceholder) in routes) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(title), findsAtLeastNWidgets(1), reason: path);
      expect(
        find.text('Funcionalidad en desarrollo'),
        isPlaceholder ? findsOneWidget : findsNothing,
        reason: path,
      );
    }
  });

  testWidgets('reader can inspect a draft structure without write controls', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.processStructure('process-42', 'version-42'));
    await tester.pumpAndSettle();

    expect(find.text('Estructura'), findsOneWidget);
    expect(find.text('Ticket con requerimiento'), findsOneWidget);
    expect(find.text('Agregar entrada'), findsNothing);
    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Editar evidencia'), findsNothing);
  });

  testWidgets('administrator adds a catalog entry to a draft input', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    container
        .read(appRouterProvider)
        .go(RouteNames.processStructure('process-42', 'version-42'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar entrada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ticket con requerimiento').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.text('Guardar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ticket con requerimiento'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('process-draft-save')));
    await tester.pumpAndSettle();

    expect(find.text('Borrador guardado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('administrator can access the services list', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.servicesPath);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.servicesPath,
    );
    expect(find.text('Servicios'), findsAtLeastNWidgets(1));
    expect(find.text('No hay servicios configurados.'), findsOneWidget);
    expect(find.text('Nuevo servicio'), findsAtLeastNWidgets(1));
  });

  testWidgets('reader can consult the services list without write actions', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.servicesPath);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.servicesPath,
    );
    expect(find.text('Servicios'), findsAtLeastNWidgets(1));
    expect(find.text('No hay servicios configurados.'), findsOneWidget);
    expect(find.text('Nuevo servicio'), findsNothing);
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

    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.loginPath,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);

    router.go(RouteNames.integrationsPath);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.loginPath,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Integraciones'), findsNothing);

    router.go(RouteNames.newVerificationPath);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.loginPath,
    );
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

  testWidgets('reader is redirected from service edit', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );
    final router = container.read(appRouterProvider);

    router.go(RouteNames.serviceEdit('service-42'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RouteNames.homePath);
    expect(find.text('Editar servicio'), findsNothing);
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

  testWidgets('account menu opens password settings and logs out', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.reader),
    );

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Cambiar mi contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider), isNull);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('administrator can see and access integrations', (tester) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );

    expect(find.text('Integraciones'), findsOneWidget);
    container.read(appRouterProvider).go(RouteNames.integrationsPath);
    await tester.pumpAndSettle();

    expect(find.text('Verificar de nuevo'), findsOneWidget);
    expect(find.text('Sin información'), findsNWidgets(2));
    expect(find.text('Integraciones'), findsNWidgets(2));
  });

  testWidgets('administrator can reach reader creation from navigation', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      RouteNames.usersPath,
    );
    expect(find.text('Gestión de usuarios'), findsOneWidget);
    expect(find.text('Rol: Lector'), findsOneWidget);
    expect(find.textContaining('READER'), findsNothing);

    await tester.tap(find.text('Crear Lector'));
    await tester.pumpAndSettle();
    expect(find.text('Crear Usuario Lector'), findsOneWidget);
    expect(find.text('Nombre visible'), findsOneWidget);
    expect(find.text('Contraseña inicial'), findsOneWidget);
  });

  testWidgets('reader does not see user management', (tester) async {
    await _pumpApp(tester, session: const Session(role: UserRole.reader));
    expect(find.text('Usuarios'), findsNothing);
  });

  testWidgets('wide user list has columns and reader form stays narrow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _pumpApp(
      tester,
      session: const Session(role: UserRole.administrator),
    );
    final router = container.read(appRouterProvider);
    router.go(RouteNames.usersPath);
    await tester.pumpAndSettle();

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Rol'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Lector'), findsOneWidget);

    router.go(RouteNames.createReaderPath);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(TextFormField).first).width,
      lessThanOrEqualTo(640),
    );
    expect(tester.takeException(), isNull);
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

  testWidgets(
    'narrow administrator layout fits account menu and destinations',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpApp(
        tester,
        session: const Session(role: UserRole.administrator),
      );

      expect(find.byTooltip('Perfil'), findsOneWidget);
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byKey(const Key('account-menu-panel'))).dx,
        lessThanOrEqualTo(360),
      );
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(tester.getTopLeft(find.byTooltip('Perfil')).dy, greaterThan(650));
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byKey(const Key('account-menu-panel'))).dy,
      lessThan(tester.getTopLeft(find.byTooltip('Perfil')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact rail keeps account menu inside the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester, session: const Session(role: UserRole.reader));
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('account-menu-panel'))).dx,
      greaterThanOrEqualTo(0),
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestNewVerificationViewModel extends NewVerificationViewModel {
  @override
  Future<NewVerificationState> build() async =>
      const NewVerificationState(services: []);
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Session? session,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
        serviceListViewModelProvider.overrideWith(
          _TestServiceListViewModel.new,
        ),
        newVerificationViewModelProvider.overrideWith(
          _TestNewVerificationViewModel.new,
        ),
        processStructureRepositoryProvider.overrideWithValue(
          _TestProcessRepository(),
        ),
        processListViewModelProvider.overrideWith(
          _TestProcessListViewModel.new,
        ),
        integrationsRepositoryProvider.overrideWithValue(
          _TestIntegrationsRepository(),
        ),
        userRepositoryProvider.overrideWithValue(_TestUserRepository()),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

class _TestProcessListViewModel extends ProcessListViewModel {
  @override
  Future<ProcessListState> build() async => const ProcessListState(items: []);
}

class _TestIntegrationsRepository implements IntegrationsRepository {
  @override
  Future<List<IntegrationStatus>> loadStatuses() async => const [];

  @override
  Future<List<IntegrationStatus>> testIntegrations() async => const [];
}

class _TestUserRepository implements UserRepository {
  @override
  Future<PaginatedUsers> listUsers(int page, int size) async => PaginatedUsers(
    items: [
      User(
        id: 'reader-1',
        email: 'lector@tema.local',
        displayName: 'Lector de prueba',
        role: Role.reader,
        active: true,
      ),
    ],
  );

  @override
  Future<User> createReader(CreateReaderRequest request) async => User(
    id: 'reader-1',
    email: request.email,
    displayName: request.displayName,
    role: Role.reader,
    active: true,
  );
}

class _TestServiceListViewModel extends ServiceListViewModel {
  @override
  Future<ServiceListState> build() async => ServiceListState(
    items: const [],
    page: const PageInfo(page: 0, size: 20, totalElements: 0, totalPages: 0),
  );
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.initialSession);

  final Session? initialSession;

  @override
  Session? build() => initialSession;
}

class _TestProcessRepository implements ProcessStructureRepository {
  static const _ticket = RegistryDefinition(
    id: 'registry-ticket',
    key: 'ticket',
    canonicalName: 'Ticket con requerimiento',
    evidenceType: EvidenceType.ticket,
    preloaded: true,
  );

  static final _draft = ProcessVersionDraft(
    id: 'version-42',
    processId: 'process-42',
    officialVersion: '1.0',
    versionDate: DateTime(2026, 10, 1),
    status: ProcessStatus.draft,
    revision: 2,
    objective: 'Gestionar requerimientos.',
    owner: 'Responsable de Operaciones',
    policies: const [],
    macroActivities: const [
      MacroActivityDraft(
        id: 'macro-42',
        name: 'Gestionar requerimiento',
        order: 0,
        inputs: [
          EvidenceExpectation(
            id: 'evidence-42',
            registryDefinitionId: 'registry-ticket',
            registryDefinition: _ticket,
            order: 0,
          ),
        ],
        activities: [
          ActivityDraft(
            id: 'activity-42',
            name: 'Resolver',
            instructions: 'Resolver el requerimiento.',
            order: 0,
          ),
        ],
      ),
    ],
  );

  @override
  Future<ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  }) async => _draft;

  @override
  Future<ProcessVersionDraft> saveDraft(
    ProcessVersionDraft draft,
    List<RegistryDefinition> definitions,
  ) async => draft.copyWith(revision: draft.revision + 1);

  @override
  Future<ProcessPage<RegistryDefinition>> searchRegistry({
    required String query,
    required int page,
    required int size,
  }) async => const ProcessPage(items: [_ticket], page: 0, totalPages: 1);

  @override
  Future<RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) async => RegistryDefinition(
    id: 'created',
    key: 'generated',
    canonicalName: canonicalName,
    evidenceType: evidenceType,
    officialNomenclature: officialNomenclature,
    preloaded: false,
  );

  @override
  Future<ProcessDefinition> getProcess(String processId) async =>
      const ProcessDefinition(
        id: 'process-42',
        code: 'SUPPORT_SOFTWARE_FACTORY',
        name: 'Soporte y Software Factory',
        m2Enabled: true,
      );

  @override
  Future<ProcessPage<ProcessDefinition>> listProcesses({
    required int page,
    required int size,
  }) async => const ProcessPage(
    items: [
      ProcessDefinition(
        id: 'process-42',
        code: 'SUPPORT_SOFTWARE_FACTORY',
        name: 'Soporte y Software Factory',
        m2Enabled: true,
      ),
    ],
    page: 0,
    totalPages: 1,
  );

  @override
  Future<ProcessPage<ProcessVersionSummary>> listVersions({
    required String processId,
    required int page,
    required int size,
  }) async => ProcessPage(
    items: [
      ProcessVersionSummary(
        id: 'version-42',
        processId: 'process-42',
        officialVersion: '1.0',
        versionDate: DateTime(2026, 10, 1),
        status: ProcessStatus.draft,
        revision: 2,
      ),
    ],
    page: 0,
    totalPages: 1,
  );
}
