import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createApiClient({
  required String baseUrl,
  required String? Function() readToken,
  HttpClientAdapter? httpClientAdapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;

  dio.interceptors.add(_AuthorizationInterceptor(readToken));
  if (kDebugMode) dio.interceptors.add(_SafeRequestLogInterceptor());
  return dio;
}

class _AuthorizationInterceptor extends Interceptor {
  _AuthorizationInterceptor(this.readToken);

  final String? Function() readToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _SafeRequestLogInterceptor extends Interceptor {
  static const _startedAtKey = 'requestStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode?.toString() ?? 'unknown');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode?.toString() ?? 'network');
    handler.next(err);
  }

  void _log(RequestOptions options, String status) {
    final startedAt = options.extra[_startedAtKey] as DateTime?;
    final duration = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    debugPrint(
      '[HTTP] ${options.method.toUpperCase()} ${options.uri.path} '
      'status=$status duration=${duration}ms',
    );
  }
}
