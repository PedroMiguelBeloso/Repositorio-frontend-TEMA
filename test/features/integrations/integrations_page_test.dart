import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integrations_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_source.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_state.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_status.dart';
import 'package:proyecto_tema_frontend/features/integrations/view/integrations_page.dart';

void main() {
  testWidgets('shows both resolved sources and their Spanish statuses', (
    tester,
  ) async {
    final repository = _FakeIntegrationsRepository(statuses: _statuses);
    final container = _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_subject(container));
    await tester.pumpAndSettle();

    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Redmine'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Error de autenticación'), findsOneWidget);
    expect(find.text('Probar integraciones'), findsOneWidget);
    expect(find.textContaining('Última comprobación:'), findsNWidgets(2));
  });

  testWidgets('test action is disabled with progress until response arrives', (
    tester,
  ) async {
    final completion = Completer<List<IntegrationStatus>>();
    final repository = _FakeIntegrationsRepository(
      statuses: _statuses,
      testCompleter: completion,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_subject(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar integraciones'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Probar integraciones'),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.testCalls, 1);

    completion.complete(_updatedStatuses);
    await tester.pumpAndSettle();

    expect(find.text('Sin permiso para consultar'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('failed test keeps statuses and shows a safe error', (
    tester,
  ) async {
    final completion = Completer<List<IntegrationStatus>>();
    final repository = _FakeIntegrationsRepository(
      statuses: _statuses,
      testCompleter: completion,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_subject(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar integraciones'));
    await tester.pump();
    completion.completeError(const NetworkFailure('No se pudo conectar.'));
    await tester.pumpAndSettle();

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Error de autenticación'), findsOneWidget);
    expect(find.text('No se pudo conectar.'), findsOneWidget);
    expect(repository.testCalls, 1);
  });

  testWidgets('load error shows retry and retry reloads the page', (
    tester,
  ) async {
    final repository = _FakeIntegrationsRepository(
      statuses: _statuses,
      failFirstLoad: true,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_subject(container));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar.'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Disponible'), findsOneWidget);
    expect(repository.loadCalls, 2);
  });

  testWidgets('missing source is shown as Sin información without a date', (
    tester,
  ) async {
    final repository = _FakeIntegrationsRepository(
      statuses: [_statuses.first],
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_subject(container));
    await tester.pumpAndSettle();

    expect(find.text('Sin información'), findsOneWidget);
    expect(find.textContaining('Última comprobación:'), findsOneWidget);
  });

  for (final width in [360.0, 1200.0]) {
    testWidgets('fits without overflow at $width logical pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = _container(
        _FakeIntegrationsRepository(statuses: _statuses),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_subject(container));
      await tester.pumpAndSettle();

      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Redmine'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

ProviderContainer _container(_FakeIntegrationsRepository repository) =>
    ProviderContainer(
      overrides: [
        integrationsRepositoryProvider.overrideWithValue(repository),
      ],
    );

Widget _subject(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: appTheme,
    home: const Scaffold(body: IntegrationsPage()),
  ),
);

final _statuses = [
  IntegrationStatus(
    source: IntegrationSource.drive,
    state: IntegrationState.available,
    checkedAt: DateTime.utc(2026, 10, 1, 12, 30),
    message: 'Lectura correcta.',
  ),
  IntegrationStatus(
    source: IntegrationSource.redmine,
    state: IntegrationState.authError,
    checkedAt: DateTime.utc(2026, 10, 1, 12, 30),
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
    this.testCompleter,
    this.failFirstLoad = false,
  });

  final List<IntegrationStatus> statuses;
  final Completer<List<IntegrationStatus>>? testCompleter;
  bool failFirstLoad;
  int loadCalls = 0;
  int testCalls = 0;

  @override
  Future<List<IntegrationStatus>> loadStatuses() async {
    loadCalls++;
    if (failFirstLoad) {
      failFirstLoad = false;
      throw const NetworkFailure('No se pudo conectar.');
    }
    return statuses;
  }

  @override
  Future<List<IntegrationStatus>> testIntegrations() {
    testCalls++;
    return testCompleter?.future ?? Future.value(_updatedStatuses);
  }
}