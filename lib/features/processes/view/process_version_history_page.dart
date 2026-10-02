import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/process_models.dart';
import '../viewmodel/process_history_view_model.dart';

class ProcessVersionHistoryPage extends ConsumerWidget {
  const ProcessVersionHistoryPage({super.key, required this.processId});

  final String processId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(processHistoryViewModelProvider(processId));
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de versiones'),
        actions: [
          if (isAdmin && history.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: FilledButton.icon(
                onPressed: history.value?.isCreatingVersion == true
                    ? null
                    : () => _createVersion(context, ref, history.value!),
                icon: history.value?.isCreatingVersion == true
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.note_add_outlined),
                label: const Text('Crear nueva versión'),
              ),
            ),
        ],
      ),
      body: AsyncContent<ProcessHistoryState>(
        value: history,
        errorMessage: 'No se pudo cargar el historial de versiones.',
        onRetry: () => ref.invalidate(processHistoryViewModelProvider(processId)),
        builder: (data) => Column(
          children: [
            if (data.actionFailure != null)
              _HistoryFailureBanner(
                failure: data.actionFailure!,
                onDismiss: () => ref
                    .read(processHistoryViewModelProvider(processId).notifier)
                    .clearActionFailure(),
              ),
            Expanded(
              child: data.versions.isEmpty
                  ? const EmptyState(message: 'Este proceso no tiene versiones.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: data.versions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final version = data.versions[index];
                        return _VersionHistoryTile(
                          version: version,
                          isAdmin: isAdmin,
                          onOpen: () => context.push(
                            RouteNames.processVersion(processId, version.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createVersion(
    BuildContext context,
    WidgetRef ref,
    ProcessHistoryState state,
  ) async {
    final result = await showDialog<_NewVersionInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateVersionDialog(versions: state.versions),
    );
    if (!context.mounted || result == null) return;

    final version = await ref
        .read(processHistoryViewModelProvider(processId).notifier)
        .createDraftVersion(
          officialVersion: result.officialVersion,
          versionDate: result.versionDate,
          copyFromVersionId: result.copyFromVersionId,
        );
    if (!context.mounted || version == null) return;
    context.push(RouteNames.processVersion(processId, version.id));
  }
}

class _VersionHistoryTile extends StatelessWidget {
  const _VersionHistoryTile({
    required this.version,
    required this.isAdmin,
    required this.onOpen,
  });

  final ProcessVersion version;
  final bool isAdmin;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (version.status) {
      ProcessVersionStatus.draft => StatusTone.warning,
      ProcessVersionStatus.published => StatusTone.success,
      ProcessVersionStatus.archived => StatusTone.neutral,
      ProcessVersionStatus.unknown => StatusTone.neutral,
    };

    return Card(
      child: ListTile(
        onTap: onOpen,
        title: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Versión ${version.officialVersion}',
              style: theme.textTheme.titleMedium,
            ),
            StatusChip(label: version.status.label, tone: tone),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Text('Fecha de versión: ${_date(version.versionDate)}'),
              Text('Creada: ${_dateTime(version.createdAt)}'),
              if (version.publishedAt != null)
                Text('Publicada: ${_dateTime(version.publishedAt!)}'),
            ],
          ),
        ),
        trailing: Icon(
          isAdmin && version.status.isDraft
              ? Icons.edit_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}

class _HistoryFailureBanner extends StatelessWidget {
  const _HistoryFailureBanner({required this.failure, required this.onDismiss});

  final AppFailure failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          0,
        ),
        child: MaterialBanner(
          content: Text(failure.message),
          leading: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          actions: [
            TextButton(onPressed: onDismiss, child: const Text('Cerrar')),
          ],
        ),
      );
}

class _NewVersionInput {
  const _NewVersionInput({
    required this.officialVersion,
    required this.versionDate,
    this.copyFromVersionId,
  });

  final String officialVersion;
  final DateTime versionDate;
  final String? copyFromVersionId;
}

class _CreateVersionDialog extends StatefulWidget {
  const _CreateVersionDialog({required this.versions});

  final List<ProcessVersion> versions;

  @override
  State<_CreateVersionDialog> createState() => _CreateVersionDialogState();
}

class _CreateVersionDialogState extends State<_CreateVersionDialog> {
  final _versionController = TextEditingController();
  DateTime? _versionDate;
  String _copySelection = '';
  String? _error;

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Crear nueva versión'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _versionController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Versión oficial',
                  hintText: '2.0',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _versionDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _versionDate = picked;
                      _error = null;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _versionDate == null
                      ? 'Seleccionar fecha de versión'
                      : 'Fecha: ${_date(_versionDate!)}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _copySelection,
                decoration: const InputDecoration(
                  labelText: 'Contenido inicial',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Empezar en blanco'),
                  ),
                  for (final version in widget.versions)
                    DropdownMenuItem(
                      value: version.id,
                      child: Text(
                        'Copiar versión ${version.officialVersion} · '
                        '${_date(version.versionDate)}',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _copySelection = value ?? '';
                  _error = null;
                }),
              ),
              if (_copySelection.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Se crea una copia independiente; la versión de origen no cambia.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Crear borrador'),
        ),
      ],
    );
  }

  void _submit() {
    final officialVersion = _versionController.text.trim();
    if (officialVersion.isEmpty || _versionDate == null) {
      setState(() {
        _error = officialVersion.isEmpty
            ? 'Ingresá el nombre o número de versión.'
            : 'Seleccioná la fecha de versión.';
      });
      return;
    }
    Navigator.of(context).pop(
      _NewVersionInput(
        officialVersion: officialVersion,
        versionDate: _versionDate!,
        copyFromVersionId:
            _copySelection.isEmpty ? null : _copySelection,
      ),
    );
  }
}

String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

String _dateTime(DateTime value) => DateFormat('dd/MM/yyyy HH:mm').format(value);