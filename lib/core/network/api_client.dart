import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createApiClient({
  required String baseUrl,
  required Interceptor authInterceptor,
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

  dio.interceptors.add(authInterceptor);
  if (kDebugMode) dio.interceptors.add(_SafeRequestLogInterceptor());
  return dio;
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

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {Object? data, Options? options}) =>
      _dio.put<T>(path, data: data, options: options);
}
