import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';
import '../widgets/general_data_section.dart';
import '../widgets/policies_section.dart';
import '../widgets/process_structure_detail.dart';
import '../widgets/process_tree_view.dart';

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
  ProcessEditorKey get _providerKey => (
        processId: widget.processId,
        versionId: widget.versionId,
      );

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(processEditorViewModelProvider(_providerKey));
    final notifier = ref.read(processEditorViewModelProvider(_providerKey).notifier);
    final dirty = notifier.hasUnsavedChanges;

    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Proceso')),
        body: AppErrorView(
          failure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo cargar el proceso.',
          ),
          onRetry: () => ref
              .read(processEditorViewModelProvider(_providerKey).notifier)
              .reloadFromServer(),
        ),
      ),
      data: (state) => _buildEditor(context, state, dirty),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    ProcessEditorState state,
    bool dirty,
  ) {
    final session = ref.watch(sessionProvider);
    final canEdit = session?.isAdmin == true && state.version.status.isDraft;
    final notifier = ref.read(processEditorViewModelProvider(_providerKey).notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.definition.displayName),
          actions: [
            if (canEdit) ...[
              FilledButton.icon(
                onPressed: state.isSaving || !dirty
                    ? null
                    : () => notifier.save(),
                icon: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(state.isSaving ? 'Guardando...' : 'Guardar'),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Datos generales'),
              Tab(text: 'Políticas'),
              Tab(text: 'Estructura'),
            ],
          ),
        ),
        body: Column(
          children: [
            _EditorHeader(
              state: state,
              canEdit: canEdit,
              dirty: dirty,
            ),
            if (state.actionFailure != null)
              _EditorFailureBanner(
                failure: state.actionFailure!,
                onDismiss: notifier.clearActionFailure,
                onReload: state.actionFailure is ConflictFailure
                    ? () => _reloadAfterConflict(context, notifier)
                    : null,
              ),
            if (state.saveSucceeded)
              const _SuccessBanner(
                message: 'Borrador guardado correctamente.',
              ),
            Expanded(
              child: TabBarView(
                children: [
                  GeneralDataSection(
                    definition: state.definition,
                    version: state.version,
                    readOnly: !canEdit,
                    validationErrors: state.validationErrors,
                    onOfficialVersionChanged: notifier.updateOfficialVersion,
                    onVersionDateChanged: notifier.updateVersionDate,
                    onObjectiveChanged: notifier.updateObjective,
                    onOwnerChanged: notifier.updateOwner,
                  ),
                  PoliciesSection(
                    policies: state.version.policies,
                    readOnly: !canEdit,
                    validationErrors: state.validationErrors,
                    onAdd: notifier.addPolicy,
                    onTextChanged: notifier.updatePolicyText,
                    onDelete: notifier.removePolicy,
                    onMove: notifier.movePolicy,
                  ),
                  _StructureTab(
                    state: state,
                    readOnly: !canEdit,
                    onSelectMacro: notifier.selectMacroActivity,
                    onSelectActivity: notifier.selectActivity,
                    onAddMacro: notifier.addMacroActivity,
                    onDeleteMacro: (macro) =>
                        _deleteMacroActivity(context, notifier, macro),
                    onMoveMacro: notifier.moveMacroActivity,
                    onAddActivity: notifier.addActivity,
                    onDeleteActivity: ({
                      required macroKey,
                      required activityKey,
                    }) => notifier.removeActivity(
                      macroKey: macroKey,
                      activityKey: activityKey,
                    ),
                    onMoveActivity: ({
                      required macroKey,
                      required activityKey,
                      required delta,
                    }) => notifier.moveActivity(
                      macroKey: macroKey,
                      activityKey: activityKey,
                      delta: delta,
                    ),
                    onMacroChanged: notifier.updateMacroActivity,
                    onActivityChanged: notifier.updateActivity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadAfterConflict(
    BuildContext context,
    ProcessEditorViewModel notifier,
  ) async {
    final dirty = notifier.hasUnsavedChanges;
    if (dirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recargar versión'),
          content: const Text(
            'La versión cambió en el servidor. Recargar reemplazará los '
            'cambios locales que todavía no se guardaron.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Recargar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await notifier.reloadFromServer();
  }

  Future<void> _deleteMacroActivity(
    BuildContext context,
    ProcessEditorViewModel notifier,
    ProcessMacroActivity macro,
  ) async {
    if (macro.activities.isEmpty) {
      notifier.removeMacroActivity(macro.localKey);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar macroactividad'),
        content: Text(
          'La macroactividad contiene ${macro.activities.length} '
          'actividad(es). Si continuás, también se eliminarán del borrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.removeMacroActivity(macro.localKey);
  }


}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.state,
    required this.canEdit,
    required this.dirty,
  });

  final ProcessEditorState state;
  final bool canEdit;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${state.definition.displayName} · '
                'Versión ${state.version.officialVersion}',
                style: theme.textTheme.titleMedium,
              ),
              StatusChip(
                label: state.version.status.label,
                tone: state.version.status.isDraft
                    ? StatusTone.warning
                    : StatusTone.info,
              ),
              if (dirty && canEdit)
                const StatusChip(
                  label: 'Cambios sin guardar',
                  tone: StatusTone.warning,
                ),
              if (!canEdit)
                const StatusChip(
                  label: 'Modo consulta',
                  tone: StatusTone.neutral,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorFailureBanner extends StatelessWidget {
  const _EditorFailureBanner({
    required this.failure,
    required this.onDismiss,
    required this.onReload,
  });

  final AppFailure failure;
  final VoidCallback onDismiss;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: Text(failure.message)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onReload != null)
                    OutlinedButton.icon(
                      onPressed: onReload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recargar'),
                    ),
                  IconButton(
                    tooltip: 'Cerrar mensaje',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructureTab extends StatelessWidget {
  const _StructureTab({
    required this.state,
    required this.readOnly,
    required this.onSelectMacro,
    required this.onSelectActivity,
    required this.onAddMacro,
    required this.onDeleteMacro,
    required this.onMoveMacro,
    required this.onAddActivity,
    required this.onDeleteActivity,
    required this.onMoveActivity,
    required this.onMacroChanged,
    required this.onActivityChanged,
  });

  final ProcessEditorState state;
  final bool readOnly;
  final ValueChanged<String> onSelectMacro;
  final void Function(String macroKey, String activityKey) onSelectActivity;
  final VoidCallback onAddMacro;
  final ValueChanged<ProcessMacroActivity> onDeleteMacro;
  final void Function(String macroKey, int delta) onMoveMacro;
  final ValueChanged<String> onAddActivity;
  final void Function({
    required String macroKey,
    required String activityKey,
  }) onDeleteActivity;
  final void Function({
    required String macroKey,
    required String activityKey,
    required int delta,
  }) onMoveActivity;
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
    final tree = ProcessTreeView(
      macroActivities: state.version.macroActivities,
      selectedNode: state.selectedNode,
      readOnly: readOnly,
      onSelectMacro: onSelectMacro,
      onSelectActivity: onSelectActivity,
      onAddMacro: onAddMacro,
      onDeleteMacro: onDeleteMacro,
      onMoveMacro: onMoveMacro,
      onAddActivity: onAddActivity,
      onDeleteActivity: (macroKey, activityKey) => onDeleteActivity(
        macroKey: macroKey,
        activityKey: activityKey,
      ),
      onMoveActivity: (macroKey, activityKey, delta) => onMoveActivity(
        macroKey: macroKey,
        activityKey: activityKey,
        delta: delta,
      ),
    );
    final detail = ProcessStructureDetail(
      state: state,
      readOnly: readOnly,
      onMacroChanged: onMacroChanged,
      onActivityChanged: onActivityChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 920) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tree,
                const SizedBox(height: AppSpacing.lg),
                detail,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 390,
                height: constraints.maxHeight - AppSpacing.xl * 2,
                child: SingleChildScrollView(child: tree),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight - AppSpacing.xl * 2,
                  child: SingleChildScrollView(child: detail),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
