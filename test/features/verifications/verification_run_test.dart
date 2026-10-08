import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/verification_run_page.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/verification_run_view_model.dart';

void main() {
  group('VerificationRunViewModel', () {
    test(
      'polls queued and running runs serially until a terminal state',
      () async {
        final gate = Completer<VerificationRun>();
        final repository = _RunRepository(
          response: (call) => call == 1
              ? _run(VerificationRunStatus.queued)
              : call == 2
              ? gate.future
              : _run(VerificationRunStatus.completed),
        );
        final container = _createContainer(
          repository,
          interval: const Duration(milliseconds: 10),
        );
        final subscription = container.listen(
          verificationRunViewModelProvider('run-1'),
          (_, _) {},
        );
        addTearDown(() {
          subscription.close();
          container.dispose();
        });

        await container.read(verificationRunViewModelProvider('run-1').future);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(repository.calls, 2);
        expect(repository.maxConcurrent, 1);

        gate.complete(_run(VerificationRunStatus.completed));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          container
              .read(verificationRunViewModelProvider('run-1'))
              .requireValue
              .run
              .status,
          VerificationRunStatus.completed,
        );
        final callsAfterCompletion = repository.calls;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(repository.calls, callsAfterCompletion);
      },
    );

    test(
      'preserves the last run on refresh error and supports retry',
      () async {
        final repository = _RunRepository(
          response: (call) {
            if (call == 2) throw StateError('temporary transport failure');
            return _run(
              call == 1
                  ? VerificationRunStatus.running
                  : VerificationRunStatus.failed,
              failureMessage: 'Falló el procesamiento.',
            );
          },
        );
        final container = _createContainer(
          repository,
          interval: const Duration(seconds: 1),
        );
        final subscription = container.listen(
          verificationRunViewModelProvider('run-1'),
          (_, _) {},
        );
        addTearDown(() {
          subscription.close();
          container.dispose();
        });

        await container.read(verificationRunViewModelProvider('run-1').future);
        await container
            .read(verificationRunViewModelProvider('run-1').notifier)
            .refresh();

        var state = container
            .read(verificationRunViewModelProvider('run-1'))
            .requireValue;
        expect(state.run.status, VerificationRunStatus.running);
        expect(state.refreshFailure, isNotNull);

        await container
            .read(verificationRunViewModelProvider('run-1').notifier)
            .retry();
        state = container
            .read(verificationRunViewModelProvider('run-1'))
            .requireValue;
        expect(state.run.status, VerificationRunStatus.failed);
        expect(state.refreshFailure, isNull);
      },
    );

    test('stops polling after a failed run', () async {
      final repository = _RunRepository(
        response: (call) => _run(
          call == 1
              ? VerificationRunStatus.running
              : VerificationRunStatus.failed,
          failureMessage: 'Falló el procesamiento.',
        ),
      );
      final container = _createContainer(
        repository,
        interval: const Duration(milliseconds: 10),
      );
      final subscription = container.listen(
        verificationRunViewModelProvider('run-1'),
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      await container.read(verificationRunViewModelProvider('run-1').future);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.calls, 2);
      expect(
        container
            .read(verificationRunViewModelProvider('run-1'))
            .requireValue
            .run
            .status,
        VerificationRunStatus.failed,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.calls, 2);
    });

    test('cancels polling when its provider is disposed', () async {
      final repository = _RunRepository(
        response: (_) => _run(VerificationRunStatus.queued),
      );
      final container = _createContainer(
        repository,
        interval: const Duration(milliseconds: 10),
      );
      final subscription = container.listen(
        verificationRunViewModelProvider('run-1'),
        (_, _) {},
      );
      await container.read(verificationRunViewModelProvider('run-1').future);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      final callsBeforeDispose = repository.calls;

      subscription.close();
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.calls, callsBeforeDispose);
    });
  });

  group('VerificationRunPage', () {
    testWidgets('shows indeterminate progress when total is zero', (
      tester,
    ) async {
      await _mountPage(
        tester,
        _run(
          VerificationRunStatus.queued,
          progress: RunProgress.fromValues(total: 0, processed: 0),
        ),
      );

      expect(find.text('En espera'), findsOneWidget);
      expect(find.text('0 de 0 registros procesados'), findsOneWidget);
      expect(find.text('Progreso indeterminado'), findsOneWidget);
      expect(find.text('0 %'), findsNothing);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, isNull);
    });

    testWidgets('shows determinate progress and review count', (tester) async {
      await _mountPage(
        tester,
        _run(
          VerificationRunStatus.running,
          progress: RunProgress.fromValues(
            total: 10,
            processed: 4,
            reviewRequired: 1,
          ),
        ),
      );

      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('4 de 10 registros procesados'), findsOneWidget);
      expect(find.text('40 %'), findsOneWidget);
      expect(find.text('Requieren revisión: 1'), findsOneWidget);
      expect(find.textContaining('errores'), findsNothing);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.4);
    });

    testWidgets('shows completed results action', (tester) async {
      await _mountPage(tester, _run(VerificationRunStatus.completed));

      expect(find.text('Finalizada').first, findsOneWidget);
      expect(find.text('Ver resultados'), findsOneWidget);
      expect(
        find.text('La pantalla de resultados aún está en desarrollo.'),
        findsNothing,
      );
    });

    testWidgets('shows backend failure details without retrying the run', (
      tester,
    ) async {
      await _mountPage(
        tester,
        _run(
          VerificationRunStatus.failed,
          failureMessage: 'No se pudo acceder a la fuente.',
        ),
      );

      expect(find.text('Fallida'), findsOneWidget);
      expect(find.text('No se pudo acceder a la fuente.'), findsOneWidget);
      expect(find.text('Volver a Verificaciones'), findsOneWidget);
      expect(find.text('Iniciar nueva verificación'), findsOneWidget);
      expect(find.text('Reintentar ejecución'), findsNothing);
    });
  });
}

ProviderContainer _createContainer(
  _RunRepository repository, {
  required Duration interval,
}) {
  return ProviderContainer(
    overrides: [
      verificationRepositoryProvider.overrideWithValue(repository),
      verificationRunPollingIntervalProvider.overrideWith((ref) => interval),
    ],
  );
}

Future<void> _mountPage(WidgetTester tester, VerificationRun run) async {
  final repository = _RunRepository(response: (_) => run);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(repository),
        verificationRunPollingIntervalProvider.overrideWith(
          (_) => const Duration(seconds: 3),
        ),
        sessionProvider.overrideWith(
          () =>
              _TestSessionNotifier(const Session(role: UserRole.administrator)),
        ),
      ],
      child: const MaterialApp(home: VerificationRunPage(runId: 'run-1')),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

VerificationRun _run(
  VerificationRunStatus status, {
  RunProgress? progress,
  String? failureMessage,
}) {
  return VerificationRun(
    id: 'run-1',
    serviceId: 'service-1',
    processVersionId: 'version-1',
    scope: VerificationScope.process,
    status: status,
    progress: progress ?? RunProgress.fromValues(total: 10, processed: 4),
    startedAt: DateTime.utc(2026, 10, 7, 10, 15),
    finishedAt: status == VerificationRunStatus.completed
        ? DateTime.utc(2026, 10, 7, 10, 20)
        : null,
    note: 'Verificación de prueba',
    failureMessage: failureMessage,
  );
}

class _RunRepository implements VerificationRepository {
  @override
  Future<VerificationResult> decideResult({
    required String runId,
    required String resultId,
    required int revision,
    required VerificationResultStatus finalStatus,
    required String rationale,
  }) => throw UnimplementedError();

  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) => throw UnimplementedError();

  _RunRepository({required this.response});

  final FutureOr<VerificationRun> Function(int call) response;
  int calls = 0;
  int _active = 0;
  int maxConcurrent = 0;

  @override
  Future<VerificationRun> getVerification(String runId) async {
    calls++;
    _active++;
    if (_active > maxConcurrent) maxConcurrent = _active;
    try {
      return await response(calls);
    } finally {
      _active--;
    }
  }

  @override
  Future<PagedResult<VerificationResult>> listResults({
    required String runId,
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) => throw UnimplementedError();

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId) =>
      throw UnimplementedError();

  @override
  Future<VerificationPreview> preview(VerificationTarget target) =>
      throw UnimplementedError();

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) => throw UnimplementedError();

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) => throw UnimplementedError();
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.session);

  final Session? session;

  @override
  Session? build() => session;
}
