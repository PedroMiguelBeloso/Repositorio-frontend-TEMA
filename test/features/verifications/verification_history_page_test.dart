import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/verification_history_page.dart';

void main() {
  testWidgets('shows API counts, four translated statuses and pagination', (
    tester,
  ) async {
    final repository = _HistoryRepository(
      page0: PagedResult(
        items: [
          _run('run-queued', VerificationRunStatus.queued, 0, 10),
          _run('run-running', VerificationRunStatus.running, 4, 10),
          _run('run-completed', VerificationRunStatus.completed, 10, 10),
          _run('run-failed', VerificationRunStatus.failed, 7, 10),
        ],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 42,
          totalPages: 3,
        ),
      ),
      page1: PagedResult(
        items: [_run('run-page-2', VerificationRunStatus.running, 2, 5)],
        page: const PageInfo(
          page: 1,
          size: 20,
          totalElements: 42,
          totalPages: 3,
        ),
      ),
    );
    final router = await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.administrator),
    );

    expect(find.text('42 ejecuciones'), findsOneWidget);
    expect(find.text('En espera'), findsOneWidget);
    expect(find.text('En curso'), findsNWidgets(1));
    expect(find.text('Finalizada'), findsOneWidget);
    expect(find.text('Fallida'), findsOneWidget);
    expect(find.text('4 de 10'), findsOneWidget);
    expect(find.text('10 de 10'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Servicio Alfa'), findsAtLeastNWidgets(1));
    expect(find.text('Start Up · versión 3.2'), findsAtLeastNWidgets(1));

    final nextPageButton = find.byKey(
      const ValueKey('verification-history-next-page'),
    );
    await _scrollHistoryToVisible(tester, nextPageButton);
    expect(tester.widget<IconButton>(nextPageButton).onPressed, isNotNull);
    await tester.tap(nextPageButton);
    await tester.pumpAndSettle();

    expect(repository.lastRunPage, 1);
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(find.text('run-page-2'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/verifications');
  });

  testWidgets('administrator sees new verification action on empty history', (
    tester,
  ) async {
    final repository = _HistoryRepository(page0: _emptyPage);
    await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.administrator),
    );

    expect(find.text('Nueva verificación'), findsOneWidget);
    expect(
      find.text('No hay ejecuciones de verificación para mostrar.'),
      findsOneWidget,
    );
  });

  testWidgets('reader does not see new verification action on empty history', (
    tester,
  ) async {
    final repository = _HistoryRepository(page0: _emptyPage);
    await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.reader),
    );

    expect(find.text('Nueva verificación'), findsNothing);
    expect(
      find.text('No hay ejecuciones de verificación para mostrar.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'selecting and clearing service filter sends serviceId and resets page',
    (tester) async {
      final repository = _HistoryRepository(
        page0: PagedResult(
          items: [_run('run-all', VerificationRunStatus.running, 1, 2)],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 21,
            totalPages: 2,
          ),
        ),
        page1: PagedResult(
          items: [_run('run-page-2', VerificationRunStatus.running, 2, 2)],
          page: const PageInfo(
            page: 1,
            size: 20,
            totalElements: 21,
            totalPages: 2,
          ),
        ),
        filteredPage0: PagedResult(
          items: [_run('run-filtered', VerificationRunStatus.completed, 2, 2)],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      );
      await _pumpHistoryPage(
        tester,
        repository,
        const Session(role: UserRole.administrator),
      );

      final nextPageButton = find.byKey(
        const ValueKey('verification-history-next-page'),
      );
      await _scrollHistoryToVisible(tester, nextPageButton);
      expect(tester.widget<IconButton>(nextPageButton).onPressed, isNotNull);
      await tester.tap(nextPageButton);
      await tester.pumpAndSettle();

      expect(repository.lastRunPage, 1);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Servicio Beta').last);
      await tester.pumpAndSettle();

      expect(repository.lastRunPage, 0);
      expect(repository.lastRunServiceId, 'service-2');
      expect(find.text('run-filtered'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos los servicios').last);
      await tester.pumpAndSettle();

      expect(repository.lastRunPage, 0);
      expect(repository.lastRunServiceId, isNull);
      expect(find.text('run-all'), findsOneWidget);
    },
  );

  testWidgets('a run opens its own runId and preserves API order', (
    tester,
  ) async {
    final repository = _HistoryRepository(
      page0: PagedResult(
        items: [
          _run('first-run', VerificationRunStatus.completed, 10, 10),
          _run('second-run', VerificationRunStatus.failed, 3, 10),
        ],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 2,
          totalPages: 1,
        ),
      ),
    );
    final router = await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.reader),
    );

    final firstIndex = tester.getTopLeft(find.text('first-run')).dy;
    final secondIndex = tester.getTopLeft(find.text('second-run')).dy;
    expect(firstIndex, lessThan(secondIndex));

    final secondRunCard = find.byKey(
      const ValueKey('verification-run-second-run'),
    );
    await _scrollHistoryToVisible(tester, secondRunCard);
    await tester.tap(secondRunCard);
    await tester.pumpAndSettle();

    expect(find.text('runId: second-run'), findsOneWidget);
    expect(router.state.uri.path, '/verifications/second-run');
  });

  testWidgets('loading, error and retry use shared async feedback', (
    tester,
  ) async {
    final repository = _HistoryRepository(
      page0: PagedResult(
        items: [_run('run-1', VerificationRunStatus.running, 1, 3)],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
      failFirstHistoryRequest: true,
    );
    await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.reader),
    );

    expect(
      find.text('No se pudo cargar el historial de verificaciones.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('run-1'), findsOneWidget);
    expect(repository.historyCalls, 2);
  });

  testWidgets('desktop and mobile layouts stay within bounds', (tester) async {
    final repository = _HistoryRepository(
      page0: PagedResult(
        items: [
          _run('run-1', VerificationRunStatus.running, 6, 10),
          _run('run-2', VerificationRunStatus.completed, 10, 10),
        ],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 2,
          totalPages: 1,
        ),
      ),
    );

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHistoryPage(
      tester,
      repository,
      const Session(role: UserRole.reader),
    );

    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

final _emptyPage = PagedResult<VerificationRunSummary>(
  items: const [],
  page: const PageInfo(page: 0, size: 20, totalElements: 0, totalPages: 0),
);

VerificationRunSummary _run(
  String id,
  VerificationRunStatus status,
  int processed,
  int total,
) {
  return VerificationRunSummary(
    id: id,
    serviceId: id == 'run-filtered' ? 'service-2' : 'service-1',
    processVersionId: id == 'run-filtered' ? 'version-2' : 'version-1',
    scope: VerificationScope.process,
    status: status,
    progress: RunProgress.fromValues(total: total, processed: processed),
    startedAt: DateTime.utc(2026, 10, 7, 10, 15),
  );
}

Future<void> _scrollHistoryToVisible(WidgetTester tester, Finder target) async {
  final historyList = find.byType(ListView).first;

  for (var attempt = 0; attempt < 10; attempt++) {
    final targetRect = tester.getRect(target);
    final viewportRect = tester.getRect(historyList);

    if (targetRect.top >= viewportRect.top &&
        targetRect.bottom <= viewportRect.bottom) {
      return;
    }

    await tester.drag(historyList, const Offset(0, -400));
    await tester.pumpAndSettle();
  }

  final targetRect = tester.getRect(target);
  final viewportRect = tester.getRect(historyList);
  expect(
    targetRect.top,
    greaterThanOrEqualTo(viewportRect.top),
    reason: 'El elemento objetivo debe quedar visible dentro del ListView del historial.',
  );
  expect(
    targetRect.bottom,
    lessThanOrEqualTo(viewportRect.bottom),
    reason: 'El elemento objetivo debe quedar visible dentro del ListView del historial.',
  );
}

final _services = [
  Service(
    id: 'service-1',
    name: 'Servicio Alfa',
    client: 'Cliente',
    serviceType: ServiceType.supportErp,
    status: ServiceStatus.active,
    revision: 1,
    processes: const [
      ServiceProcess(
        processVersionId: 'version-1',
        processId: 'process-1',
        processName: 'Start Up',
        officialVersion: '3.2',
        m2Enabled: true,
      ),
    ],
    sources: const ServiceSource(),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Service(
    id: 'service-2',
    name: 'Servicio Beta',
    client: 'Cliente',
    serviceType: ServiceType.softwareFactory,
    status: ServiceStatus.active,
    revision: 1,
    processes: const [
      ServiceProcess(
        processVersionId: 'version-2',
        processId: 'process-2',
        processName: 'Take Over',
        officialVersion: '1.5',
        m2Enabled: true,
      ),
    ],
    sources: const ServiceSource(),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

Future<GoRouter> _pumpHistoryPage(
  WidgetTester tester,
  _HistoryRepository repository,
  Session session,
) async {
  final router = GoRouter(
    initialLocation: '/verifications',
    routes: [
      GoRoute(
        path: '/verifications',
        builder: (context, state) => const VerificationHistoryPage(),
      ),
      GoRoute(
        path: '/verifications/:runId',
        builder: (context, state) =>
            Text('runId: ${state.pathParameters['runId']}'),
      ),
      GoRoute(
        path: '/verifications/new',
        builder: (context, state) => const Text('Nueva verification test'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
        verificationRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.initialSession);

  final Session initialSession;

  @override
  Session? build() => initialSession;
}

class _HistoryRepository implements VerificationRepository {
  @override
  Future<VerificationResult> decideResult({
    required String runId,
    required String resultId,
    required int revision,
    required VerificationResultStatus finalStatus,
    required String rationale,
  }) => throw UnimplementedError();

  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) => throw UnimplementedError();

  _HistoryRepository({
    required this.page0,
    this.page1,
    this.filteredPage0,
    this.failFirstHistoryRequest = false,
  });

  final PagedResult<VerificationRunSummary> page0;
  final PagedResult<VerificationRunSummary>? page1;
  final PagedResult<VerificationRunSummary>? filteredPage0;
  bool failFirstHistoryRequest;
  int historyCalls = 0;
  int lastRunPage = 0;
  String? lastRunServiceId;

  @override
  Future<VerificationRun> getVerification(String runId) async =>
      throw UnimplementedError();

  @override
  Future<PagedResult<VerificationResult>> listResults({
    required String runId,
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) async => PagedResult(
    items: page == 0 ? _services : const [],
    page: PageInfo(
      page: page,
      size: size,
      totalElements: _services.length,
      totalPages: 1,
    ),
  );

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) async {
    historyCalls++;
    lastRunPage = page;
    lastRunServiceId = serviceId;
    if (failFirstHistoryRequest) {
      failFirstHistoryRequest = false;
      throw StateError('history unavailable');
    }
    if (serviceId != null) return filteredPage0 ?? _emptyPage;
    return page == 1 ? page1 ?? page0 : page0;
  }

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId) async =>
      const [];

  @override
  Future<VerificationPreview> preview(VerificationTarget target) async =>
      throw UnimplementedError();

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) async => throw UnimplementedError();

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) async => throw UnimplementedError();
}
