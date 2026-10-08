import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart'
    as evidence_model;
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart'
    as process_models;
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver_provider.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/verification_results_view_model.dart';

void main() {
  test(
    'admin corrects one ticket and preserves the other ticket result',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: _page(0, ['result-1', 'result-2'], totalPages: 1),
        },
      );
      final container = _createContainer(repository, 'run-1', admin: true);
      addTearDown(container.dispose);
      await container.read(
        verificationResultsViewModelProvider('run-1').future,
      );
      final viewModel = container.read(
        verificationResultsViewModelProvider('run-1').notifier,
      );
      viewModel.toggleResult('result-1');

      final updated = await viewModel.decideResult(
        resultId: 'result-1',
        finalStatus: VerificationResultStatus.doesNotComply,
        rationale: '  Falta validación del cliente.  ',
      );
      final state = container
          .read(verificationResultsViewModelProvider('run-1'))
          .requireValue;
      expect(repository.statusDecisionResultIds, ['result-1']);
      expect(repository.statusDecisionRevision, 0);
      expect(
        repository.statusDecisionRationale,
        'Falta validación del cliente.',
      );
      expect(updated.proposedStatus, VerificationResultStatus.complies);
      expect(
        state.items.first.effectiveStatus,
        VerificationResultStatus.doesNotComply,
      );
      expect(
        state.items.last.effectiveStatus,
        VerificationResultStatus.complies,
      );
      expect(state.selectedResultId, 'result-1');
      expect(
        state.items.first.humanDecisions.single.decisionType,
        HumanDecisionType.resultStatus,
      );
    },
  );

  test(
    'reader, pending applicability and invalid No aplica are rejected',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: _page(0, ['result-1'], totalPages: 1),
        },
      );
      final reader = _createContainer(repository, 'run-1');
      addTearDown(reader.dispose);
      await reader.read(verificationResultsViewModelProvider('run-1').future);
      await expectLater(
        reader
            .read(verificationResultsViewModelProvider('run-1').notifier)
            .decideResult(
              resultId: 'result-1',
              finalStatus: VerificationResultStatus.complies,
              rationale: 'Confirmado.',
            ),
        throwsA(isA<PermissionFailure>()),
      );

      final admin = _createContainer(repository, 'run-1', admin: true);
      addTearDown(admin.dispose);
      await admin.read(verificationResultsViewModelProvider('run-1').future);
      await expectLater(
        admin
            .read(verificationResultsViewModelProvider('run-1').notifier)
            .decideResult(
              resultId: 'result-1',
              finalStatus: VerificationResultStatus.notApplicable,
              rationale: 'No aplica.',
            ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.statusDecisionResultIds, isEmpty);

      final pendingRepository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: PagedResult(
            items: [_pendingResult('result-1')],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
            ),
          ),
        },
      );
      final pending = _createContainer(
        pendingRepository,
        'run-1',
        admin: true,
        resolver: _CaseDependentResolver(),
      );
      addTearDown(pending.dispose);
      await pending.read(verificationResultsViewModelProvider('run-1').future);
      await expectLater(
        pending
            .read(verificationResultsViewModelProvider('run-1').notifier)
            .decideResult(
              resultId: 'result-1',
              finalStatus: VerificationResultStatus.complies,
              rationale: 'Confirmado.',
            ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(pendingRepository.statusDecisionResultIds, isEmpty);
    },
  );

  test('status decision conflict refreshes without resubmitting', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {
        0: _page(0, ['result-1'], totalPages: 1),
      },
      rejectStatusDecisionAsConflict: true,
    );
    final container = _createContainer(repository, 'run-1', admin: true);
    addTearDown(container.dispose);
    await container.read(verificationResultsViewModelProvider('run-1').future);
    await expectLater(
      container
          .read(verificationResultsViewModelProvider('run-1').notifier)
          .decideResult(
            resultId: 'result-1',
            finalStatus: VerificationResultStatus.doesNotComply,
            rationale: 'Falta evidencia.',
          ),
      throwsA(isA<ConflictFailure>()),
    );
    expect(repository.statusDecisionResultIds, ['result-1']);
    expect(repository.calls.where((call) => call == 'GET run').length, 2);
    expect(
      container
          .read(verificationResultsViewModelProvider('run-1'))
          .requireValue
          .isDecidingResult,
      isFalse,
    );
  });
  test(
    'admin resolves one ticket without replacing another ticket result',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: PagedResult(
            items: [_pendingResult('result-1'), _pendingResult('result-2')],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 2,
              totalPages: 1,
            ),
          ),
        },
      );
      final container = _createContainer(
        repository,
        'run-1',
        admin: true,
        resolver: _CaseDependentResolver(),
      );
      addTearDown(container.dispose);
      await container.read(
        verificationResultsViewModelProvider('run-1').future,
      );
      await Future<void>.delayed(Duration.zero);

      final viewModel = container.read(
        verificationResultsViewModelProvider('run-1').notifier,
      );
      viewModel.toggleResult('result-1');
      final updated = await viewModel.resolveApplicability(
        resultId: 'result-1',
        decision: HumanApplicabilityDecision.notApplicable,
        rationale: '  No hubo desarrollo.  ',
      );
      final state = container
          .read(verificationResultsViewModelProvider('run-1'))
          .requireValue;
      expect(repository.resolvedResultIds, ['result-1']);
      expect(repository.resolvedRevision, 0);
      expect(repository.resolvedRationale, 'No hubo desarrollo.');
      expect(updated.effectiveStatus, VerificationResultStatus.notApplicable);
      expect(
        state.items.first.effectiveStatus,
        VerificationResultStatus.notApplicable,
      );
      expect(
        state.items.last.applicability.decision,
        ApplicabilityDecision.undetermined,
      );
      expect(state.selectedResultId, 'result-1');
      expect(
        state.items.first.humanDecisions.single.decisionType,
        HumanDecisionType.applicability,
      );
    },
  );

  test(
    'reader and unconfirmed process mode cannot submit a decision',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: PagedResult(
            items: [_pendingResult('result-1')],
            page: const PageInfo(
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
            ),
          ),
        },
      );
      final reader = _createContainer(
        repository,
        'run-1',
        resolver: _CaseDependentResolver(),
      );
      addTearDown(reader.dispose);
      await reader.read(verificationResultsViewModelProvider('run-1').future);
      await expectLater(
        reader
            .read(verificationResultsViewModelProvider('run-1').notifier)
            .resolveApplicability(
              resultId: 'result-1',
              decision: HumanApplicabilityDecision.applies,
              rationale: 'Aplica.',
            ),
        throwsA(isA<PermissionFailure>()),
      );
      final unknownMode = _createContainer(repository, 'run-1', admin: true);
      addTearDown(unknownMode.dispose);
      await unknownMode.read(
        verificationResultsViewModelProvider('run-1').future,
      );
      await expectLater(
        unknownMode
            .read(verificationResultsViewModelProvider('run-1').notifier)
            .resolveApplicability(
              resultId: 'result-1',
              decision: HumanApplicabilityDecision.applies,
              rationale: 'Aplica.',
            ),
        throwsA(isA<ConflictFailure>()),
      );
      expect(repository.resolvedResultIds, isEmpty);
    },
  );
  test('a stale revision refreshes the result without resubmitting', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {
        0: PagedResult(
          items: [_pendingResult('result-1')],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      },
      rejectApplicabilityAsConflict: true,
    );
    final container = _createContainer(
      repository,
      'run-1',
      admin: true,
      resolver: _CaseDependentResolver(),
    );
    addTearDown(container.dispose);
    await container.read(verificationResultsViewModelProvider('run-1').future);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      container
          .read(verificationResultsViewModelProvider('run-1').notifier)
          .resolveApplicability(
            resultId: 'result-1',
            decision: HumanApplicabilityDecision.applies,
            rationale: 'Hubo desarrollo.',
          ),
      throwsA(isA<ConflictFailure>()),
    );
    expect(repository.resolvedResultIds, ['result-1']);
    expect(repository.calls.where((call) => call == 'GET run').length, 2);
    expect(
      container
          .read(verificationResultsViewModelProvider('run-1'))
          .requireValue
          .isResolvingApplicability,
      isFalse,
    );
  });
  test('loads execution first and then results only when completed', () async {
    final repository = _ResultsRepository(
      run: _run(VerificationRunStatus.completed),
      pages: {
        0: _page(0, ['result-1'], totalPages: 2),
      },
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

    await container.read(
      verificationResultsViewModelProvider('run-queued').future,
    );
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

    await container.read(
      verificationResultsViewModelProvider('run-failed').future,
    );
    final state = container
        .read(verificationResultsViewModelProvider('run-failed'))
        .requireValue;

    expect(repository.calls, ['GET run']);
    expect(state.run.failureMessage, 'No se pudo consultar Redmine.');
    expect(state.items, isEmpty);
    expect(state.page, isNull);
  });

  test(
    'changes page using API totals and clears only the open result',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: _page(0, ['result-1'], totalPages: 3),
          1: _page(1, ['result-2'], totalPages: 3),
        },
      );
      final container = _createContainer(repository, 'run-paged');
      addTearDown(container.dispose);

      await container.read(
        verificationResultsViewModelProvider('run-paged').future,
      );
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
    },
  );

  test(
    'keeps the execution context and offers retry when results fail',
    () async {
      final repository = _ResultsRepository(
        run: _run(VerificationRunStatus.completed),
        pages: {
          0: _page(0, ['result-1'], totalPages: 1),
        },
        failNextResultsRequest: true,
      );
      final container = _createContainer(repository, 'run-retry');
      addTearDown(container.dispose);

      await container.read(
        verificationResultsViewModelProvider('run-retry').future,
      );
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
    },
  );

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
  String runId, {
  bool admin = false,
  VerificationResultLocationResolver? resolver,
}) {
  final container = ProviderContainer(
    overrides: [
      if (admin) sessionProvider.overrideWith(() => _AdminSessionNotifier()),
      verificationRepositoryProvider.overrideWithValue(repository),
      verificationResultLocationResolverProvider.overrideWithValue(
        resolver ?? _NoOpLocationResolver(),
      ),
    ],
  );
  container.listen(verificationResultsViewModelProvider(runId), (_, _) {});
  return container;
}

VerificationRun _run(VerificationRunStatus status, {String? failureMessage}) {
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

VerificationResult _pendingResult(String id) => VerificationResult(
  id: id,
  runId: 'run-1',
  expectationId: 'expectation-$id',
  macroActivityId: 'macro-1',
  activityId: 'activity-1',
  displayName: 'Orden de transporte',
  evidenceType: process_models.EvidenceType.document,
  location: process_models.EvidenceLocation.activityRecord,
  subjectTicketId: id == 'result-1' ? '204' : '205',
  applicability: ApplicabilityAssessment(
    decision: ApplicabilityDecision.undetermined,
    origin: DecisionOrigin.aiApplicability,
    rationale: 'No se pudo determinar la aplicabilidad.',
    limitations: const [],
  ),
  proposedStatus: VerificationResultStatus.reviewRequired,
  effectiveStatus: VerificationResultStatus.reviewRequired,
  rationale: 'Requiere decisión humana.',
  limitations: const [],
  evidence: const [],
  humanDecisions: const [],
  revision: 0,
);

class _NoOpLocationResolver implements VerificationResultLocationResolver {
  @override
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  }) async => const {};
}

class _CaseDependentResolver implements VerificationResultLocationResolver {
  @override
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  }) async => {
    for (final result in results)
      result.id: const VerificationResultLocationContext(
        macroActivityName: 'Gestión de tickets',
        activityName: 'Actualizar ticket',
        applicabilityMode: evidence_model.ApplicabilityMode.caseDependent,
      ),
  };
}

class _AdminSessionNotifier extends SessionNotifier {
  @override
  Session? build() => const Session(role: UserRole.administrator);
}

class _ResultsRepository implements VerificationRepository {
  @override
  Future<VerificationResult> decideResult({
    required String runId,
    required String resultId,
    required int revision,
    required VerificationResultStatus finalStatus,
    required String rationale,
  }) async {
    statusDecisionResultIds.add(resultId);
    statusDecisionRevision = revision;
    statusDecisionRationale = rationale;
    if (rejectStatusDecisionAsConflict) {
      throw const ConflictFailure('La revisión cambió.');
    }
    final original = pages[0]!.items.firstWhere((item) => item.id == resultId);
    return VerificationResult(
      id: original.id,
      runId: original.runId,
      expectationId: original.expectationId,
      macroActivityId: original.macroActivityId,
      activityId: original.activityId,
      displayName: original.displayName,
      evidenceType: original.evidenceType,
      location: original.location,
      subjectTicketId: original.subjectTicketId,
      applicability: original.applicability,
      proposedStatus: original.proposedStatus,
      effectiveStatus: finalStatus,
      rationale: rationale,
      limitations: original.limitations,
      evidence: original.evidence,
      humanDecisions: [
        ...original.humanDecisions,
        HumanDecisionEvent(
          id: 'status-decision-1',
          decisionType: HumanDecisionType.resultStatus,
          finalStatus: finalStatus,
          rationale: rationale,
          decidedAt: DateTime.utc(2026, 10, 8),
        ),
      ],
      revision: revision + 1,
    );
  }

  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) async {
    resolvedResultIds.add(resultId);
    resolvedRevision = revision;
    resolvedRationale = rationale;
    if (rejectApplicabilityAsConflict) {
      throw const ConflictFailure('La revisión cambió.');
    }
    final original = pages[0]!.items.firstWhere((item) => item.id == resultId);
    return VerificationResult(
      id: original.id,
      runId: original.runId,
      expectationId: original.expectationId,
      macroActivityId: original.macroActivityId,
      activityId: original.activityId,
      displayName: original.displayName,
      evidenceType: original.evidenceType,
      location: original.location,
      subjectTicketId: original.subjectTicketId,
      applicability: ApplicabilityAssessment(
        decision: ApplicabilityDecision.notApplicable,
        origin: DecisionOrigin.human,
        rationale: rationale,
        limitations: const [],
      ),
      proposedStatus: original.proposedStatus,
      effectiveStatus: VerificationResultStatus.notApplicable,
      rationale: 'El Administrador resolvió la aplicabilidad.',
      limitations: const [],
      evidence: original.evidence,
      humanDecisions: [
        HumanDecisionEvent(
          id: 'decision-1',
          decisionType: HumanDecisionType.applicability,
          applicabilityDecision: decision,
          rationale: rationale,
          decidedAt: DateTime.utc(2026, 10, 8),
        ),
      ],
      revision: revision + 1,
    );
  }

  _ResultsRepository({
    required this.run,
    this.pages = const {},
    this.failNextResultsRequest = false,
    this.rejectApplicabilityAsConflict = false,
    this.rejectStatusDecisionAsConflict = false,
  });

  final VerificationRun run;
  final Map<int, PagedResult<VerificationResult>> pages;
  bool failNextResultsRequest;
  bool rejectApplicabilityAsConflict;
  bool rejectStatusDecisionAsConflict;
  final List<String> calls = [];
  final List<String> resolvedResultIds = [];
  int? resolvedRevision;
  String? resolvedRationale;
  final List<String> statusDecisionResultIds = [];
  int? statusDecisionRevision;
  String? statusDecisionRationale;

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
