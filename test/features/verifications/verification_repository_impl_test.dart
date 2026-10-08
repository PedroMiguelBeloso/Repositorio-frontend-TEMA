import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
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
}

class _VerificationAdapter implements HttpClientAdapter {
  Map<String, dynamic>? previewBody;
  Map<String, dynamic>? startBody;
  Map<String, dynamic>? historyQueryParameters;
  String? detailPath;
  bool runNotFound = false;

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
