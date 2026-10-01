
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/evidence_expectation.dart';
import '../model/process_structure_models.dart';
import '../viewmodel/process_view_models.dart';
import 'registry_catalog_dialog.dart';

class ProcessListPage extends ConsumerWidget {
  const ProcessListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processes = ref.watch(processListViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Procesos')),
      body: AsyncContent<List<ProcessDefinition>>(
        value: processes,
        errorMessage: 'No se pudieron cargar los procesos.',
        onRetry: () => ref.invalidate(processListViewModelProvider),
        isEmpty: (items) => items.isEmpty,
        emptyMessage: 'No hay procesos disponibles.',
        builder: (items) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final process = items[index];
                return Card(
                  child: ListTile(
                    title: Text(process.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(RouteNames.processDetails(process.id)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProcessDetailPage extends ConsumerWidget {
  const ProcessDetailPage({super.key, required this.processId});

  final String processId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(processDetailViewModelProvider(processId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del proceso')),
      body: AsyncContent<ProcessDetailState>(
        value: result,
        errorMessage: 'No se pudo cargar el proceso.',
        onRetry: () =>
            ref.invalidate(processDetailViewModelProvider(processId)),
        builder: (data) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  data.process.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Versiones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push(RouteNames.processHistory(processId)),
                      icon: const Icon(Icons.history),
                      label: const Text('Historial'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.versions.isEmpty)
                  const EmptyState(message: 'Este proceso no tiene versiones.'),
                for (final version in data.versions)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text('Versión ${version.officialVersion}'),
                      subtitle: Text(
                        '${version.status.label} · ${_formatDate(version.versionDate)} · '
                        'Revisión ${version.revision}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        RouteNames.processStructure(processId, version.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProcessHistoryPage extends ConsumerWidget {
  const ProcessHistoryPage({super.key, required this.processId});

  final String processId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(processDetailViewModelProvider(processId));
    return Scaffold(
      appBar: AppBar(title: const Text('Historial del proceso')),
      body: AsyncContent<ProcessDetailState>(
        value: result,
        errorMessage: 'No se pudo cargar el historial.',
        onRetry: () =>
            ref.invalidate(processDetailViewModelProvider(processId)),
        builder: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            for (final version in data.versions)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text('Versión ${version.officialVersion}'),
                  subtitle: Text(
                    '${version.status.label} · ${_formatDate(version.versionDate)}',
                  ),
                  trailing: const Icon(Icons.visibility_outlined),
                  onTap: () => context.push(
                    RouteNames.processStructure(processId, version.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProcessEditorPage extends ConsumerStatefulWidget {
  const ProcessEditorPage({
    super.key,
    required this.processId,
    required this.versionId,
  });

  final String processId;
  final String versionId;

  @override
  ConsumerState<ProcessEditorPage> createState() => _ProcessEditorPageState();
}

class _ProcessEditorPageState extends ConsumerState<ProcessEditorPage> {
  String? _selectedNodeId;

  (String, String) get _key => (widget.processId, widget.versionId);

  @override
  Widget build(BuildContext context) {
    final provider = processEditorViewModelProvider(_key);
    final editor = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final canEdit = notifier.canEdit;

    return PopScope(
      canPop: !notifier.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && notifier.hasUnsavedChanges) {
          final discard = await _confirmDiscard(context);
          if (discard && context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estructura'),
          actions: [
            if (editor.value != null && notifier.hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Center(child: Text('Cambios sin guardar')),
              ),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilledButton.icon(
                  key: const ValueKey('process-draft-save'),
                  onPressed: editor.value?.isSaving == true
                      ? null
                      : () => _save(context, notifier),
                  icon: editor.value?.isSaving == true
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
          ],
        ),
        body: AsyncContent<ProcessEditorState>(
          value: editor,
          errorMessage: 'No se pudo cargar la estructura del proceso.',
          onRetry: () => ref.invalidate(provider),
          builder: (data) {
            if (data.draft.macroActivities.isEmpty) {
              return const EmptyState(
                message: 'Esta versión todavía no tiene macroactividades.',
              );
            }
            final selectedMacroIndex = data.draft.macroActivities.indexWhere(
              (macro) =>
                  macro.id == _selectedNodeId ||
                  macro.activities.any(
                    (activity) => activity.id == _selectedNodeId,
                  ),
            );
            final macroIndex = selectedMacroIndex < 0 ? 0 : selectedMacroIndex;
            final macro = data.draft.macroActivities[macroIndex];
            final activityIndex = macro.activities.indexWhere(
              (activity) => activity.id == _selectedNodeId,
            );
            final isActivitySelected = activityIndex >= 0;

            return Column(
              children: [
                _VersionSummary(draft: data.draft, canEdit: canEdit),
                if (!canEdit)
                  const MaterialBanner(
                    content: Text('Versión en modo de consulta.'),
                    leading: Icon(Icons.lock_outline),
                    actions: [SizedBox.shrink()],
                  ),
                if (data.actionFailure != null)
                  _FailureBanner(
                    failure: data.actionFailure!,
                    onResolveConflict: data.actionFailure is ConflictFailure
                        ? () => _resolveConflict(context, notifier)
                        : null,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tree = _ProcessTree(
                        draft: data.draft,
                        selectedNodeId: _selectedNodeId ?? macro.id,
                        onSelect: (id) => setState(() => _selectedNodeId = id),
                      );
                      final detail = _StructureDetail(
                        key: ValueKey('${macro.id}:$activityIndex'),
                        macroIndex: macroIndex,
                        activityIndex: isActivitySelected
                            ? activityIndex
                            : null,
                        state: data,
                        canEdit: canEdit,
                        notifier: notifier,
                      );
                      if (constraints.maxWidth < 820) {
                        return Column(
                          children: [
                            SizedBox(height: 190, child: tree),
                            const Divider(height: 1),
                            Expanded(child: detail),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: 300, child: tree),
                          const VerticalDivider(width: 1),
                          Expanded(child: detail),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    ProcessEditorViewModel notifier,
  ) async {
    final saved = await notifier.save();
    if (saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Borrador guardado.')));
    }
  }

  Future<void> _resolveConflict(
    BuildContext context,
    ProcessEditorViewModel notifier,
  ) async {
    final reload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('El borrador cambió'),
        content: const Text(
          'Otra persona guardó una revisión más reciente. '
          '¿Querés recargarla y descartar tus cambios locales?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recargar borrador'),
          ),
        ],
      ),
    );
    if (reload == true) await notifier.reload();
  }

  Future<bool> _confirmDiscard(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text('¿Querés salir y descartar los cambios?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar cambios'),
            ),
          ],
        ),
      ) ??
      false;
}

class _VersionSummary extends StatelessWidget {
  const _VersionSummary({required this.draft, required this.canEdit});

  final ProcessVersionDraft draft;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Versión ${draft.officialVersion} · ${draft.status.label} · '
            'Revisión ${draft.revision}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (canEdit)
          const Chip(
            avatar: Icon(Icons.edit_outlined, size: 16),
            label: Text('Borrador editable'),
          ),
      ],
    ),
  );
}

class _ProcessTree extends StatelessWidget {
  const _ProcessTree({
    required this.draft,
    required this.selectedNodeId,
    required this.onSelect,
  });

  final ProcessVersionDraft draft;
  final String? selectedNodeId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    children: [
      for (final macro in draft.macroActivities)
        ExpansionTile(
          key: PageStorageKey(macro.id),
          initiallyExpanded:
              macro.id == selectedNodeId ||
              macro.activities.any((activity) => activity.id == selectedNodeId),
          title: Text(macro.name),
          subtitle: Text(
            '${macro.inputs.length} entradas · ${macro.activities.length} actividades · '
            '${macro.outputs.length} salidas',
          ),
          onExpansionChanged: (_) => onSelect(macro.id),
          children: [
            ListTile(
              dense: true,
              selected: macro.id == selectedNodeId,
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Macroactividad'),
              onTap: () => onSelect(macro.id),
            ),
            for (final activity in macro.activities)
              ListTile(
                dense: true,
                selected: activity.id == selectedNodeId,
                contentPadding: const EdgeInsets.only(left: 40, right: 16),
                leading: const Icon(Icons.playlist_add_check),
                title: Text(activity.name),
                subtitle: Text('${activity.records.length} registros'),
                onTap: () => onSelect(activity.id),
              ),
          ],
        ),
    ],
  );
}

class _StructureDetail extends StatelessWidget {
  const _StructureDetail({
    super.key,
    required this.macroIndex,
    required this.activityIndex,
    required this.state,
    required this.canEdit,
    required this.notifier,
  });

  final int macroIndex;
  final int? activityIndex;
  final ProcessEditorState state;
  final bool canEdit;
  final ProcessEditorViewModel notifier;

  @override
  Widget build(BuildContext context) {
    final macro = state.draft.macroActivities[macroIndex];
    if (activityIndex != null) {
      final activity = macro.activities[activityIndex!];
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(activity.name, style: Theme.of(context).textTheme.titleLarge),
          if (activity.instructions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(activity.instructions),
          ],
          const SizedBox(height: AppSpacing.xl),
          _EvidenceSection(
            title: 'Registros de la actividad',
            addLabel: 'Agregar registro',
            items: activity.records,
            canEdit: canEdit,
            fieldErrors: state.fieldErrors,
            fieldPath:
                'macroActivities[$macroIndex].activities[$activityIndex].records',
            onAdd: () => _add(context, EvidenceSection.records),
            onEdit: (index) => _edit(context, EvidenceSection.records, index),
            onRemove: (index) =>
                _remove(context, EvidenceSection.records, index),
            onMove: (index, offset) => notifier.moveEvidence(
              macroIndex: macroIndex,
              section: EvidenceSection.records,
              activityIndex: activityIndex,
              evidenceIndex: index,
              offset: offset,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(macro.name, style: Theme.of(context).textTheme.titleLarge),
        if (macro.description?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(macro.description!),
        ],
        const SizedBox(height: AppSpacing.xl),
        _EvidenceSection(
          title: 'Entradas',
          addLabel: 'Agregar entrada',
          items: macro.inputs,
          canEdit: canEdit,
          fieldErrors: state.fieldErrors,
          fieldPath: 'macroActivities[$macroIndex].inputs',
          onAdd: () => _add(context, EvidenceSection.inputs),
          onEdit: (index) => _edit(context, EvidenceSection.inputs, index),
          onRemove: (index) => _remove(context, EvidenceSection.inputs, index),
          onMove: (index, offset) => notifier.moveEvidence(
            macroIndex: macroIndex,
            section: EvidenceSection.inputs,
            evidenceIndex: index,
            offset: offset,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _EvidenceSection(
          title: 'Salidas',
          addLabel: 'Agregar salida',
          items: macro.outputs,
          canEdit: canEdit,
          fieldErrors: state.fieldErrors,
          fieldPath: 'macroActivities[$macroIndex].outputs',
          onAdd: () => _add(context, EvidenceSection.outputs),
          onEdit: (index) => _edit(context, EvidenceSection.outputs, index),
          onRemove: (index) => _remove(context, EvidenceSection.outputs, index),
          onMove: (index, offset) => notifier.moveEvidence(
            macroIndex: macroIndex,
            section: EvidenceSection.outputs,
            evidenceIndex: index,
            offset: offset,
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, EvidenceSection section) async {
    final config = await _editEvidenceDialog(context, notifier, null);
    if (config == null) return;
    notifier.addEvidence(
      macroIndex: macroIndex,
      section: section,
      activityIndex: activityIndex,
      definition: config.definition,
      displayName: config.displayName,
      applicability: config.applicability,
      cardinality: config.cardinality,
    );
  }

  Future<void> _edit(
    BuildContext context,
    EvidenceSection section,
    int index,
  ) async {
    final macro = state.draft.macroActivities[macroIndex];
    final items = switch (section) {
      EvidenceSection.inputs => macro.inputs,
      EvidenceSection.outputs => macro.outputs,
      EvidenceSection.records => macro.activities[activityIndex!].records,
    };
    final config = await _editEvidenceDialog(context, notifier, items[index]);
    if (config == null) return;
    notifier.updateEvidence(
      macroIndex: macroIndex,
      section: section,
      activityIndex: activityIndex,
      evidenceIndex: index,
      definition: config.definition,
      displayName: config.displayName,
      applicability: config.applicability,
      cardinality: config.cardinality,
    );
  }

  Future<void> _remove(
    BuildContext context,
    EvidenceSection section,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar evidencia'),
        content: const Text(
          'Al guardar, esta evidencia se eliminará del borrador. ¿Querés continuar?',
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
        macroIndex: macroIndex,
        section: section,
        activityIndex: activityIndex,
        evidenceIndex: index,
      );
    }
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.title,
    required this.addLabel,
    required this.items,
    required this.canEdit,
    required this.fieldErrors,
    required this.fieldPath,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
  });

  final String title;
  final String addLabel;
  final List<EvidenceExpectation> items;
  final bool canEdit;
  final Map<String, String> fieldErrors;
  final String fieldPath;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onMove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (canEdit)
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            'No hay evidencias configuradas.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      for (var index = 0; index < items.length; index++)
        _EvidenceTile(
          item: items[index],
          index: index,
          count: items.length,
          canEdit: canEdit,
          fieldError: _fieldErrorFor(fieldErrors, '$fieldPath[$index]'),
          onEdit: () => onEdit(index),
          onRemove: () => onRemove(index),
          onMoveUp: () => onMove(index, -1),
          onMoveDown: () => onMove(index, 1),
        ),
    ],
  );
}

String? _fieldErrorFor(Map<String, String> errors, String path) {
  for (final entry in errors.entries) {
    if (entry.key.startsWith(path)) return entry.value;
  }
  return null;
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.item,
    required this.index,
    required this.count,
    required this.canEdit,
    required this.fieldError,
    required this.onEdit,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final EvidenceExpectation item;
  final int index;
  final int count;
  final bool canEdit;
  final String? fieldError;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.effectiveName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${item.registryDefinition.evidenceType.label} · '
                      '${item.applicability.label} · ${item.cardinality.label}',
                    ),
                    if (item.displayName.trim().isNotEmpty)
                      Text(
                        'Catálogo: ${item.registryDefinition.canonicalName}',
                      ),
                    if (item.registryDefinition.officialNomenclature != null)
                      Text(
                        'Nomenclatura: ${item.registryDefinition.officialNomenclature}',
                      ),
                  ],
                ),
              ),
              if (canEdit) ...[
                IconButton(
                  tooltip: 'Mover arriba',
                  onPressed: index == 0 ? null : onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Mover abajo',
                  onPressed: index == count - 1 ? null : onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Editar evidencia',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Quitar evidencia',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          if (fieldError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                fieldError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failure, this.onResolveConflict});

  final AppFailure failure;
  final VoidCallback? onResolveConflict;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(failure.message),
    leading: Icon(
      Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
    ),
    actions: [
      if (onResolveConflict != null)
        TextButton(
          onPressed: onResolveConflict,
          child: const Text('Resolver conflicto'),
        )
      else
        const SizedBox.shrink(),
    ],
  );
}

class _EvidenceConfig {
  const _EvidenceConfig({
    required this.definition,
    required this.displayName,
    required this.applicability,
    required this.cardinality,
  });

  final RegistryDefinition definition;
  final String displayName;
  final ApplicabilityMode applicability;
  final EvidenceCardinality cardinality;
}

Future<_EvidenceConfig?> _editEvidenceDialog(
  BuildContext context,
  ProcessEditorViewModel notifier,
  EvidenceExpectation? original,
) => showDialog<_EvidenceConfig>(
  context: context,
  builder: (context) =>
      _EvidenceConfigDialog(notifier: notifier, original: original),
);

class _EvidenceConfigDialog extends StatefulWidget {
  const _EvidenceConfigDialog({required this.notifier, required this.original});

  final ProcessEditorViewModel notifier;
  final EvidenceExpectation? original;

  @override
  State<_EvidenceConfigDialog> createState() => _EvidenceConfigDialogState();
}

class _EvidenceConfigDialogState extends State<_EvidenceConfigDialog> {
  late final TextEditingController _displayNameController;
  RegistryDefinition? _definition;
  late ApplicabilityMode _applicability;
  late EvidenceCardinality _cardinality;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    _definition = original?.registryDefinition;
    _displayNameController = TextEditingController(
      text: original?.displayName ?? '',
    );
    _applicability = original?.applicability ?? ApplicabilityMode.always;
    _cardinality = original?.cardinality ?? EvidenceCardinality.one;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.original == null ? 'Agregar evidencia' : 'Editar evidencia',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro del catálogo',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _definition == null
                        ? 'No se seleccionó un registro.'
                        : '${_definition!.canonicalName} · ${_definition!.evidenceType.label}',
                  ),
                ),
                TextButton(
                  onPressed: _selectDefinition,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
            if (_definition?.officialNomenclature?.isNotEmpty == true)
              Text('Nomenclatura: ${_definition!.officialNomenclature}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre mostrado en este proceso',
                hintText: 'Opcional',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ApplicabilityMode>(
              initialValue: _applicability,
              decoration: const InputDecoration(labelText: 'Cuándo se exige'),
              items: [
                for (final value in ApplicabilityMode.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) => setState(() => _applicability = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<EvidenceCardinality>(
              initialValue: _cardinality,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              items: [
                for (final value in EvidenceCardinality.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
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
                  definition: _definition!,
                  displayName: _displayNameController.text,
                  applicability: _applicability,
                  cardinality: _cardinality,
                ),
              ),
        child: const Text('Guardar'),
      ),
    ],
  );

  Future<void> _selectDefinition() async {
    final selected = await showDialog<RegistryDefinition>(
      context: context,
      builder: (context) => RegistryCatalogDialog(notifier: widget.notifier),
    );
    if (selected != null && mounted) setState(() => _definition = selected);
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
