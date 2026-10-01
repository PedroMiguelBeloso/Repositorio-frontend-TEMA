import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/core/network/api_client.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';

void main() {
  test('getAssignableProcessVersions keeps only published assignable versions', () async {
    final adapter = _ServicesAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(dio);
    final repository = ServiceRepositoryImpl(client);

    final result = await repository.getAssignableProcessVersions();

    expect(result.map((group) => group.process.code), [
      ProcessCode.startUp,
      ProcessCode.takeOver,
      ProcessCode.supportSoftwareFactory,
    ]);
    expect(result.expand((group) => group.publishedVersions).length, 3);
    expect(
      result.every(
        (group) => group.publishedVersions.every((version) => version.isPublished),
      ),
      isTrue,
    );
    expect(adapter.requestedQualityVersions, isFalse);
  });

  test('ServiceRepository maps validation problem details to field errors', () async {
    final adapter = _ServicesAdapter(servicesError: true);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = ServiceRepositoryImpl(ApiClient(dio));

    try {
      await repository.listServices(page: 0, size: 20);
      fail('La consulta debía producir ValidationFailure.');
    } on ValidationFailure catch (failure) {
      expect(failure.message, 'Datos inválidos.');
      expect(failure.fieldErrors['name'], 'El nombre es obligatorio.');
    }
  });
}

class _ServicesAdapter implements HttpClientAdapter {
  _ServicesAdapter({this.servicesError = false});

  final bool servicesError;
  bool requestedQualityVersions = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path.endsWith('/services') && servicesError) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {
            'status': 422,
            'detail': 'Datos inválidos.',
            'details': [
              {'field': 'name', 'message': 'El nombre es obligatorio.'},
            ],
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final payload = path.endsWith('/processes')
        ? _processes
        : path.endsWith('/processes/p1/versions')
        ? _versions('p1')
        : path.endsWith('/processes/p2/versions')
        ? _versions('p2')
        : path.endsWith('/processes/p3/versions')
        ? _versions('p3')
        : path.endsWith('/processes/p4/versions')
        ? _qualityVersions()
        : path.endsWith('/services')
        ? _serviceList
        : throw StateError('Ruta no prevista en el test: $path');

    return ResponseBody.fromString(
      _json(payload),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  final Map<String, dynamic> _processes = {
    'items': [
      {'id': 'p1', 'code': 'START_UP', 'name': 'Start Up', 'm2Enabled': true},
      {'id': 'p2', 'code': 'TAKE_OVER', 'name': 'Take Over', 'm2Enabled': true},
      {
        'id': 'p3',
        'code': 'SUPPORT_SOFTWARE_FACTORY',
        'name': 'Soporte y Software Factory',
        'm2Enabled': true,
      },
      {
        'id': 'p4',
        'code': 'QUALITY_CONTINUOUS_IMPROVEMENT',
        'name': 'Calidad y Mejora Continua',
        'm2Enabled': false,
      },
    ],
    'page': {'page': 0, 'size': 50, 'totalElements': 4, 'totalPages': 1},
  };

  Map<String, dynamic> _versions(String processId) {
    return {
      'items': [
        {
          'id': '$processId-published',
          'processId': processId,
          'officialVersion': '1.0',
          'versionDate': '2026-09-01',
          'status': 'PUBLISHED',
          'revision': 1,
          'objective': 'Objetivo',
          'owner': 'Owner',
          'policies': [],
          'macroActivities': [],
          'createdAt': '2026-09-01T00:00:00Z',
        },
        {
          'id': '$processId-draft',
          'processId': processId,
          'officialVersion': '2.0',
          'versionDate': '2026-09-02',
          'status': 'DRAFT',
          'revision': 1,
          'objective': 'Objetivo',
          'owner': 'Owner',
          'policies': [],
          'macroActivities': [],
          'createdAt': '2026-09-02T00:00:00Z',
        },
      ],
      'page': {'page': 0, 'size': 50, 'totalElements': 2, 'totalPages': 1},
    };
  }

  Map<String, dynamic> _qualityVersions() {
    requestedQualityVersions = true;
    return _versions('p4');
  }

  final _serviceList = {
    'items': [],
    'page': {'page': 0, 'size': 20, 'totalElements': 0, 'totalPages': 0},
  };

  String _json(Object value) => jsonEncode(value);

  @override
  void close({bool force = false}) {}
}
