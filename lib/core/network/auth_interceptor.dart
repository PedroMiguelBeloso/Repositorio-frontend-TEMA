import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/session_provider.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = ref.read(sessionProvider);

    final requiresAuth = options.headers.remove('Requires-Auth') != 'false';
    if (requiresAuth && session?.isValid == true) {
      options.headers['Authorization'] = 'Bearer ${session!.accessToken!}';
    }

    options.extra['requiresAuth'] = requiresAuth;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['requiresAuth'] == true) {
      ref.read(sessionProvider.notifier).clearSession();
    }
    handler.next(err);
  }
}