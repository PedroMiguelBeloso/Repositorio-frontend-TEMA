import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_structure_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart';

void main() {
  test(
    'searches catalog with query and pagination from the OpenAPI contract',
    () async {
      final adapter = _RegistryAdapter();
      final repository = ProcessStructureRepositoryImpl(_client(adapter));

      final result = await repository.searchRegistry(
        query: 'Ticket',
        page: 2,
        size: 10,
      );

      expect(result.items.single.canonicalName, 'Ticket con requerimiento');
      expect(adapter.request!.method, 'GET');
      expect(adapter.request!.uri.path, '/api/v1/registry-definitions');
      expect(adapter.request!.uri.queryParameters, {
        'query': 'Ticket',
        'page': '2',
        'size': '10',
      });
    },
  );

  test(
    'creates only catalog fields and uses the server-generated key',
    () async {
      final adapter = _RegistryAdapter();
      final repository = ProcessStructureRepositoryImpl(_client(adapter));

      final created = await repository.createRegistryDefinition(
        canonicalName: 'Orden de transporte',
        evidenceType: EvidenceType.document,
        officialNomenclature: 'OT-001',
      );

      expect(created.id, 'registry-created');
      expect(created.key, 'generated-by-server');
      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.uri.path, '/api/v1/registry-definitions');
      expect(adapter.requestData, {
        'canonicalName': 'Orden de transporte',
        'evidenceType': 'DOCUMENT',
        'officialNomenclature': 'OT-001',
      });
    },
  );
}

ApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}

class _RegistryAdapter implements HttpClientAdapter {
  RequestOptions? request;
  Map<String, dynamic>? requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (options.data is Map) {
      requestData = Map<String, dynamic>.from(options.data as Map);
    }
    final payload = options.method == 'POST'
        ? {
            'id': 'registry-created',
            'key': 'generated-by-server',
            'canonicalName': 'Orden de transporte',
            'evidenceType': 'DOCUMENT',
            'officialNomenclature': 'OT-001',
            'preloaded': false,
          }
        : {
            'items': [
              {
                'id': 'registry-ticket',
                'key': 'ticket',
                'canonicalName': 'Ticket con requerimiento',
                'evidenceType': 'TICKET',
                'preloaded': true,
              },
            ],
            'page': {
              'page': 2,
              'size': 10,
              'totalElements': 21,
              'totalPages': 3,
            },
          };
    return ResponseBody.fromString(
      jsonEncode(payload),
      options.method == 'POST' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
