import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/new_verification_page.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/new_verification_view_model.dart';

void main() {
  testWidgets('shows loading then an understandable empty state on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completion = Completer<NewVerificationState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          newVerificationViewModelProvider.overrideWith(
            () => _PendingViewModel(completion),
          ),
        ],
        child: const MaterialApp(home: NewVerificationPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completion.complete(const NewVerificationState(services: []));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Todavía no hay servicios. Creá uno y asignale una versión publicada antes de verificar.',
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps expected records collapsed and separates ticket groups', (
    tester,
  ) async {
    await _pumpReady(tester);

    expect(find.text('2. Registros que se comprobarán'), findsOneWidget);
    expect(find.text('Registro de prueba'), findsNothing);
    expect(find.text('3. Tickets de entrada'), findsOneWidget);
    expect(find.text('Tickets - Informar requerimiento'), findsOneWidget);
    expect(find.text('Tickets - Gestionar requerimiento'), findsOneWidget);
    expect(find.byKey(const ValueKey('ticket-g1-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('ticket-g2-3')), findsOneWidget);
    expect(find.byTooltip('Página siguiente'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('ticket-g2-4')));
    await tester.tap(find.byKey(const ValueKey('ticket-g2-4')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('ticket-g2-4')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('ticket-g1-4')))
          .value,
      isFalse,
    );
    expect(find.text('Tickets elegidos en este grupo · 1'), findsOneWidget);

    await tester.ensureVisible(find.text('2. Registros que se comprobarán'));
    await tester.tap(find.text('2. Registros que se comprobarán'));
    await tester.pumpAndSettle();
    expect(find.text('Registro de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticket cards wrap long subjects on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReady(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('ticket-g2-4')));
    await tester.pumpAndSettle();
    expect(find.text('Registro de prueba'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpReady(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        newVerificationViewModelProvider.overrideWith(_ReadyViewModel.new),
      ],
      child: const MaterialApp(home: NewVerificationPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _ReadyViewModel extends NewVerificationViewModel {
  @override
  Future<NewVerificationState> build() async => const NewVerificationState(
    services: [],
    preview: VerificationPreview(
      serviceId: 's1',
      serviceRevision: 1,
      processVersionId: 'p1',
      scope: VerificationScope.process,
      expectations: [
        PreviewExpectation(
          id: 'e1',
          displayName: 'Registro de prueba',
          location: 'INPUT',
          evidenceType: 'DOCUMENT',
          applicability: 'ALWAYS',
          cardinality: 'ONE',
        ),
      ],
      ticketSelectionGroups: [
        TicketSelectionGroup(
          id: 'g1',
          label: 'Tickets - Informar requerimiento',
          cardinality: 'ONE',
          required: true,
          relatedExpectationIds: ['e1'],
        ),
        TicketSelectionGroup(
          id: 'g2',
          label: 'Tickets - Gestionar requerimiento',
          cardinality: 'ONE',
          required: true,
          relatedExpectationIds: ['e1'],
        ),
      ],
    ),
    tickets: TicketPage(
      items: [
        TicketSummary(
          id: '3',
          subject:
              'Requerimiento abierto con una descripción larga para probar el ajuste del texto en pantalla angosta',
          status: 'To Do',
        ),
        TicketSummary(
          id: '4',
          subject: 'Requerimiento actualizado',
          status: 'In Progress',
        ),
      ],
      page: PageInfo(page: 0, size: 20, totalElements: 2, totalPages: 1),
    ),
  );
}

class _PendingViewModel extends NewVerificationViewModel {
  _PendingViewModel(this.completion);
  final Completer<NewVerificationState> completion;
  @override
  Future<NewVerificationState> build() => completion.future;
}
