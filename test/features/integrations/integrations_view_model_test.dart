import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_source.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_state.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_status.dart';
import 'package:proyecto_tema_frontend/features/integrations/viewmodel/integrations_view_model.dart';

void main() {
  test('loads the initial integration statuses', () async {
    final repository = _FakeIntegrationsRepository(statuses: _initialStatuses);
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = await container.read(integrationsViewModelProvider.future);

    expect(state.statusFor(IntegrationSource.drive)?.state,
        IntegrationState.available);
    expect(repository.loadCalls, 1);
  });

  test('initial load errors can be retried', () async {
    final repository = _FakeIntegrationsRepository(
      statuses: _initialStatuses,
      loadFailure: const NetworkFailure('No se pudo conectar.'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await expectLater(
      container.read(integrationsViewModelProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
    expect(container.read(integrationsViewModelProvider), isA<AsyncError>());

    await container
        .read(integrationsViewModelProvider.notifier)
        .retry();

    expect(container.read(integrationsViewModelProvider).value?.statuses,
        _initialStatuses);
    expect(repository.loadCalls, 2);
  });

  test('successful test replaces the statuses returned by initial load', () async {
    final repository = _FakeIntegrationsRepository(
      statuses: _initialStatuses,
      testStatuses: _updatedStatuses,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(integrationsViewModelProvider.future);

    await container
        .read(integrationsViewModelProvider.notifier)
        .testIntegrations();

    final state = container.read(integrationsViewModelProvider).requireValue;
    expect(state.statuses, _updatedStatuses);
    expect(state.isTesting, isFalse);
    expect(state.actionFailure, isNull);
    expect(repository.testCalls, 1);
  });

  test('failed test keeps the last statuses and exposes a safe failure', () async {
    final repository = _FakeIntegrationsRepository(
      statuses: _initialStatuses,
      testFailure: const NetworkFailure('No se pudo conectar.'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(integrationsViewModelProvider.future);

    await container
        .read(integrationsViewModelProvider.notifier)
        .testIntegrations();

    final state = container.read(integrationsViewModelProvider).requireValue;
    expect(state.statuses, _initialStatuses);
    expect(state.actionFailure?.message, 'No se pudo conectar.');
    expect(state.isTesting, isFalse);
  });

  test('ignores a second test call while the first is in progress', () async {
    final completion = Completer<List<IntegrationStatus>>();
    final repository = _FakeIntegrationsRepository(
      statuses: _initialStatuses,
      testCompleter: completion,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(integrationsViewModelProvider.future);

    final notifier = container.read(integrationsViewModelProvider.notifier);
    final firstCall = notifier.testIntegrations();
    final secondCall = notifier.testIntegrations();

    expect(repository.testCalls, 1);
    expect(container.read(integrationsViewModelProvider).value?.isTesting, isTrue);
    completion.complete(_updatedStatuses);
    await Future.wait([firstCall, secondCall]);
  });

  test('a missing source has no fabricated status', () async {
    final repository = _FakeIntegrationsRepository(
      statuses: [_initialStatuses.first],
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = await container.read(integrationsViewModelProvider.future);

    expect(state.statusFor(IntegrationSource.redmine), isNull);
  });
}

ProviderContainer _container(_FakeIntegrationsRepository repository) =>
    ProviderContainer(
      overrides: [
        integrationsRepositoryProvider.overrideWithValue(repository),
      ],
    );

final _initialStatuses = [
  IntegrationStatus(
    source: IntegrationSource.drive,
    state: IntegrationState.available,
    checkedAt: DateTime.utc(2026, 10, 1, 12),
  ),
  IntegrationStatus(
    source: IntegrationSource.redmine,
    state: IntegrationState.unavailable,
    checkedAt: DateTime.utc(2026, 10, 1, 12),
  ),
];

final _updatedStatuses = [
  IntegrationStatus(
    source: IntegrationSource.drive,
    state: IntegrationState.permissionError,
    checkedAt: DateTime.utc(2026, 10, 1, 13),
  ),
  IntegrationStatus(
    source: IntegrationSource.redmine,
    state: IntegrationState.available,
    checkedAt: DateTime.utc(2026, 10, 1, 13),
  ),
];

class _FakeIntegrationsRepository implements IntegrationsRepository {
  _FakeIntegrationsRepository({
    required this.statuses,
    this.testStatuses = const [],
    this.loadFailure,
    this.testFailure,
    this.testCompleter,
  });

  final List<IntegrationStatus> statuses;
  final List<IntegrationStatus> testStatuses;
  AppFailure? loadFailure;
  final AppFailure? testFailure;
  final Completer<List<IntegrationStatus>>? testCompleter;
  int loadCalls = 0;
  int testCalls = 0;

  @override
  Future<List<IntegrationStatus>> loadStatuses() async {
    loadCalls++;
    final failure = loadFailure;
    if (failure != null) {
      loadFailure = null;
      throw failure;
    }
    return statuses;
  }

  @override
  Future<List<IntegrationStatus>> testIntegrations() {
    testCalls++;
    if (testCompleter != null) return testCompleter!.future;
    if (testFailure != null) throw testFailure!;
    return Future.value(testStatuses);
  }
}