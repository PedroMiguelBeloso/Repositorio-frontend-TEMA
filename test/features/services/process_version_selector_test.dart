import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/services/widgets/process_version_selector.dart';

void main() {
  testWidgets('removing a process clears the visible version selection', (
    tester,
  ) async {
    final version = ProcessVersionOption(
      id: 'version-1',
      processId: 'process-1',
      processName: 'Start Up',
      officialVersion: '1.0',
      versionDate: DateTime(2026, 10, 1),
      status: ProcessStatus.published,
    );
    final group = AssignableProcessGroup(
      process: const ProcessDefinitionSummary(
        id: 'process-1',
        code: ProcessCode.startUp,
        name: 'Start Up',
        m2Enabled: true,
      ),
      publishedVersions: [version],
    );
    var selected = <ProcessVersionOption>[version];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: ProcessVersionSelector(
                groups: [group],
                selectedVersions: selected,
                onVersionSelected: (value) {},
                onProcessRemoved: (_) => setState(() => selected = []),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Asignada: versión 1.0'), findsOneWidget);
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(find.text('Asignada: versión 1.0'), findsNothing);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      isNull,
    );
  });
}
