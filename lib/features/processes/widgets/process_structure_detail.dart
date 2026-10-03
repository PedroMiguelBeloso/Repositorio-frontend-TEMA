import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';
import 'process_evidence_section.dart';

class ProcessStructureDetail extends StatelessWidget {
  const ProcessStructureDetail({
    super.key,
    required this.state,
    required this.readOnly,
    required this.onMacroChanged,
    required this.onActivityChanged,
    required this.notifier,
  });

  final ProcessEditorState state;
  final bool readOnly;
  final ProcessEditorViewModel notifier;
  final void Function({
    required String macroKey,
    String? name,
    String? description,
  })
  onMacroChanged;
  final void Function({
    required String macroKey,
    required String activityKey,
    String? name,
    String? responsible,
    String? instructions,
    String? etaText,
  })
  onActivityChanged;

  @override
  Widget build(BuildContext context) {
    final macro = state.selectedMacroActivity;
    final activity = state.selectedActivity;

    if (macro == null) {
      return const Card(
        child: EmptyState(
          message:
              'Seleccioná una macroactividad o actividad para ver su detalle.',
          icon: Icons.touch_app_outlined,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: activity == null
            ? _MacroActivityForm(
                macro: macro,
                readOnly: readOnly,
                errorText:
                    state.validationErrors[ProcessEditorFieldKeys.macroName(
                      macro.localKey,
                    )],
                onChanged: onMacroChanged,
                notifier: notifier,
              )
            : _ActivityForm(
                macro: macro,
                activity: activity,
                readOnly: readOnly,
                nameError:
                    state.validationErrors[ProcessEditorFieldKeys.activityName(
                      activity.localKey,
                    )],
                instructionsError:
                    state
                        .validationErrors[ProcessEditorFieldKeys.activityInstructions(
                      activity.localKey,
                    )],
                onChanged: onActivityChanged,
                notifier: notifier,
              ),
      ),
    );
  }
}

class _MacroActivityForm extends StatelessWidget {
  const _MacroActivityForm({
    required this.macro,
    required this.readOnly,
    required this.errorText,
    required this.onChanged,
    required this.notifier,
  });

  final ProcessMacroActivity macro;
  final ProcessEditorViewModel notifier;
  final bool readOnly;
  final String? errorText;
  final void Function({
    required String macroKey,
    String? name,
    String? description,
  })
  onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Text('Macroactividad', style: theme.textTheme.titleLarge),
            if (!readOnly)
              OutlinedButton.icon(
                onPressed: () => notifier.addActivity(macro.localKey),
                icon: const Icon(Icons.add),
                label: const Text('Agregar actividad'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (readOnly) ...[
          _ReadOnlyValue(label: 'Nombre', value: macro.name),
          _ReadOnlyValue(label: 'Descripción', value: macro.description),
        ] else ...[
          TextFormField(
            key: ValueKey('macro-name-${macro.localKey}-${macro.id ?? 'new'}'),
            initialValue: macro.name,
            decoration: InputDecoration(
              labelText: 'Nombre de la macroactividad',
              errorText: errorText,
            ),
            onChanged: (value) =>
                onChanged(macroKey: macro.localKey, name: value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('macro-description-${macro.localKey}'),
            initialValue: macro.description,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              alignLabelWithHint: true,
            ),
            onChanged: (value) =>
                onChanged(macroKey: macro.localKey, description: value),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ProcessEvidenceSection(
          title: 'Entradas',
          location: EvidenceLocation.input,
          items: macro.inputs,
          macroKey: macro.localKey,
          notifier: notifier,
          readOnly: readOnly,
        ),
        const SizedBox(height: AppSpacing.lg),
        ProcessEvidenceSection(
          title: 'Salidas',
          location: EvidenceLocation.output,
          items: macro.outputs,
          macroKey: macro.localKey,
          notifier: notifier,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _ActivityForm extends StatelessWidget {
  const _ActivityForm({
    required this.macro,
    required this.activity,
    required this.readOnly,
    required this.nameError,
    required this.instructionsError,
    required this.onChanged,
    required this.notifier,
  });

  final ProcessMacroActivity macro;
  final ProcessActivity activity;
  final ProcessEditorViewModel notifier;
  final bool readOnly;
  final String? nameError;
  final String? instructionsError;
  final void Function({
    required String macroKey,
    required String activityKey,
    String? name,
    String? responsible,
    String? instructions,
    String? etaText,
  })
  onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actividad', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        if (readOnly) ...[
          _ReadOnlyValue(label: 'Nombre', value: activity.name),
          _ReadOnlyValue(label: 'Responsable', value: activity.responsible),
          _ReadOnlyValue(label: 'Instrucciones', value: activity.instructions),
          _ReadOnlyValue(
            label: 'Plazo o periodicidad informativa',
            value: activity.etaText,
          ),
        ] else ...[
          TextFormField(
            key: ValueKey(
              'activity-name-${activity.localKey}-${activity.id ?? 'new'}',
            ),
            initialValue: activity.name,
            decoration: InputDecoration(
              labelText: 'Nombre de la actividad',
              errorText: nameError,
            ),
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              activityKey: activity.localKey,
              name: value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('activity-responsible-${activity.localKey}'),
            initialValue: activity.responsible,
            decoration: const InputDecoration(labelText: 'Responsable'),
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              activityKey: activity.localKey,
              responsible: value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('activity-instructions-${activity.localKey}'),
            initialValue: activity.instructions,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Instrucciones',
              alignLabelWithHint: true,
              errorText: instructionsError,
            ),
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              activityKey: activity.localKey,
              instructions: value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('activity-eta-${activity.localKey}'),
            initialValue: activity.etaText,
            decoration: const InputDecoration(
              labelText: 'Plazo o periodicidad informativa',
              helperText:
                  'Texto informativo. No crea recordatorios ni vencimientos.',
            ),
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              activityKey: activity.localKey,
              etaText: value,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ProcessEvidenceSection(
          title: 'Registros de la actividad',
          location: EvidenceLocation.activityRecord,
          items: activity.records,
          macroKey: macro.localKey,
          activityKey: activity.localKey,
          notifier: notifier,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(value.trim().isEmpty ? 'Sin completar' : value),
        ],
      ),
    );
  }
}
