import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import 'auth_interceptor.dart';
import 'api_client.dart';

final apiHttpClientAdapterProvider = Provider<HttpClientAdapter?>(
  (ref) => null,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = createApiClient(
    baseUrl: Environment.apiBaseUrl,
    authInterceptor: AuthInterceptor(ref),
    httpClientAdapter: ref.watch(apiHttpClientAdapterProvider),
  );
  ref.onDispose(dio.close);
  return ApiClient(dio);
});
