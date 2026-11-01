import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/ai_retry_history_dialog.dart';

void main() {
  final attempts = [
    AiRetryAttempt.fromJson({
      'attemptedAt': '2026-10-26T12:00:00Z',
      'outcome': 'HUMAN_PRESERVED',
      'previousProposedStatus': 'REVIEW_REQUIRED',
      'proposedStatus': 'COMPLIES',
      'effectiveStatus': 'DOES_NOT_COMPLY',
      'rationale': 'El campo Validación confirma el requisito.',
      'model': 'gemini-2.5-flash',
      'ticketSnapshot': [
        {
          'id': '42',
          'subject': 'Actualizar instalación',
          'projectName': 'Servicio TEMA',
          'statusName': 'Resuelto',
          'closed': true,
          'customFields': [
            {'name': 'Validación', 'value': 'Aprobada'},
          ],
          'journals': [],
        },
      ],
      'previousResult': {
        'displayName': 'Ticket actualizado',
        'rationale': 'Antes faltaba prueba de la actualización.',
        'applicability': {'decision': 'APPLIES'},
      },
    }),
  ];

  testWidgets('shows a readable before/after audit and ticket facts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: AiRetryHistoryDialog(attempts: attempts)),
      ),
    );
    expect(find.text('Qué cambió'), findsOneWidget);
    expect(find.text('Tickets de Redmine releídos'), findsOneWidget);
    expect(find.text('Actualizar instalación'), findsOneWidget);
    expect(find.text('REDMINE · TICKET #42'), findsOneWidget);
    expect(find.text('Estado en Redmine'), findsOneWidget);
    expect(find.text('Copiar ticket'), findsOneWidget);
    expect(
      find.text(
        'La decisión humana se conservó. Solo cambió la propuesta automática.',
      ),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(
      find.text('Antes faltaba prueba de la actualización.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'copies a ticket as a formatted document rather than concatenated labels',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(body: AiRetryHistoryDialog(attempts: attempts)),
        ),
      );
      await tester.ensureVisible(find.text('Copiar ticket'));
      await tester.tap(find.text('Copiar ticket'));
      await tester.pumpAndSettle();
      expect(
        copied,
        contains(
          'Ticket #42 — Actualizar instalación\nProyecto: Servicio TEMA',
        ),
      );
      expect(
        copied,
        contains('\nCampos personalizados:\n- Validación: Aprobada'),
      );
    },
  );

  testWidgets('explains an empty ticket snapshot at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final empty = AiRetryAttempt.fromJson({
      'attemptedAt': '2026-10-26T12:00:00Z',
      'outcome': 'NO_CHANGE',
      'previousProposedStatus': 'REVIEW_REQUIRED',
      'proposedStatus': 'REVIEW_REQUIRED',
      'effectiveStatus': 'REVIEW_REQUIRED',
      'rationale': 'No había hechos del caso.',
      'ticketSnapshot': [],
      'previousResult': {},
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: AiRetryHistoryDialog(attempts: [empty])),
      ),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se consultaron tickets'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
