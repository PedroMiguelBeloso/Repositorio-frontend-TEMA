import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/process_models.dart';
import '../viewmodel/process_list_view_model.dart';

class ProcessListPage extends ConsumerWidget {
  const ProcessListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(processListViewModelProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesos'),
        actions: [
          if (isAdmin &&
              (asyncState.value?.items.isNotEmpty ?? false) &&
              (asyncState.value?.availableCodes.isNotEmpty ?? false)) ...[
            FilledButton.icon(
              onPressed: asyncState.value?.isMutating == true
                  ? null
                  : () => _openNewProcessDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proceso'),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          failure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudieron cargar los procesos.',
          ),
          onRetry: () =>
              ref.read(processListViewModelProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return _EmptyProcesses(
              isAdmin: isAdmin,
              canCreate: data.availableCodes.isNotEmpty,
              onCreate: () => _openNewProcessDialog(context),
              failure: data.actionFailure,
            );
          }

          return Column(
            children: [
              if (data.actionFailure != null)
                _ActionFailureBanner(
                  failure: data.actionFailure!,
                  onDismiss: () => ref
                      .read(processListViewModelProvider.notifier)
                      .clearActionFailure(),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(processListViewModelProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: data.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final overview = data.items[index];
                      return _ProcessCard(
                        overview: overview,
                        isAdmin: isAdmin,
                        isBusy: data.isMutating,
                        onOpenHistory: () => context.push(
                          RouteNames.processHistory(overview.definition.id),
                        ),
                        onOpenVersion: (version) => context.push(
                          RouteNames.processVersion(
                            overview.definition.id,
                            version.id,
                          ),
                        ),
                        onStartDraft: () => _openStartDraftDialog(
                          context,
                          overview.definition,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openNewProcessDialog(BuildContext context) async {
    final result = await showDialog<_DraftCreatedResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NewProcessDialog(),
    );
    if (!context.mounted || result == null) return;
    context.push(RouteNames.processVersion(result.processId, result.versionId));
  }

  Future<void> _openStartDraftDialog(
    BuildContext context,
    ProcessDefinition definition,
  ) async {
    final result = await showDialog<_DraftCreatedResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StartFirstDraftDialog(definition: definition),
    );
    if (!context.mounted || result == null) return;
    context.push(RouteNames.processVersion(result.processId, result.versionId));
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({
    required this.overview,
    required this.isAdmin,
    required this.isBusy,
    required this.onOpenHistory,
    required this.onOpenVersion,
    required this.onStartDraft,
  });

  final ProcessOverview overview;
  final bool isAdmin;
  final bool isBusy;
  final VoidCallback onOpenHistory;
  final ValueChanged<ProcessVersion> onOpenVersion;
  final VoidCallback onStartDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = overview.versionToOpen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.definition.displayName,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(
                      label: overview.hasDraft
                          ? 'Borrador disponible'
                          : 'Sin borrador',
                      tone: overview.hasDraft
                          ? StatusTone.warning
                          : StatusTone.neutral,
                    ),
                    if (version != null)
                      Text(
                        'Versión ${version.officialVersion} · '
                        '${DateFormat('dd/MM/yyyy').format(version.versionDate)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
                if (version == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isAdmin
                        ? 'La definición existe, pero todavía no tiene una versión.'
                        : 'Todavía no hay una versión para consultar.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            );

            final openVersionAction = version != null
                ? FilledButton.icon(
                    onPressed: isBusy ? null : () => onOpenVersion(version),
                    icon: Icon(
                      isAdmin && version.status.isDraft
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                    ),
                    label: Text(
                      isAdmin && version.status.isDraft
                          ? 'Editar borrador'
                          : 'Consultar',
                    ),
                  )
                : isAdmin && overview.canStartFirstDraft
                    ? FilledButton.icon(
                        onPressed: isBusy ? null : onStartDraft,
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Iniciar borrador'),
                      )
                    : null;
            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ?openVersionAction,
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onOpenHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Historial'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.lg),
                  Align(alignment: Alignment.centerLeft, child: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: summary),
                const SizedBox(width: AppSpacing.lg),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyProcesses extends StatelessWidget {
  const _EmptyProcesses({
    required this.isAdmin,
    required this.canCreate,
    required this.onCreate,
    required this.failure,
  });

  final bool isAdmin;
  final bool canCreate;
  final VoidCallback onCreate;
  final AppFailure? failure;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (failure != null)
          _ActionFailureBanner(failure: failure!, onDismiss: null),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyState(
                  message:
                      'Todavía no hay procesos configurados para esta entrega.',
                  icon: Icons.account_tree_outlined,
                ),
                if (isAdmin && canCreate) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo proceso'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionFailureBanner extends StatelessWidget {
  const _ActionFailureBanner({required this.failure, required this.onDismiss});

  final AppFailure failure;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(failure.message)),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Cerrar mensaje',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewProcessDialog extends ConsumerStatefulWidget {
  const _NewProcessDialog();

  @override
  ConsumerState<_NewProcessDialog> createState() => _NewProcessDialogState();
}

class _NewProcessDialogState extends ConsumerState<_NewProcessDialog> {
  M1ProcessCode? _selectedCode;
  ProcessDefinition? _createdDefinition;
  final _versionController = TextEditingController();
  DateTime? _versionDate;
  String? _localError;

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(processListViewModelProvider).value;
    final busy = listState?.isMutating == true;
    final availableCodes = listState?.availableCodes ?? const <M1ProcessCode>[];
    final failure = listState?.actionFailure;
    final definition = _createdDefinition;

    return AlertDialog(
      title: Text(
        definition == null ? 'Nuevo proceso' : 'Iniciar primer borrador',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: definition == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elegí uno de los cuatro procesos previstos para M1.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RadioGroup<M1ProcessCode>(
                      groupValue: _selectedCode,
                      onChanged: (value) {
                        if (busy) return;
                        setState(() {
                          _selectedCode = value;
                          _localError = null;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final code in availableCodes)
                            RadioListTile<M1ProcessCode>(
                              value: code,
                              enabled: !busy,
                              title: Text(code.label),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    if (availableCodes.isEmpty)
                      const Text(
                        'Los cuatro procesos ya fueron creados. No hay nuevas '
                        'definiciones disponibles.',
                      ),
                    if (_localError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DialogError(message: _localError!),
                    ],
                    if (failure != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DialogError(message: failure.message),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${definition.displayName} ya fue creado. Completá los '
                      'datos de la primera versión para abrir el borrador.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DraftVersionFields(
                      controller: _versionController,
                      date: _versionDate,
                      enabled: !busy,
                      onDateChanged: (value) => setState(() {
                        _versionDate = value;
                        _localError = null;
                      }),
                    ),
                    if (_localError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DialogError(message: _localError!),
                    ],
                    if (failure != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'La definición del proceso ya existe, pero el borrador '
                        'todavía no se inició. Podés reintentar o cerrar este '
                        'diálogo y retomarlo desde el listado.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DialogError(message: failure.message),
                    ],
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : definition == null
                  ? _createDefinition
                  : _startDraft,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(definition == null ? 'Crear proceso' : 'Abrir borrador'),
        ),
      ],
    );
  }

  Future<void> _createDefinition() async {
    final code = _selectedCode;
    if (code == null) {
      setState(() => _localError = 'Seleccioná un proceso para continuar.');
      return;
    }
    final created = await ref
        .read(processListViewModelProvider.notifier)
        .createDefinition(code);
    if (!mounted || created == null) {
      final available = ref.read(processListViewModelProvider).value?.availableCodes;
      if (available != null && !available.contains(code)) {
        setState(() => _selectedCode = null);
      }
      return;
    }
    setState(() {
      _createdDefinition = created;
      _localError = null;
    });
  }

  Future<void> _startDraft() async {
    final definition = _createdDefinition!;
    final version = _versionController.text.trim();
    final date = _versionDate;
    if (version.isEmpty || date == null) {
      setState(() {
        _localError = version.isEmpty
            ? 'Ingresá la versión oficial.'
            : 'Seleccioná la fecha de versión.';
      });
      return;
    }

    final created = await ref
        .read(processListViewModelProvider.notifier)
        .startFirstDraft(
          processId: definition.id,
          officialVersion: version,
          versionDate: date,
        );
    if (!mounted || created == null) return;
    Navigator.of(context).pop(
      _DraftCreatedResult(processId: definition.id, versionId: created.id),
    );
  }
}

class _StartFirstDraftDialog extends ConsumerStatefulWidget {
  const _StartFirstDraftDialog({required this.definition});

  final ProcessDefinition definition;

  @override
  ConsumerState<_StartFirstDraftDialog> createState() =>
      _StartFirstDraftDialogState();
}

class _StartFirstDraftDialogState
    extends ConsumerState<_StartFirstDraftDialog> {
  final _versionController = TextEditingController();
  DateTime? _versionDate;
  String? _localError;

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(processListViewModelProvider).value;
    final busy = listState?.isMutating == true;
    final failure = listState?.actionFailure;

    return AlertDialog(
      title: const Text('Iniciar primer borrador'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.definition.displayName} ya existe. Completá la '
                'primera versión sin crear otra definición.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _DraftVersionFields(
                controller: _versionController,
                date: _versionDate,
                enabled: !busy,
                onDateChanged: (value) => setState(() {
                  _versionDate = value;
                  _localError = null;
                }),
              ),
              if (_localError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _DialogError(message: _localError!),
              ],
              if (failure != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _DialogError(message: failure.message),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: busy ? null : _startDraft,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Abrir borrador'),
        ),
      ],
    );
  }

  Future<void> _startDraft() async {
    final version = _versionController.text.trim();
    final date = _versionDate;
    if (version.isEmpty || date == null) {
      setState(() {
        _localError = version.isEmpty
            ? 'Ingresá la versión oficial.'
            : 'Seleccioná la fecha de versión.';
      });
      return;
    }

    final created = await ref
        .read(processListViewModelProvider.notifier)
        .startFirstDraft(
          processId: widget.definition.id,
          officialVersion: version,
          versionDate: date,
        );
    if (!mounted || created == null) return;
    Navigator.of(context).pop(
      _DraftCreatedResult(
        processId: widget.definition.id,
        versionId: created.id,
      ),
    );
  }
}

class _DraftVersionFields extends StatelessWidget {
  const _DraftVersionFields({
    required this.controller,
    required this.date,
    required this.enabled,
    required this.onDateChanged,
  });

  final TextEditingController controller;
  final DateTime? date;
  final bool enabled;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Versión oficial',
            hintText: 'Ej. 2.0',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: enabled
              ? () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: date ?? DateTime.now(),
                    helpText: 'Fecha de versión',
                    cancelText: 'Cancelar',
                    confirmText: 'Aceptar',
                  );
                  if (selected != null) onDateChanged(selected);
                }
              : null,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            date == null
                ? 'Seleccionar fecha de versión'
                : 'Fecha: ${DateFormat('dd/MM/yyyy').format(date!)}',
          ),
        ),
      ],
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}

class _DraftCreatedResult {
  const _DraftCreatedResult({required this.processId, required this.versionId});
  final String processId;
  final String versionId;
}
