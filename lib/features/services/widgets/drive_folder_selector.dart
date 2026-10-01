import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/service_models.dart';

class DriveFolderSelector extends StatelessWidget {
  const DriveFolderSelector({
    super.key,
    this.selectedId,
    this.selectedName,
    this.initialFailure,
    required this.loadPage,
    required this.onSelected,
    required this.onClear,
  });

  final String? selectedId;
  final String? selectedName;
  final AppFailure? initialFailure;
  final Future<PagedResult<DriveFolderOption>> Function({
    required String query,
    required int page,
  }) loadPage;
  final ValueChanged<DriveFolderOption> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carpeta de evidencia en Google Drive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (selectedId != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.folder_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(selectedName ?? 'Carpeta seleccionada'),
                  ),
                  IconButton(
                    tooltip: 'Quitar carpeta',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ] else
              const Text('No hay una carpeta configurada.'),
            if (initialFailure case final failure?) ...[
              const SizedBox(height: AppSpacing.sm),
              AppErrorView(failure: failure),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDialog<DriveFolderOption>(
                  context: context,
                  builder: (_) => _DriveFolderDialog(
                    selectedId: selectedId,
                    loadPage: loadPage,
                  ),
                );
                if (selected != null) onSelected(selected);
              },
              icon: const Icon(Icons.search),
              label: Text(
                selectedId == null ? 'Seleccionar carpeta' : 'Cambiar carpeta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveFolderDialog extends StatefulWidget {
  const _DriveFolderDialog({
    required this.selectedId,
    required this.loadPage,
  });

  final String? selectedId;
  final Future<PagedResult<DriveFolderOption>> Function({
    required String query,
    required int page,
  }) loadPage;

  @override
  State<_DriveFolderDialog> createState() => _DriveFolderDialogState();
}

class _DriveFolderDialogState extends State<_DriveFolderDialog> {
  final _queryController = TextEditingController();
  PagedResult<DriveFolderOption>? _result;
  AppFailure? _failure;
  bool _loading = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _failure = null;
      _page = nextPage;
    });
    try {
      final result = await widget.loadPage(
        query: _queryController.text.trim(),
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _failure = failure;
        _result = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = const UnexpectedFailure(
          'No se pudieron consultar las carpetas de Google Drive.',
        );
        _result = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar carpeta de Google Drive'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          height: 430,
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  labelText: 'Buscar carpeta',
                  suffixIcon: IconButton(
                    onPressed: () => _load(page: 0),
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => _load(page: 0),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _content(context)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_failure case final failure?) {
      return AppErrorView(
        failure: failure,
        onRetry: _load,
      );
    }

    final result = _result!;

    if (result.items.isEmpty) {
      return const EmptyState(
        message: 'No se encontraron carpetas accesibles.',
        icon: Icons.folder_outlined,
      );
    }

    return Column(
      children: [
        Expanded(
          child: RadioGroup<String>(
            groupValue: widget.selectedId,
            onChanged: (value) {
              if (value == null) return;

              final folder = result.items.firstWhere(
                (item) => item.id == value,
              );

              Navigator.of(context).pop(folder);
            },
            child: ListView.separated(
              itemCount: result.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final folder = result.items[index];

                return RadioListTile<String>(
                  value: folder.id,
                  title: Text(folder.name),
                  subtitle: Text(folder.path),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Página ${result.page.page + 1} de ${result.page.totalPages}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: result.page.hasPrevious
                  ? () => _load(page: result.page.page - 1)
                  : null,
              tooltip: 'Página anterior',
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: result.page.hasNext
                  ? () => _load(page: result.page.page + 1)
                  : null,
              tooltip: 'Página siguiente',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
