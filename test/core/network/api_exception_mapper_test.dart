import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/core/network/api_exception_mapper.dart';

void main() {
  const mapper = ApiExceptionMapper();

  test('maps 401 using a ProblemDetail title without optional extensions', () {
    final failure = mapper.map(
      _httpException(401, {'status': 401, 'title': 'La sesión expiró.'}),
    );

    expect(failure, isA<UnauthenticatedFailure>());
    expect(failure.message, 'La sesión expiró.');
  });

  test('maps 403 to a permission failure', () {
    final failure = mapper.map(_httpException(403));

    expect(failure, isA<PermissionFailure>());
    expect(failure.message, isNotEmpty);
  });

  test('maps 400 and 422 to validation failures', () {
    for (final status in [400, 422]) {
      final failure = mapper.map(
        _httpException(status, {
          'status': status,
          'detail': 'Revisá el campo.',
        }),
      );

      expect(failure, isA<ValidationFailure>(), reason: '$status');
      expect(failure.message, 'Revisá el campo.', reason: '$status');
    }
  });

  test('maps conflict and unavailable service failures', () {
    expect(mapper.map(_httpException(409)), isA<ConflictFailure>());
    expect(mapper.map(_httpException(503)), isA<ServiceFailure>());
  });

  test('maps network errors to a safe user-facing failure', () {
    final failure = mapper.map(
      DioException(
        requestOptions: RequestOptions(path: '/resource'),
        type: DioExceptionType.connectionTimeout,
        message: 'technical socket details are hidden',
      ),
    );

    expect(failure, isA<NetworkFailure>());
    expect(failure.message, isNot(contains('technical socket')));
  });

  test('does not expose technical ProblemDetail messages', () {
    final failure = mapper.map(
      _httpException(400, {
        'status': 400,
        'detail': 'DioException: request failed at ApiClient.get()',
        'title': 'No se pudieron validar los datos.',
      }),
    );

    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'No se pudieron validar los datos.');

    final unsafeFallback = mapper.map(
      _httpException(400, {
        'status': 400,
        'detail': 'DioException: request failed',
      }),
    );
    expect(unsafeFallback.message, 'Revisá los datos ingresados.');
  });

  test('uses a safe service fallback instead of a server technical detail', () {
    final failure = mapper.map(
      _httpException(503, {
        'status': 503,
        'detail': 'Internal Server Error: Stack trace at Server.handle()',
      }),
    );

    expect(failure, isA<ServiceFailure>());
    expect(
      failure.message,
      'El servicio no está disponible. Intentá más tarde.',
    );
  });

  test('handles null, empty and non-map response bodies', () {
    for (final body in <Object?>[null, '', '{}', '[]', 42]) {
      final failure = mapper.map(_httpException(400, body));

      expect(failure, isA<ValidationFailure>(), reason: '$body');
      expect(failure.message, 'Revisá los datos ingresados.', reason: '$body');
    }
  });

  test('reads JSON-encoded problem details and uses detail before title', () {
    final failure = mapper.map(
      _httpException(401, '{"status":401,"title":"Título","detail":"Detalle"}'),
    );

    expect(failure.message, 'Detalle');
  });
}

DioException _httpException(int status, [Object? data]) {
  final requestOptions = RequestOptions(path: '/resource');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: status,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}
