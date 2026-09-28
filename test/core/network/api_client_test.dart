import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/core/network/api_client_provider.dart';

void main() {
  test('adds the current session token as a Bearer header', () async {
    final adapter = _RecordingAdapter();
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _TestSessionNotifier(
            const Session(role: UserRole.reader, token: 'unit-test-token'),
          ),
        ),
        apiHttpClientAdapterProvider.overrideWith((ref) => adapter),
      ],
    );
    addTearDown(container.dispose);

    final response = await container
        .read(apiClientProvider)
        .get<Map<String, dynamic>>('/private-resource');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer unit-test-token',
    );
  });

  test(
    'does not add an Authorization header without a session token',
    () async {
      final adapter = _RecordingAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _TestSessionNotifier(null)),
          apiHttpClientAdapterProvider.overrideWith((ref) => adapter),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/public-resource');

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    },
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.session);

  final Session? session;

  @override
  Session? build() => session;
}
