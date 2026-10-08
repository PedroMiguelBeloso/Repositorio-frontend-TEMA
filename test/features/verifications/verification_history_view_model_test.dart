import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/verification_history_view_model.dart';

void main() {
  test(
    'loads API page data and resolves service/process names from M1',
    () async {
      final repository = _HistoryRepository(
        runsByPage: {
          0: PagedResult(
            items: [_run('run-1', 'service-1', 'version-1', 4, 10)],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 21,
              totalPages: 2,
            ),
          ),
        },
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container.read(verificationHistoryViewModelProvider.future);
      final state = container
          .read(verificationHistoryViewModelProvider)
          .requireValue;

      expect(repository.runRequests.single.page, 0);
      expect(repository.runRequests.single.size, 20);
      expect(repository.runRequests.single.serviceId, isNull);
      expect(state.items.single.id, 'run-1');
      expect(state.page.totalElements, 21);
      expect(state.page.totalPages, 2);
      expect(state.serviceFor(state.items.single)?.name, 'Servicio Alfa');
      expect(state.processFor(state.items.single)?.processName, 'Start Up');
      expect(state.processFor(state.items.single)?.officialVersion, '3.2');
    },
  );

  test('changes service filter and always resets to first page', () async {
    final repository = _HistoryRepository(
      runsByPage: {
        0: PagedResult(
          items: [_run('run-1', 'service-1', 'version-1', 4, 10)],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 41,
            totalPages: 3,
          ),
        ),
        1: PagedResult(
          items: [_run('run-page-2', 'service-1', 'version-1', 8, 10)],
          page: const PageInfo(
            page: 1,
            size: 20,
            totalElements: 41,
            totalPages: 3,
          ),
        ),
      },
      filteredResult: PagedResult(
        items: [_run('run-filtered', 'service-2', 'version-2', 2, 2)],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(verificationHistoryViewModelProvider.future);
    final vm = container.read(verificationHistoryViewModelProvider.notifier);

    await vm.goToPage(1);
    expect(repository.runRequests.last.page, 1);
    expect(
      container
          .read(verificationHistoryViewModelProvider)
          .requireValue
          .page
          .page,
      1,
    );

    await vm.selectService('service-2');
    var state = container
        .read(verificationHistoryViewModelProvider)
        .requireValue;
    expect(repository.runRequests.last.page, 0);
    expect(repository.runRequests.last.serviceId, 'service-2');
    expect(state.serviceId, 'service-2');
    expect(state.page.page, 0);
    expect(state.items.single.id, 'run-filtered');

    await vm.selectService(null);
    state = container.read(verificationHistoryViewModelProvider).requireValue;
    expect(repository.runRequests.last.page, 0);
    expect(repository.runRequests.last.serviceId, isNull);
    expect(state.serviceId, isNull);
  });

  test(
    'history still renders by ID when M1 service lookup is unavailable',
    () async {
      final repository = _HistoryRepository(
        runsByPage: {
          0: PagedResult(
            items: [_run('run-1', 'service-missing', 'version-missing', 1, 2)],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
            ),
          ),
        },
        failServiceLookup: true,
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container.read(verificationHistoryViewModelProvider.future);
      final state = container
          .read(verificationHistoryViewModelProvider)
          .requireValue;

      expect(state.items.single.id, 'run-1');
      expect(state.serviceFor(state.items.single), isNull);
      expect(state.processFor(state.items.single), isNull);
    },
  );

  test('retry reloads the last failed request', () async {
    final repository = _HistoryRepository(
      failNextRunRequest: true,
      runsByPage: {
        0: PagedResult(
          items: [_run('run-1', 'service-1', 'version-1', 4, 10)],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      },
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await expectLater(
      container.read(verificationHistoryViewModelProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(
      container.read(verificationHistoryViewModelProvider),
      isA<AsyncError<VerificationHistoryState>>(),
    );

    final vm = container.read(verificationHistoryViewModelProvider.notifier);
    await vm.retry();

    final state = container
        .read(verificationHistoryViewModelProvider)
        .requireValue;
    expect(state.items.single.id, 'run-1');
    expect(repository.runRequests.length, 2);
  });

  test(
    'refresh preserves service lookup data when only the M1 lookup fails',
    () async {
      final repository = _HistoryRepository(
        runsByPage: {
          0: PagedResult(
            items: [_run('run-1', 'service-1', 'version-1', 1, 10)],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
            ),
          ),
        },
        failServiceLookupOnRefresh: true,
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container.read(verificationHistoryViewModelProvider.future);
      final vm = container.read(verificationHistoryViewModelProvider.notifier);

      await vm.refresh();

      final refreshed = container
          .read(verificationHistoryViewModelProvider)
          .requireValue;
      expect(refreshed.services, _services);
      expect(refreshed.items.single.id, 'run-1');
    },
  );

  test('refresh keeps no local fake row and adopts the API response', () async {
    final refreshCompleter = Completer<PagedResult<VerificationRunSummary>>();
    final repository = _HistoryRepository(
      runsByPage: {
        0: PagedResult(
          items: [_run('run-1', 'service-1', 'version-1', 1, 10)],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      },
      refreshCompleter: refreshCompleter,
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(verificationHistoryViewModelProvider.future);
    final vm = container.read(verificationHistoryViewModelProvider.notifier);

    final refresh = vm.refresh();
    final refreshing = container
        .read(verificationHistoryViewModelProvider)
        .requireValue;
    expect(refreshing.isRefreshing, isTrue);
    expect(refreshing.items.single.id, 'run-1');

    refreshCompleter.complete(
      PagedResult(
        items: [_run('run-2', 'service-1', 'version-1', 5, 10)],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    await refresh;

    final refreshed = container
        .read(verificationHistoryViewModelProvider)
        .requireValue;
    expect(refreshed.isRefreshing, isFalse);
    expect(refreshed.items.map((run) => run.id), ['run-2']);
  });
}

ProviderContainer _createContainer(_HistoryRepository repository) {
  final container = ProviderContainer(
    overrides: [verificationRepositoryProvider.overrideWithValue(repository)],
  );
  final subscription = container.listen(
    verificationHistoryViewModelProvider,
    (_, _) {},
  );
  subscription.close();
  return container;
}

VerificationRunSummary _run(
  String id,
  String serviceId,
  String processVersionId,
  int processed,
  int total,
) {
  return VerificationRunSummary(
    id: id,
    serviceId: serviceId,
    processVersionId: processVersionId,
    scope: VerificationScope.process,
    status: VerificationRunStatus.running,
    progress: RunProgress.fromValues(total: total, processed: processed),
    startedAt: DateTime.utc(2026, 10, 7, 10, 15),
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

class _HistoryRepository implements VerificationRepository {
  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) => throw UnimplementedError();

  _HistoryRepository({
    required this.runsByPage,
    this.filteredResult,
    this.failNextRunRequest = false,
    this.failServiceLookup = false,
    this.failServiceLookupOnRefresh = false,
    this.refreshCompleter,
  });

  final Map<int, PagedResult<VerificationRunSummary>> runsByPage;
  final PagedResult<VerificationRunSummary>? filteredResult;
  final Completer<PagedResult<VerificationRunSummary>>? refreshCompleter;
  bool failNextRunRequest;
  final bool failServiceLookup;
  final bool failServiceLookupOnRefresh;
  int serviceCalls = 0;
  final List<_RunRequest> runRequests = [];

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
  }) async {
    serviceCalls++;
    if (failServiceLookup || (failServiceLookupOnRefresh && serviceCalls > 1)) {
      throw StateError('service catalog unavailable');
    }
    return PagedResult(
      items: page == 0 ? _services : const [],
      page: PageInfo(
        page: page,
        size: size,
        totalElements: _services.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) async {
    runRequests.add(_RunRequest(page: page, size: size, serviceId: serviceId));

    if (failNextRunRequest) {
      failNextRunRequest = false;
      throw StateError('history unavailable');
    }
    if (refreshCompleter != null && runRequests.length > 1) {
      return refreshCompleter!.future;
    }
    if (serviceId != null) return filteredResult!;
    return runsByPage[page]!;
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

class _RunRequest {
  const _RunRequest({
    required this.page,
    required this.size,
    required this.serviceId,
  });

  final int page;
  final int size;
  final String? serviceId;
}
