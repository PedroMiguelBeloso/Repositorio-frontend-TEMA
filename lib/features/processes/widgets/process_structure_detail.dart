import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';

class ProcessStructureDetail extends StatelessWidget {
  const ProcessStructureDetail({
    super.key,
    required this.state,
    required this.readOnly,
    required this.onMacroChanged,
    required this.onActivityChanged,
  });

  final ProcessEditorState state;
  final bool readOnly;
  final void Function({
    required String macroKey,
    String? name,
    String? description,
  }) onMacroChanged;
  final void Function({
    required String macroKey,
    required String activityKey,
    String? name,
    String? responsible,
    String? instructions,
    String? etaText,
  }) onActivityChanged;

  @override
  Widget build(BuildContext context) {
    final macro = state.selectedMacroActivity;
    final activity = state.selectedActivity;

    if (macro == null) {
      return const Card(
        child: EmptyState(
          message: 'Seleccioná una macroactividad o actividad para ver su detalle.',
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
                errorText: state.validationErrors[
                  ProcessEditorFieldKeys.macroName(macro.localKey)
                ],
                onChanged: onMacroChanged,
              )
            : _ActivityForm(
                macro: macro,
                activity: activity,
                readOnly: readOnly,
                nameError: state.validationErrors[
                  ProcessEditorFieldKeys.activityName(activity.localKey)
                ],
                instructionsError: state.validationErrors[
                  ProcessEditorFieldKeys.activityInstructions(
                    activity.localKey,
                  )
                ],
                onChanged: onActivityChanged,
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
  });

  final ProcessMacroActivity macro;
  final bool readOnly;
  final String? errorText;
  final void Function({
    required String macroKey,
    String? name,
    String? description,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Macroactividad', style: theme.textTheme.titleLarge),
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
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              name: value,
            ),
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
            onChanged: (value) => onChanged(
              macroKey: macro.localKey,
              description: value,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Evidencias asociadas',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Entradas: ${macro.inputs.length} · '
          'Salidas: ${macro.outputs.length}. '
          'Se conservan al guardar este borrador.',
          style: theme.textTheme.bodySmall,
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
  });

  final ProcessMacroActivity macro;
  final ProcessActivity activity;
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
  }) onChanged;

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
            key: ValueKey('activity-name-${activity.localKey}-${activity.id ?? 'new'}'),
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
        Text('Registros de actividad', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${activity.records.length} registro(s) asociado(s). '
          'Se conservan al guardar.',
          style: theme.textTheme.bodySmall,
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
