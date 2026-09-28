import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_provider.dart';
import '../config/environment.dart';
import 'api_client.dart';

final apiHttpClientAdapterProvider = Provider<HttpClientAdapter?>(
  (ref) => null,
);

final apiClientProvider = Provider<Dio>((ref) {
  final client = createApiClient(
    baseUrl: Environment.apiBaseUrl,
    readToken: () => ref.read(sessionProvider)?.token,
    httpClientAdapter: ref.watch(apiHttpClientAdapterProvider),
  );
  ref.onDispose(client.close);
  return client;
});
