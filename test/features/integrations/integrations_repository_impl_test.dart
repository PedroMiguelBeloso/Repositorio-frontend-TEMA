import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_source.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_state.dart';

void main() {
  test('loads integration status through ApiClient', () async {
    final adapter = _IntegrationsAdapter();
    final repository = IntegrationsRepositoryImpl(_client(adapter));

    final statuses = await repository.loadStatuses();

    expect(adapter.request?.method, 'GET');
    expect(adapter.request?.uri.path, '/api/v1/integrations/status');
    expect(statuses.single.source, IntegrationSource.drive);
    expect(statuses.single.state, IntegrationState.available);
  });

  test('tests integrations and returns the updated statuses', () async {
    final adapter = _IntegrationsAdapter(status: 'UNAVAILABLE');
    final repository = IntegrationsRepositoryImpl(_client(adapter));

    final statuses = await repository.testIntegrations();

    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.uri.path, '/api/v1/integrations/test');
    expect(statuses.single.state, IntegrationState.unavailable);
  });

  test('ignores sources the client does not recognize', () async {
    final adapter = _IntegrationsAdapter(source: 'OTHER');
    final repository = IntegrationsRepositoryImpl(_client(adapter));

    expect(await repository.loadStatuses(), isEmpty);
  });
}

ApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}

class _IntegrationsAdapter implements HttpClientAdapter {
  _IntegrationsAdapter({
    this.source = 'DRIVE',
    this.status = 'AVAILABLE',
  });

  final String source;
  final String status;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final payload = [
      {
        'source': source,
        'status': status,
        'checkedAt': '2026-10-01T12:30:00Z',
      },
    ];
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}