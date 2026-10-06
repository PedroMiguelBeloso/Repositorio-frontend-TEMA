import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/view/process_consultation_view.dart';

import 'process_test_fixtures.dart';

void main() {
  final definition = ProcessDefinition(
    id: 'process-1',
    code: M1ProcessCode.startUp,
    name: 'Start Up',
    m2Enabled: true,
    createdAt: DateTime(2026, 10, 1),
  );

  for (final width in [375.0, 1366.0]) {
    testWidgets(
      'Start Up has readable policy and macro order at ${width.toInt()} px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final base = sampleProcessVersion(
          status: ProcessVersionStatus.published,
        );
        final organization = base.macroActivities.first.copyWith(
          name: 'Organización interna',
          activities: [
            base.macroActivities.first.activities.first.copyWith(
              name: 'Asignar responsable del servicio',
              instructions:
                  '1. Analizar la propuesta.\nContinuar la misma instrucción.\n2. Actualizar Capacity.',
              etaText:
                  '2 días hábiles como máximo luego de recibir y revisar la propuesta aprobada por el cliente',
            ),
            const ProcessActivity(
              localKey: 'activity-2',
              name: 'Comunicar asignación',
              responsible: 'Responsable de Operaciones',
              instructions: 'Enviar aviso.',
              etaText: 'Al inicio',
              order: 1,
              records: [],
            ),
          ],
        );
        final communication = ProcessMacroActivity(
          localKey: 'macro-2',
          name: 'Comunicación',
          description: '',
          order: 1,
          inputs: const [],
          activities: const [],
          outputs: const [],
        );
        final version = base.copyWith(
          policies: const [
            ProcessPolicy(
              localKey: 'p1',
              order: 0,
              text: 'Repositorio interno obligatorio.',
            ),
            ProcessPolicy(
              localKey: 'p2',
              order: 1,
              text: 'Copiar documentos del cliente.',
            ),
            ProcessPolicy(
              localKey: 'p3',
              order: 2,
              text: 'Repetir en renovaciones con nuevo alcance.',
            ),
          ],
          macroActivities: [organization, communication],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            home: Scaffold(
              body: ProcessConsultationView(
                definition: definition,
                version: version,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Objetivo'), findsOneWidget);
        expect(find.text('Políticas del proceso'), findsOneWidget);
        expect(find.text('Repositorio interno obligatorio.'), findsOneWidget);
        expect(find.text('Recorrido del proceso'), findsOneWidget);
        expect(find.text('Macroactividad 1'), findsOneWidget);
        expect(find.text('Asignar responsable del servicio'), findsOneWidget);
        expect(find.text('Macroactividad 2'), findsOneWidget);
        expect(find.byType(Scrollbar), findsOneWidget);
        expect(find.byKey(const Key('activity-divider-1')), findsOneWidget);
        expect(find.byKey(const Key('activity-card-1')), findsOneWidget);
        expect(find.text('Instrucciones'), findsNWidgets(2));
        expect(
          find.text('1. Analizar la propuesta.\nContinuar la misma instrucción.\n2. Actualizar Capacity.'),
          findsOneWidget,
        );
        expect(
          find.text('No se configuraron registros para esta actividad.'),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('record-1'),
            matching: find.byKey(const Key('activity-card-1')),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('input-1'),
            matching: find.byKey(const Key('activity-card-1')),
          ),
          findsNothing,
        );
        expect(
          find.textContaining('Responsable: Responsable vigente'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('input-1'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Cuándo aplica: Siempre'), findsWidgets);
        expect(find.textContaining('Cantidad requerida: Una'), findsWidgets);
        expect(
          tester.getTopLeft(find.text('Objetivo')).dy,
          lessThan(tester.getTopLeft(find.text('Políticas del proceso')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Políticas del proceso')).dy,
          lessThan(tester.getTopLeft(find.text('Recorrido del proceso')).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
