import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../model/process_models.dart';
import '../model/registry_definition.dart';
import '../view/registry_index_page.dart';
import '../viewmodel/process_editor_view_model.dart';

class ProcessEvidenceSection extends StatelessWidget {
  const ProcessEvidenceSection({
    super.key,
    required this.title,
    required this.location,
    required this.items,
    required this.macroKey,
    required this.notifier,
    required this.readOnly,
    this.activityKey,
  });

  final String title;
  final EvidenceLocation location;
  final List<EvidenceExpectation> items;
  final String macroKey;
  final String? activityKey;
  final ProcessEditorViewModel notifier;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (!readOnly)
            OutlinedButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: Text(
                'Agregar ${switch (location) {
                  EvidenceLocation.input => 'entrada',
                  EvidenceLocation.output => 'salida',
                  _ => 'registro',
                }}',
              ),
            ),
        ],
      ),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text('Todavía no hay registros configurados.'),
        ),
      for (var i = 0; i < items.length; i++)
        Card(
          child: ListTile(
            title: Text(items[i].displayName),
            subtitle: Text(
              '${items[i].evidenceType.label} · '
              '${items[i].applicability.label} · '
              '${items[i].cardinality.label}',
            ),
            trailing: readOnly
                ? null
                : Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: 'Mover arriba',
                        onPressed: i == 0
                            ? null
                            : () => notifier.moveEvidence(
                                macroKey: macroKey,
                                activityKey: activityKey,
                                location: location,
                                index: i,
                                delta: -1,
                              ),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Mover abajo',
                        onPressed: i == items.length - 1
                            ? null
                            : () => notifier.moveEvidence(
                                macroKey: macroKey,
                                activityKey: activityKey,
                                location: location,
                                index: i,
                                delta: 1,
                              ),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _edit(context, index: i),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Quitar',
                        onPressed: () => _remove(context, i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
          ),
        ),
    ],
  );

  Future<void> _edit(BuildContext context, {int? index}) async {
    final config = await showDialog<_EvidenceConfig>(
      context: context,
      builder: (context) =>
          _EvidenceDialog(original: index == null ? null : items[index]),
    );
    if (config == null) return;
    if (index == null) {
      notifier.addEvidence(
        macroKey: macroKey,
        activityKey: activityKey,
        location: location,
        definition: config.definition,
        displayName: config.displayName,
        applicability: config.applicability,
        cardinality: config.cardinality,
      );
    } else {
      notifier.updateEvidence(
        macroKey: macroKey,
        activityKey: activityKey,
        location: location,
        index: index,
        definition: config.definition,
        displayName: config.displayName,
        applicability: config.applicability,
        cardinality: config.cardinality,
      );
    }
  }

  Future<void> _remove(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar registro'),
        content: Text(
          '¿Quitar «${items[index].displayName}» de este borrador?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.removeEvidence(
        macroKey: macroKey,
        activityKey: activityKey,
        location: location,
        index: index,
      );
    }
  }
}

class _EvidenceConfig {
  const _EvidenceConfig(
    this.definition,
    this.displayName,
    this.applicability,
    this.cardinality,
  );

  final RegistryDefinition definition;
  final String displayName;
  final ApplicabilityMode applicability;
  final EvidenceCardinality cardinality;
}

class _EvidenceDialog extends StatefulWidget {
  const _EvidenceDialog({this.original});

  final EvidenceExpectation? original;

  @override
  State<_EvidenceDialog> createState() => _EvidenceDialogState();
}

class _EvidenceDialogState extends State<_EvidenceDialog> {
  late final TextEditingController _displayName;
  RegistryDefinition? _definition;
  late ApplicabilityMode _applicability;
  late EvidenceCardinality _cardinality;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    _displayName = TextEditingController(text: original?.displayName ?? '');
    if (original != null) {
      _definition = RegistryDefinition(
        id: original.registryDefinitionId,
        key: '',
        canonicalName: original.displayName,
        evidenceType: original.evidenceType,
        preloaded: false,
        officialNomenclature: original.officialNomenclature,
      );
    }
    _applicability = original?.applicability ?? ApplicabilityMode.always;
    _cardinality = original?.cardinality ?? EvidenceCardinality.one;
  }

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.original == null ? 'Agregar evidencia' : 'Editar evidencia',
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registro del índice',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _selectDefinition,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(
                _definition == null
                    ? 'Elegir del índice de registros'
                    : _definition!.canonicalName,
              ),
            ),
            if (_definition != null)
              Text(
                '${_definition!.evidenceType.label}'
                '${_definition!.officialNomenclature == null ? '' : ' · ${_definition!.officialNomenclature}'}',
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(
                labelText: 'Nombre en este proceso (opcional)',
                helperText: 'Solo cambia cómo se muestra aquí; no cambia la nomenclatura de búsqueda.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ApplicabilityMode>(
              initialValue: _applicability,
              decoration: const InputDecoration(labelText: 'Cuándo aplica'),
              items: [
                for (final mode in ApplicabilityMode.values.where(
                  (mode) => mode != ApplicabilityMode.unknown,
                ))
                  DropdownMenuItem(value: mode, child: Text(mode.label)),
              ],
              onChanged: (value) => setState(() => _applicability = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<EvidenceCardinality>(
              initialValue: _cardinality,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              items: [
                for (final count in EvidenceCardinality.values.where(
                  (count) => count != EvidenceCardinality.unknown,
                ))
                  DropdownMenuItem(value: count, child: Text(count.label)),
              ],
              onChanged: (value) => setState(() => _cardinality = value!),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _definition == null
            ? null
            : () => Navigator.pop(
                context,
                _EvidenceConfig(
                  _definition!,
                  _displayName.text,
                  _applicability,
                  _cardinality,
                ),
              ),
        child: const Text('Guardar'),
      ),
    ],
  );

  Future<void> _selectDefinition() async {
    final result = await selectRegistryDefinition(context);
    if (!mounted || result == null) return;
    setState(() => _definition = result);
  }
}
