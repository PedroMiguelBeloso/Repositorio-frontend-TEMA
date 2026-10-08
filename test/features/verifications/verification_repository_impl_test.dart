import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';

void main() {
  test(
    'history maps pagination and sends only the supported service filter',
    () async {
      final adapter = _VerificationAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio);
      final repository = VerificationRepositoryImpl(
        client,
        ServiceRepositoryImpl(client),
      );

      final result = await repository.listRuns(
        page: 1,
        size: 20,
        serviceId: 'service-2',
      );

      expect(adapter.historyQueryParameters, {
        'page': 1,
        'size': 20,
        'serviceId': 'service-2',
      });
      expect(result.page.totalElements, 21);
      expect(result.page.totalPages, 2);
      expect(result.items.single.id, 'run-2');
      expect(result.items.single.status, VerificationRunStatus.running);
      expect(result.items.single.scope, VerificationScope.process);
      expect(result.items.single.progress.fractionLabel, '6 de 10');

      await repository.listRuns(page: 0, size: 20);
      expect(adapter.historyQueryParameters, {'page': 0, 'size': 20});
    },
  );

  test(
    'preview and start use the published contract and selected ticket ID',
    () async {
      final adapter = _VerificationAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio);
      final repository = VerificationRepositoryImpl(
        client,
        ServiceRepositoryImpl(client),
      );

      final preview = await repository.preview(
        const VerificationTarget(
          serviceId: 'service-1',
          processVersionId: 'version-1',
          scope: VerificationScope.macroActivity,
          macroActivityId: 'macro-1',
          note: 'Revisión inicial',
        ),
      );
      expect(preview.serviceRevision, 4);
      expect(preview.ticketSelectionGroups.single.id, 'macro-1:ticket-input');
      expect(adapter.previewBody?['scope'], 'MACRO_ACTIVITY');
      expect(adapter.previewBody?['macroActivityId'], 'macro-1');

      final runId = await repository.start(preview, 'Revisión inicial', {
        'macro-1:ticket-input': {'204'},
      });
      expect(runId, 'run-1');
      expect(adapter.startBody?['serviceRevision'], 4);
      expect(adapter.startBody?['ticketSelections'], [
        {
          'groupId': 'macro-1:ticket-input',
          'ticketIds': ['204'],
        },
      ]);
    },
  );

  test(
    'loads paginated results and maps applicability, references and ticket scope',
    () async {
      final adapter = _VerificationAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = VerificationRepositoryImpl(
        ApiClient(dio),
        ServiceRepositoryImpl(ApiClient(dio)),
      );

      final results = await repository.listResults(
        runId: 'run-results',
        page: 1,
        size: 20,
      );

      expect(adapter.resultsPath, '/api/v1/verifications/run-results/results');
      expect(adapter.resultsQueryParameters, {'page': 1, 'size': 20});
      expect(results.page.page, 1);
      expect(results.page.totalElements, 21);
      expect(results.page.totalPages, 2);
      expect(results.items.single.displayName, 'Ticket actualizado');
      expect(results.items.single.subjectTicketId, '204');
      expect(
        results.items.single.effectiveStatus,
        VerificationResultStatus.reviewRequired,
      );
      expect(
        results.items.single.proposedStatus,
        VerificationResultStatus.complies,
      );
      expect(
        results.items.single.applicability.decision,
        ApplicabilityDecision.undetermined,
      );
      expect(
        results.items.single.applicability.origin,
        DecisionOrigin.aiApplicability,
      );
      expect(
        results.items.single.evidence.single.source,
        EvidenceSource.redmine,
      );
      expect(results.items.single.evidence.single.ticketId, '204');
      expect(
        results.items.single.evidence.single.webUrl,
        'https://redmine.example/tickets/204',
      );
      expect(
        results.items.single.humanDecisions.single.decisionType,
        HumanDecisionType.resultStatus,
      );
    },
  );

  test('loads and maps a run from its detail endpoint', () async {
    final adapter = _VerificationAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = VerificationRepositoryImpl(
      ApiClient(dio),
      ServiceRepositoryImpl(ApiClient(dio)),
    );

    final run = await repository.getVerification('run-detail');

    expect(adapter.detailPath, '/api/v1/verifications/run-detail');
    expect(run.id, 'run-detail');
    expect(run.status, VerificationRunStatus.running);
    expect(run.scope, VerificationScope.macroActivity);
    expect(run.progress.processed, 4);
    expect(run.progress.total, 10);
    expect(run.progress.reviewRequired, 1);
    expect(run.note, 'Revisión inicial');
    expect(run.finishedAt, isNull);
  });

  test('maps a missing run to an explicit not-found message', () async {
    final adapter = _VerificationAdapter()..runNotFound = true;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = VerificationRepositoryImpl(
      ApiClient(dio),
      ServiceRepositoryImpl(ApiClient(dio)),
    );

    await expectLater(
      repository.getVerification('missing'),
      throwsA(
        isA<UnexpectedFailure>().having(
          (failure) => failure.message,
          'message',
          contains('no existe o no se encuentra'),
        ),
      ),
    );
  });

  test(
    'posts applicability decision with the current revision and maps the updated result',
    () async {
      final adapter = _VerificationAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = VerificationRepositoryImpl(
        ApiClient(dio),
        ServiceRepositoryImpl(ApiClient(dio)),
      );

      final updated = await repository.resolveApplicability(
        runId: 'run-results',
        resultId: 'result-204',
        revision: 1,
        decision: HumanApplicabilityDecision.notApplicable,
        rationale: '  No hubo desarrollo.  ',
      );

      expect(
        adapter.applicabilityPath,
        '/api/v1/verifications/run-results/results/result-204/applicability',
      );
      expect(adapter.applicabilityBody, {
        'revision': 1,
        'decision': 'NOT_APPLICABLE',
        'rationale': 'No hubo desarrollo.',
      });
      expect(
        updated.applicability.decision,
        ApplicabilityDecision.notApplicable,
      );
      expect(updated.effectiveStatus, VerificationResultStatus.notApplicable);
      expect(updated.proposedStatus, VerificationResultStatus.reviewRequired);
      expect(updated.revision, 2);
      expect(
        updated.humanDecisions.single.decisionType,
        HumanDecisionType.applicability,
      );
    },
  );

  test('maps a stale applicability revision to a conflict', () async {
    final adapter = _VerificationAdapter()..applicabilityConflict = true;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = VerificationRepositoryImpl(
      ApiClient(dio),
      ServiceRepositoryImpl(ApiClient(dio)),
    );

    await expectLater(
      repository.resolveApplicability(
        runId: 'run-results',
        resultId: 'result-204',
        revision: 1,
        decision: HumanApplicabilityDecision.applies,
        rationale: 'Aplica al ticket.',
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test(
    'puts a status decision with revision and maps the human event',
    () async {
      final adapter = _VerificationAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = VerificationRepositoryImpl(
        ApiClient(dio),
        ServiceRepositoryImpl(ApiClient(dio)),
      );

      final updated = await repository.decideResult(
        runId: 'run-results',
        resultId: 'result-204',
        revision: 2,
        finalStatus: VerificationResultStatus.doesNotComply,
        rationale: '  Falta evidencia válida.  ',
      );

      expect(adapter.decisionMethod, 'PUT');
      expect(
        adapter.decisionPath,
        '/api/v1/verifications/run-results/results/result-204/decision',
      );
      expect(adapter.decisionBody, {
        'revision': 2,
        'finalStatus': 'DOES_NOT_COMPLY',
        'rationale': 'Falta evidencia válida.',
      });
      expect(updated.proposedStatus, VerificationResultStatus.complies);
      expect(updated.effectiveStatus, VerificationResultStatus.doesNotComply);
      expect(
        updated.humanDecisions.single.decisionType,
        HumanDecisionType.resultStatus,
      );
      expect(updated.revision, 3);
    },
  );

  test('a stale human status decision maps to conflict', () async {
    final adapter = _VerificationAdapter()..decisionConflict = true;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = VerificationRepositoryImpl(
      ApiClient(dio),
      ServiceRepositoryImpl(ApiClient(dio)),
    );
    await expectLater(
      repository.decideResult(
        runId: 'run-results',
        resultId: 'result-204',
        revision: 1,
        finalStatus: VerificationResultStatus.complies,
        rationale: 'Confirmado.',
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });
}

class _VerificationAdapter implements HttpClientAdapter {
  Map<String, dynamic>? previewBody;
  Map<String, dynamic>? startBody;
  Map<String, dynamic>? historyQueryParameters;
  String? detailPath;
  String? resultsPath;
  Map<String, dynamic>? resultsQueryParameters;
  bool runNotFound = false;
  String? applicabilityPath;
  Map<String, dynamic>? applicabilityBody;
  bool applicabilityConflict = false;
  String? decisionPath;
  String? decisionMethod;
  Map<String, dynamic>? decisionBody;
  bool decisionConflict = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path.endsWith('/verifications/preview')) {
      previewBody = Map<String, dynamic>.from(options.data as Map);
      return _response({
        'serviceId': 'service-1',
        'serviceRevision': 4,
        'processVersionId': 'version-1',
        'scope': 'MACRO_ACTIVITY',
        'macroActivityId': 'macro-1',
        'expectations': [],
        'ticketSelectionGroups': [
          {
            'id': 'macro-1:ticket-input',
            'macroActivityId': 'macro-1',
            'label': 'Ticket recibido',
            'cardinality': 'ONE',
            'inputExpectationIds': ['input-1'],
            'relatedExpectationIds': ['output-1'],
            'required': true,
          },
        ],
      }, 200);
    }
    if (path.endsWith('/results') && options.method == 'GET') {
      resultsPath = path;
      resultsQueryParameters = Map<String, dynamic>.from(
        options.queryParameters,
      );
      return _response({
        'items': [
          {
            'id': 'result-204',
            'runId': 'run-results',
            'expectationId': 'expectation-ticket-update',
            'macroActivityId': 'macro-1',
            'activityId': 'activity-3',
            'displayName': 'Ticket actualizado',
            'evidenceType': 'TICKET',
            'location': 'ACTIVITY_RECORD',
            'subjectTicketId': '204',
            'applicability': {
              'decision': 'UNDETERMINED',
              'origin': 'AI_APPLICABILITY',
              'rationale':
                  'No hay información suficiente para resolver la aplicabilidad.',
              'limitations': ['Falta contexto del caso.'],
            },
            'proposedStatus': 'COMPLIES',
            'effectiveStatus': 'REVIEW_REQUIRED',
            'rationale':
                'La fuente está disponible pero requiere intervención.',
            'limitations': ['La consulta de Redmine fue parcial.'],
            'evidence': [
              {
                'kind': 'TICKET',
                'source': 'REDMINE',
                'externalId': '204',
                'displayName': 'Ticket 204',
                'webUrl': 'https://redmine.example/tickets/204',
                'observedAt': '2026-10-08T12:00:00Z',
                'ticketId': '204',
              },
            ],
            'humanDecisions': [
              {
                'id': 'decision-1',
                'decisionType': 'RESULT_STATUS',
                'finalStatus': 'REVIEW_REQUIRED',
                'rationale': 'El Administrador dejó el estado para revisión.',
                'decidedAt': '2026-10-08T13:00:00Z',
              },
            ],
            'revision': 1,
          },
        ],
        'page': {'page': 1, 'size': 20, 'totalElements': 21, 'totalPages': 2},
      }, 200);
    }
    if (path.endsWith('/applicability') && options.method == 'POST') {
      applicabilityPath = path;
      applicabilityBody = Map<String, dynamic>.from(options.data as Map);
      if (applicabilityConflict) {
        return _response({'status': 409, 'detail': 'La revisión cambió.'}, 409);
      }
      return _response({
        'id': 'result-204',
        'runId': 'run-results',
        'expectationId': 'expectation-ticket-update',
        'macroActivityId': 'macro-1',
        'activityId': 'activity-3',
        'displayName': 'Orden de transporte',
        'evidenceType': 'DOCUMENT',
        'location': 'ACTIVITY_RECORD',
        'subjectTicketId': '204',
        'applicability': {
          'decision': 'NOT_APPLICABLE',
          'origin': 'HUMAN',
          'rationale': 'No hubo desarrollo.',
          'limitations': [],
        },
        'proposedStatus': 'REVIEW_REQUIRED',
        'effectiveStatus': 'NOT_APPLICABLE',
        'rationale': 'El Administrador determinó que no aplica.',
        'limitations': [],
        'evidence': [],
        'humanDecisions': [
          {
            'id': 'decision-2',
            'decisionType': 'APPLICABILITY',
            'applicabilityDecision': 'NOT_APPLICABLE',
            'rationale': 'No hubo desarrollo.',
            'decidedAt': '2026-10-08T14:00:00Z',
          },
        ],
        'revision': 2,
      }, 200);
    }
    if (path.endsWith('/decision') && options.method == 'PUT') {
      decisionPath = path;
      decisionMethod = options.method;
      decisionBody = Map<String, dynamic>.from(options.data as Map);
      if (decisionConflict) {
        return _response({'status': 409, 'detail': 'La revisión cambió.'}, 409);
      }
      return _response({
        'id': 'result-204',
        'runId': 'run-results',
        'expectationId': 'expectation-ticket-update',
        'macroActivityId': 'macro-1',
        'activityId': 'activity-3',
        'displayName': 'Ticket actualizado',
        'evidenceType': 'TICKET',
        'location': 'ACTIVITY_RECORD',
        'subjectTicketId': '204',
        'applicability': {
          'decision': 'APPLIES',
          'origin': 'DETERMINISTIC',
          'rationale': 'La evidencia aplica.',
          'limitations': [],
        },
        'proposedStatus': 'COMPLIES',
        'effectiveStatus': 'DOES_NOT_COMPLY',
        'rationale': 'Falta evidencia válida.',
        'limitations': [],
        'evidence': [],
        'humanDecisions': [
          {
            'id': 'decision-status-1',
            'decisionType': 'RESULT_STATUS',
            'finalStatus': 'DOES_NOT_COMPLY',
            'rationale': 'Falta evidencia válida.',
            'decidedAt': '2026-10-08T15:00:00Z',
          },
        ],
        'revision': 3,
      }, 200);
    }
    if (path.contains('/verifications/') &&
        !path.endsWith('/verifications/preview')) {
      detailPath = path;
      if (runNotFound) return _response({'title': 'Not found'}, 404);
      return _response({
        'id': 'run-detail',
        'serviceId': 'service-detail',
        'serviceTypeSnapshot': 'SUPPORT_ERP',
        'serviceRevisionSnapshot': 2,
        'processVersionId': 'version-detail',
        'sourceSnapshot': {},
        'scope': 'MACRO_ACTIVITY',
        'macroActivityId': 'macro-detail',
        'note': 'Revisión inicial',
        'status': 'RUNNING',
        'progress': {'total': 10, 'processed': 4, 'reviewRequired': 1},
        'startedBy': 'user-1',
        'startedAt': '2026-10-07T10:15:00Z',
        'ticketSelections': [],
      }, 200);
    }
    if (path.endsWith('/verifications') && options.method == 'GET') {
      historyQueryParameters = Map<String, dynamic>.from(
        options.queryParameters,
      );
      return _response({
        'items': [
          {
            'id': 'run-2',
            'serviceId': 'service-2',
            'serviceTypeSnapshot': 'SUPPORT_ERP',
            'serviceRevisionSnapshot': 2,
            'processVersionId': 'version-2',
            'sourceSnapshot': {},
            'scope': 'PROCESS',
            'status': 'RUNNING',
            'progress': {'total': 10, 'processed': 6, 'reviewRequired': 0},
            'startedBy': 'user-1',
            'startedAt': '2026-10-07T10:15:00Z',
            'ticketSelections': [],
          },
        ],
        'page': {'page': 1, 'size': 20, 'totalElements': 21, 'totalPages': 2},
      }, 200);
    }
    if (path.endsWith('/verifications') && options.method == 'POST') {
      startBody = Map<String, dynamic>.from(options.data as Map);
      return _response({'id': 'run-1'}, 202);
    }
    throw StateError('Unexpected route: $path');
  }

  ResponseBody _response(Object json, int status) => ResponseBody.fromString(
    jsonEncode(json),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
