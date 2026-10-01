import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';

class GeneralDataSection extends StatelessWidget {
  const GeneralDataSection({
    super.key,
    required this.definition,
    required this.version,
    required this.readOnly,
    required this.validationErrors,
    required this.onOfficialVersionChanged,
    required this.onVersionDateChanged,
    required this.onObjectiveChanged,
    required this.onOwnerChanged,
  });

  final ProcessDefinition definition;
  final ProcessVersion version;
  final bool readOnly;
  final Map<String, String> validationErrors;
  final ValueChanged<String> onOfficialVersionChanged;
  final ValueChanged<DateTime> onVersionDateChanged;
  final ValueChanged<String> onObjectiveChanged;
  final ValueChanged<String> onOwnerChanged;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return _ReadOnlyGeneralData(definition: definition, version: version);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Datos generales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Proceso'),
                child: Text(definition.displayName),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: ValueKey('official-version-${version.revision}'),
                initialValue: version.officialVersion,
                decoration: InputDecoration(
                  labelText: 'Versión oficial',
                  errorText: validationErrors[
                    ProcessEditorFieldKeys.officialVersion
                  ],
                ),
                onChanged: onOfficialVersionChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _VersionDateField(
                date: version.versionDate,
                errorText:
                    validationErrors[ProcessEditorFieldKeys.versionDate],
                onChanged: onVersionDateChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: ValueKey('objective-${version.revision}'),
                initialValue: version.objective,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Objetivo del proceso',
                  alignLabelWithHint: true,
                  errorText:
                      validationErrors[ProcessEditorFieldKeys.objective],
                ),
                onChanged: onObjectiveChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: ValueKey('owner-${version.revision}'),
                initialValue: version.owner,
                decoration: InputDecoration(
                  labelText: 'Responsable del proceso',
                  errorText: validationErrors[ProcessEditorFieldKeys.owner],
                ),
                onChanged: onOwnerChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionDateField extends StatelessWidget {
  const _VersionDateField({
    required this.date,
    required this.errorText,
    required this.onChanged,
  });

  final DateTime date;
  final String? errorText;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final selected = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDate: date,
              helpText: 'Fecha de versión',
              cancelText: 'Cancelar',
              confirmText: 'Aceptar',
            );
            if (selected != null) onChanged(selected);
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fecha de versión: ${DateFormat('dd/MM/yyyy').format(date)}',
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyGeneralData extends StatelessWidget {
  const _ReadOnlyGeneralData({required this.definition, required this.version});

  final ProcessDefinition definition;
  final ProcessVersion version;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadOnlyField(label: 'Proceso', value: definition.displayName),
                  _ReadOnlyField(
                    label: 'Versión oficial',
                    value: version.officialVersion,
                  ),
                  _ReadOnlyField(
                    label: 'Fecha de versión',
                    value: DateFormat('dd/MM/yyyy').format(version.versionDate),
                  ),
                  _ReadOnlyField(
                    label: 'Objetivo del proceso',
                    value: version.objective,
                  ),
                  _ReadOnlyField(
                    label: 'Responsable del proceso',
                    value: version.owner,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
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
