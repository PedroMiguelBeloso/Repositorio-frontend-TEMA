import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';

class ProcessTreeView extends StatelessWidget {
  const ProcessTreeView({
    super.key,
    required this.macroActivities,
    required this.selectedNode,
    required this.readOnly,
    required this.onSelectMacro,
    required this.onSelectActivity,
    required this.onAddMacro,
    required this.onDeleteMacro,
    required this.onMoveMacro,
    required this.onAddActivity,
    required this.onDeleteActivity,
    required this.onMoveActivity,
  });

  final List<ProcessMacroActivity> macroActivities;
  final ProcessNodeSelection? selectedNode;
  final bool readOnly;
  final ValueChanged<String> onSelectMacro;
  final void Function(String macroKey, String activityKey) onSelectActivity;
  final VoidCallback onAddMacro;
  final ValueChanged<ProcessMacroActivity> onDeleteMacro;
  final void Function(String macroKey, int delta) onMoveMacro;
  final ValueChanged<String> onAddActivity;
  final void Function(String macroKey, String activityKey) onDeleteActivity;
  final void Function(String macroKey, String activityKey, int delta)
      onMoveActivity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Estructura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!readOnly)
                  IconButton(
                    tooltip: 'Agregar macroactividad',
                    onPressed: onAddMacro,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (macroActivities.isEmpty)
              const EmptyState(
                message: 'No hay macroactividades cargadas.',
                icon: Icons.account_tree_outlined,
              )
            else
              for (var macroIndex = 0;
                  macroIndex < macroActivities.length;
                  macroIndex++)
                _MacroTreeItem(
                  macro: macroActivities[macroIndex],
                  macroIndex: macroIndex,
                  macroCount: macroActivities.length,
                  selectedNode: selectedNode,
                  readOnly: readOnly,
                  onSelectMacro: onSelectMacro,
                  onSelectActivity: onSelectActivity,
                  onDeleteMacro: onDeleteMacro,
                  onMoveMacro: onMoveMacro,
                  onAddActivity: onAddActivity,
                  onDeleteActivity: onDeleteActivity,
                  onMoveActivity: onMoveActivity,
                ),
            if (!readOnly) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onAddMacro,
                icon: const Icon(Icons.add),
                label: const Text('Agregar macroactividad'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroTreeItem extends StatelessWidget {
  const _MacroTreeItem({
    required this.macro,
    required this.macroIndex,
    required this.macroCount,
    required this.selectedNode,
    required this.readOnly,
    required this.onSelectMacro,
    required this.onSelectActivity,
    required this.onDeleteMacro,
    required this.onMoveMacro,
    required this.onAddActivity,
    required this.onDeleteActivity,
    required this.onMoveActivity,
  });

  final ProcessMacroActivity macro;
  final int macroIndex;
  final int macroCount;
  final ProcessNodeSelection? selectedNode;
  final bool readOnly;
  final ValueChanged<String> onSelectMacro;
  final void Function(String macroKey, String activityKey) onSelectActivity;
  final ValueChanged<ProcessMacroActivity> onDeleteMacro;
  final void Function(String macroKey, int delta) onMoveMacro;
  final ValueChanged<String> onAddActivity;
  final void Function(String macroKey, String activityKey) onDeleteActivity;
  final void Function(String macroKey, String activityKey, int delta)
      onMoveActivity;

  @override
  Widget build(BuildContext context) {
    final isMacroSelected = selectedNode?.type == ProcessNodeType.macroActivity &&
        selectedNode?.macroKey == macro.localKey;
    final title = macro.name.trim().isEmpty
        ? 'Macroactividad ${macroIndex + 1}'
        : macro.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ExpansionTile(
        key: PageStorageKey('macro-tree-${macro.localKey}'),
        initiallyExpanded: selectedNode?.macroKey == macro.localKey,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        childrenPadding: const EdgeInsets.only(left: AppSpacing.md),
        leading: const Icon(Icons.folder_outlined),
        title: InkWell(
          onTap: () => onSelectMacro(macro.localKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isMacroSelected ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
        trailing: readOnly
            ? null
            : Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Subir macroactividad',
                    onPressed: macroIndex == 0
                        ? null
                        : () => onMoveMacro(macro.localKey, -1),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Bajar macroactividad',
                    onPressed: macroIndex + 1 == macroCount
                        ? null
                        : () => onMoveMacro(macro.localKey, 1),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Eliminar macroactividad',
                    onPressed: () => onDeleteMacro(macro),
                    color: Theme.of(context).colorScheme.error,
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
        children: [
          if (macro.activities.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sin actividades',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            for (var activityIndex = 0;
                activityIndex < macro.activities.length;
                activityIndex++)
              _ActivityTreeItem(
                macroKey: macro.localKey,
                activity: macro.activities[activityIndex],
                activityIndex: activityIndex,
                activityCount: macro.activities.length,
                selectedNode: selectedNode,
                readOnly: readOnly,
                onSelectActivity: onSelectActivity,
                onDeleteActivity: onDeleteActivity,
                onMoveActivity: onMoveActivity,
              ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onAddActivity(macro.localKey),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar actividad'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTreeItem extends StatelessWidget {
  const _ActivityTreeItem({
    required this.macroKey,
    required this.activity,
    required this.activityIndex,
    required this.activityCount,
    required this.selectedNode,
    required this.readOnly,
    required this.onSelectActivity,
    required this.onDeleteActivity,
    required this.onMoveActivity,
  });

  final String macroKey;
  final ProcessActivity activity;
  final int activityIndex;
  final int activityCount;
  final ProcessNodeSelection? selectedNode;
  final bool readOnly;
  final void Function(String macroKey, String activityKey) onSelectActivity;
  final void Function(String macroKey, String activityKey) onDeleteActivity;
  final void Function(String macroKey, String activityKey, int delta)
      onMoveActivity;

  @override
  Widget build(BuildContext context) {
    final selected = selectedNode?.type == ProcessNodeType.activity &&
        selectedNode?.activityKey == activity.localKey;
    final title = activity.name.trim().isEmpty
        ? 'Actividad ${activityIndex + 1}'
        : activity.name;

    return ListTile(
      dense: true,
      selected: selected,
      leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
      title: Text(title),
      onTap: () => onSelectActivity(macroKey, activity.localKey),
      trailing: readOnly
          ? null
          : Wrap(
              spacing: 0,
              children: [
                IconButton(
                  tooltip: 'Subir actividad',
                  onPressed: activityIndex == 0
                      ? null
                      : () => onMoveActivity(
                            macroKey,
                            activity.localKey,
                            -1,
                          ),
                  icon: const Icon(Icons.arrow_upward, size: 17),
                ),
                IconButton(
                  tooltip: 'Bajar actividad',
                  onPressed: activityIndex + 1 == activityCount
                      ? null
                      : () => onMoveActivity(
                            macroKey,
                            activity.localKey,
                            1,
                          ),
                  icon: const Icon(Icons.arrow_downward, size: 17),
                ),
                IconButton(
                  tooltip: 'Eliminar actividad',
                  onPressed: () =>
                      onDeleteActivity(macroKey, activity.localKey),
                  color: Theme.of(context).colorScheme.error,
                  icon: const Icon(Icons.delete_outline, size: 17),
                ),
              ],
            ),
    );
  }
}
