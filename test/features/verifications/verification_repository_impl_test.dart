import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';

void main() {
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
}

class _VerificationAdapter implements HttpClientAdapter {
  Map<String, dynamic>? previewBody;
  Map<String, dynamic>? startBody;

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
    if (path.endsWith('/verifications')) {
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
