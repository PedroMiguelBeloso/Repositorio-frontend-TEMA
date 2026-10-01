import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/viewmodel/process_editor_view_model.dart';

import 'fake_process_repository.dart';
import 'process_test_fixtures.dart';

void main() {
  test(
    'loading and saving a draft preserves node IDs and existing evidences',
    () async {
      final original = sampleProcessVersion();
      final repository = FakeProcessRepository(
        definitions: [_definition],
        versionsByProcess: {
          _definition.id: [original],
        },
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final provider = processEditorViewModelProvider((
        processId: _definition.id,
        versionId: original.id,
      ));
      await container.read(provider.future);

      final notifier = container.read(provider.notifier);
      notifier.updateObjective('Objetivo actualizado');
      notifier.updateActivity(
        macroKey: 'macro-1',
        activityKey: 'activity-1',
        instructions: 'Instrucciones actualizadas',
      );

      expect(notifier.hasUnsavedChanges, isTrue);
      expect(await notifier.save(), isTrue);

      final submitted = repository.submittedVersion!;
      expect(submitted.revision, 7);
      expect(submitted.policies.single.id, 'policy-1');
      expect(submitted.macroActivities.single.id, 'macro-1');
      expect(submitted.macroActivities.single.activities.single.id, 'activity-1');
      expect(submitted.macroActivities.single.inputs.single.id, 'input-1');
      expect(
        submitted.macroActivities.single.activities.single.records.single.id,
        'record-1',
      );
      expect(submitted.macroActivities.single.outputs.single.id, 'output-1');

      final state = container.read(provider).value!;
      expect(state.version.revision, 8);
      expect(state.saveSucceeded, isTrue);
      expect(notifier.hasUnsavedChanges, isFalse);
    },
  );

  test('a revision conflict is shown and never reported as a successful save',
      () async {
    final original = sampleProcessVersion();
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {
        _definition.id: [original],
      },
      saveFailure: const ConflictFailure(
        'La revisión del borrador cambió en el servidor.',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        processRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final provider = processEditorViewModelProvider((
      processId: _definition.id,
      versionId: original.id,
    ));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.updateObjective('Cambio concurrente local');
    expect(await notifier.save(), isFalse);

    final state = container.read(provider).value!;
    expect(state.actionFailure, isA<ConflictFailure>());
    expect(state.saveSucceeded, isFalse);
    expect(state.isSaving, isFalse);
    expect(notifier.hasUnsavedChanges, isTrue);
  });
}

final _definition = ProcessDefinition(
  id: 'process-1',
  code: M1ProcessCode.startUp,
  name: 'Start Up',
  m2Enabled: true,
  createdAt: DateTime(2026, 10, 1),
);
