import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carpeta de evidencia en Google Drive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (selectedId != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.folder_outlined),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 8),
              _SourceFailure(message: failure.message),
            ],
            const SizedBox(height: 10),
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
      content: SizedBox(
        width: 600,
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
            const SizedBox(height: 12),
            Expanded(child: _content(context)),
          ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SourceFailure(message: failure.message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }

  final result = _result!;

  if (result.items.isEmpty) {
    return const Center(
      child: Text('No se encontraron carpetas accesibles.'),
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
          ),
          const SizedBox(width: 8),
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

class _SourceFailure extends StatelessWidget {
  const _SourceFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
