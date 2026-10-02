import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository_impl.dart';

void main() {
  test('creates a draft with the selected source version ID', () async {
    final adapter = _ProcessVersionAdapter();
    final repository = ProcessRepositoryImpl(_client(adapter));

    await repository.createDraftVersion(
      processId: 'process-1',
      officialVersion: ' 2.0 ',
      versionDate: DateTime(2026, 10, 1),
      copyFromVersionId: 'version-1',
    );

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, '/api/v1/processes/process-1/versions');
    expect(adapter.requestData, {
      'officialVersion': '2.0',
      'versionDate': '2026-10-01',
      'copyFromVersionId': 'version-1',
    });
  });

  test('loads every history page declared by the server', () async {
    final adapter = _ProcessVersionAdapter();
    final repository = ProcessRepositoryImpl(_client(adapter));

    final versions = await repository.listVersions('process-1');

    expect(versions.map((version) => version.id), ['version-1', 'version-2']);
    expect(
      adapter.requests.map((request) => request.uri.queryParameters['page']),
      ['0', '1'],
    );
    expect(
      adapter.requests.every(
        (request) => request.uri.queryParameters['size'] == '50',
      ),
      isTrue,
    );
  });

  test('publishes the saved revision and maps the published response', () async {
    final adapter = _ProcessVersionAdapter();
    final repository = ProcessRepositoryImpl(_client(adapter));

    final published = await repository.publishVersion(
      processId: 'process-1',
      versionId: 'version-1',
      revision: 9,
    );

    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.uri.path,
      '/api/v1/processes/process-1/versions/version-1/publish',
    );
    expect(adapter.requestData, {'revision': 9});
    expect(published.status.apiValue, 'PUBLISHED');
    expect(published.publishedAt, DateTime.parse('2026-10-01T12:00:00Z'));
  });

  test('keeps a stale-revision conflict as a conflict failure', () async {
    final adapter = _ProcessVersionAdapter(
      publishStatus: 409,
      publishProblem: {
        'status': 409,
        'code': 'STALE_REVISION',
        'detail': 'El borrador cambió en el servidor.',
      },
    );
    final repository = ProcessRepositoryImpl(_client(adapter));

    await expectLater(
      repository.publishVersion(
        processId: 'process-1',
        versionId: 'version-1',
        revision: 9,
      ),
      throwsA(
        isA<ConflictFailure>().having(
          (failure) => failure.message,
          'message',
          'El borrador cambió en el servidor.',
        ),
      ),
    );
  });

  test('keeps publication validation details as a validation failure', () async {
    final adapter = _ProcessVersionAdapter(
      publishStatus: 422,
      publishProblem: {
        'status': 422,
        'detail': 'La versión no se puede publicar.',
        'details': [
          {
            'field': 'macroActivities[0].activities[0].instructions',
            'message': 'Las instrucciones son obligatorias.',
          },
        ],
      },
    );
    final repository = ProcessRepositoryImpl(_client(adapter));

    await expectLater(
      repository.publishVersion(
        processId: 'process-1',
        versionId: 'version-1',
        revision: 9,
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.fieldErrors,
          'fieldErrors',
          {
            'macroActivities[0].activities[0].instructions':
                'Las instrucciones son obligatorias.',
          },
        ),
      ),
    );
  });
}

ApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}

class _ProcessVersionAdapter implements HttpClientAdapter {
  _ProcessVersionAdapter({
    this.publishStatus = 200,
    this.publishProblem,
  });

  final int publishStatus;
  final Map<String, dynamic>? publishProblem;
  final List<RequestOptions> requests = [];
  Map<String, dynamic>? requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.data is Map) {
      requestData = Map<String, dynamic>.from(options.data as Map);
    }

    if (options.uri.path.endsWith('/publish')) {
      return _response(
        publishProblem ?? _version(status: 'PUBLISHED', revision: 10),
        publishStatus,
      );
    }
    if (options.uri.path.endsWith('/versions') && options.method == 'GET') {
      final page = int.parse(options.uri.queryParameters['page']!);
      return _response({
        'items': [_version(id: 'version-${page + 1}')],
        'page': {
          'page': page,
          'size': 50,
          'totalElements': 2,
          'totalPages': 2,
        },
      }, 200);
    }
    if (options.uri.path.endsWith('/versions') && options.method == 'POST') {
      return _response(_version(id: 'version-copy'), 201);
    }
    throw StateError('Unexpected request: ${options.method} ${options.uri}');
  }

  ResponseBody _response(Object payload, int status) =>
      ResponseBody.fromString(
        jsonEncode(payload),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  Map<String, dynamic> _version({
    String id = 'version-1',
    String status = 'DRAFT',
    int revision = 7,
  }) => {
    'id': id,
    'processId': 'process-1',
    'officialVersion': '2.0',
    'versionDate': '2026-10-01',
    'status': status,
    'revision': revision,
    'objective': 'Objetivo',
    'owner': 'Responsable',
    'policies': <Object>[],
    'macroActivities': <Object>[],
    if (status == 'PUBLISHED') 'publishedAt': '2026-10-01T12:00:00Z',
    'createdAt': '2026-10-01T10:00:00Z',
  };

  @override
  void close({bool force = false}) {}
}