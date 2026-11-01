import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/core/widgets/app_error_view.dart';
import 'package:proyecto_tema_frontend/core/widgets/integration_status_card.dart';
import 'package:proyecto_tema_frontend/core/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip presents a text label and a tone icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: StatusChip(label: 'Disponible', tone: StatusTone.success),
        ),
      ),
    );

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('IntegrationStatusCard shows resolved fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: IntegrationStatusCard(
            sourceLabel: 'Google Drive',
            statusLabel: 'Disponible',
            tone: StatusTone.success,
            checkedAtLabel: '01/10/2026 12:30',
            message: 'Consulta de lectura correcta.',
          ),
        ),
      ),
    );

    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Última comprobación: 01/10/2026 12:30'), findsOneWidget);
    expect(find.text('Consulta de lectura correcta.'), findsOneWidget);
  });

  testWidgets(
    'IntegrationStatusCard can show missing information without a date',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: IntegrationStatusCard(
              sourceLabel: 'Redmine',
              statusLabel: 'Sin información',
              tone: StatusTone.neutral,
            ),
          ),
        ),
      );

      expect(find.text('Sin información'), findsOneWidget);
      expect(find.textContaining('Última comprobación:'), findsNothing);
    },
  );

  testWidgets('AppErrorView uses OutlinedButton for retry', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: AppErrorView(
            failure: const NetworkFailure('No se pudo conectar.'),
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('No se pudo conectar.'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retryCount, 1);
  });
}
