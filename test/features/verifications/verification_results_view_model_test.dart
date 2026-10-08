import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart' as process_models;
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver_provider.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/verification_results_view_model.dart';

void main() {
  test('loads execution first and then results only when completed', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {0: _page(0, ['result-1'], totalPages: 2)},
    );
    final container = _createContainer(repository, 'run-1');
    addTearDown(container.dispose);

    await container.read(verificationResultsViewModelProvider('run-1').future);
    final state = container
        .read(verificationResultsViewModelProvider('run-1'))
        .requireValue;

    expect(repository.calls, ['GET run', 'GET results page=0 size=20']);
    expect(state.run.status, VerificationRunStatus.completed);
    expect(state.items.single.id, 'result-1');
    expect(state.page?.totalPages, 2);
    expect(state.page?.totalElements, 21);
  });

  test('does not query results for a queued execution', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.queued),
    );
    final container = _createContainer(repository, 'run-queued');
    addTearDown(container.dispose);

    await container.read(verificationResultsViewModelProvider('run-queued').future);
    final state = container
        .read(verificationResultsViewModelProvider('run-queued'))
        .requireValue;

    expect(repository.calls, ['GET run']);
    expect(state.items, isEmpty);
    expect(state.page, isNull);
  });

  test('does not show an empty result page for a failed execution', () async {
    final repository = _ResultsRepository(
      run: _run(
        VerificationRunStatus.failed,
        failureMessage: 'No se pudo consultar Redmine.',
      ),
    );
    final container = _createContainer(repository, 'run-failed');
    addTearDown(container.dispose);

    await container.read(verificationResultsViewModelProvider('run-failed').future);
    final state = container
        .read(verificationResultsViewModelProvider('run-failed'))
        .requireValue;

    expect(repository.calls, ['GET run']);
    expect(state.run.failureMessage, 'No se pudo consultar Redmine.');
    expect(state.items, isEmpty);
    expect(state.page, isNull);
  });

  test('changes page using API totals and clears only the open result', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {
        0: _page(0, ['result-1'], totalPages: 3),
        1: _page(1, ['result-2'], totalPages: 3),
      },
    );
    final container = _createContainer(repository, 'run-paged');
    addTearDown(container.dispose);

    await container.read(verificationResultsViewModelProvider('run-paged').future);
    final viewModel = container.read(
      verificationResultsViewModelProvider('run-paged').notifier,
    );
    viewModel.toggleResult('result-1');
    expect(
      container
          .read(verificationResultsViewModelProvider('run-paged'))
          .requireValue
          .selectedResultId,
      'result-1',
    );

    await viewModel.goToPage(1);
    final state = container
        .read(verificationResultsViewModelProvider('run-paged'))
        .requireValue;

    expect(repository.calls.last, 'GET results page=1 size=20');
    expect(state.page?.page, 1);
    expect(state.page?.totalPages, 3);
    expect(state.items.single.id, 'result-2');
    expect(state.selectedResultId, isNull);
  });

  test('keeps the execution context and offers retry when results fail', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {0: _page(0, ['result-1'], totalPages: 1)},
      failNextResultsRequest: true,
    );
    final container = _createContainer(repository, 'run-retry');
    addTearDown(container.dispose);

    await container.read(verificationResultsViewModelProvider('run-retry').future);
    var state = container
        .read(verificationResultsViewModelProvider('run-retry'))
        .requireValue;

    expect(state.run.id, 'run-1');
    expect(state.items, isEmpty);
    expect(state.resultsFailure, isNotNull);
    expect(state.resultsFailure!.message, contains('No se pudieron cargar'));

    final viewModel = container.read(
      verificationResultsViewModelProvider('run-retry').notifier,
    );
    await viewModel.retry();
    state = container
        .read(verificationResultsViewModelProvider('run-retry'))
        .requireValue;

    expect(state.run.id, 'run-1');
    expect(state.items.single.id, 'result-1');
    expect(state.resultsFailure, isNull);
    expect(repository.calls, [
      'GET run',
      'GET results page=0 size=20',
      'GET run',
      'GET results page=0 size=20',
    ]);
  });

  test('retries the requested page after a pagination failure', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {
        0: _page(0, ['result-1'], totalPages: 3),
        1: _page(1, ['result-2'], totalPages: 3),
      },
    );
    final container = _createContainer(repository, 'run-paged-retry');
    addTearDown(container.dispose);

    await container.read(
      verificationResultsViewModelProvider('run-paged-retry').future,
    );
    final viewModel = container.read(
      verificationResultsViewModelProvider('run-paged-retry').notifier,
    );

    repository.failNextResultsRequest = true;
    await viewModel.goToPage(1);
    var state = container
        .read(verificationResultsViewModelProvider('run-paged-retry'))
        .requireValue;
    expect(state.page?.page, 0);
    expect(state.resultsFailure, isNotNull);

    await viewModel.retry();
    state = container
        .read(verificationResultsViewModelProvider('run-paged-retry'))
        .requireValue;
    expect(state.page?.page, 1);
    expect(state.items.single.id, 'result-2');
    expect(state.resultsFailure, isNull);
    expect(repository.calls, [
      'GET run',
      'GET results page=0 size=20',
      'GET results page=1 size=20',
      'GET run',
      'GET results page=1 size=20',
    ]);
  });
}

ProviderContainer _createContainer(
  _ResultsRepository repository,
  String runId,
) {
  final container = ProviderContainer(
    overrides: [
      verificationRepositoryProvider.overrideWithValue(repository),
      verificationResultLocationResolverProvider.overrideWithValue(
        _NoOpLocationResolver(),
      ),
    ],
  );
  container.listen(
    verificationResultsViewModelProvider(runId),
    (_, _) {},
  );
  return container;
}

VerificationRun _run(
  VerificationRunStatus status, {
  String? failureMessage,
}) {
  return VerificationRun(
    id: 'run-1',
    serviceId: 'service-1',
    processVersionId: 'version-1',
    scope: VerificationScope.process,
    status: status,
    progress: RunProgress.fromValues(total: 2, processed: 2),
    startedAt: DateTime.utc(2026, 10, 8, 10),
    failureMessage: failureMessage,
  );
}

PagedResult<VerificationResult> _page(
  int page,
  List<String> ids, {
  required int totalPages,
}) {
  return PagedResult(
    items: [for (final id in ids) _result(id)],
    page: PageInfo(
      page: page,
      size: 20,
      totalElements: (totalPages - 1) * 20 + 1,
      totalPages: totalPages,
    ),
  );
}

VerificationResult _result(String id) {
  return VerificationResult(
    id: id,
    runId: 'run-1',
    expectationId: 'expectation-$id',
    macroActivityId: 'macro-1',
    activityId: 'activity-1',
    displayName: 'Ticket actualizado',
    evidenceType: process_models.EvidenceType.ticket,
    location: process_models.EvidenceLocation.activityRecord,
    subjectTicketId: id == 'result-1' ? '204' : '205',
    applicability: ApplicabilityAssessment(
      decision: ApplicabilityDecision.applies,
      origin: DecisionOrigin.deterministic,
      rationale: 'La evidencia aplica al alcance seleccionado.',
      limitations: const [],
    ),
    proposedStatus: VerificationResultStatus.complies,
    effectiveStatus: VerificationResultStatus.complies,
    rationale: 'El ticket contiene el registro esperado.',
    limitations: const [],
    evidence: const [],
    humanDecisions: const [],
    revision: 0,
  );
}

class _NoOpLocationResolver implements VerificationResultLocationResolver {
  @override
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  }) async => const {};
}

class _ResultsRepository implements VerificationRepository {
  _ResultsRepository({
    required this.run,
    this.pages = const {},
    this.failNextResultsRequest = false,
  });

  final VerificationRun run;
  final Map<int, PagedResult<VerificationResult>> pages;
  bool failNextResultsRequest;
  final List<String> calls = [];

  @override
  Future<VerificationRun> getVerification(String runId) async {
    calls.add('GET run');
    return run;
  }

  @override
  Future<PagedResult<VerificationResult>> listResults({
    required String runId,
    required int page,
    required int size,
  }) async {
    calls.add('GET results page=$page size=$size');
    if (failNextResultsRequest) {
      failNextResultsRequest = false;
      throw StateError('results unavailable');
    }
    return pages[page]!;
  }

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) => throw UnimplementedError();

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId) =>
      throw UnimplementedError();

  @override
  Future<VerificationPreview> preview(VerificationTarget target) =>
      throw UnimplementedError();

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) => throw UnimplementedError();

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) => throw UnimplementedError();
}
