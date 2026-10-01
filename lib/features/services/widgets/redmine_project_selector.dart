import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../model/service_models.dart';

class RedmineProjectSelector extends StatelessWidget {
  const RedmineProjectSelector({
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
  final Future<PagedResult<RedmineProjectOption>> Function({
    required int page,
  }) loadPage;
  final ValueChanged<RedmineProjectOption> onSelected;
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
              'Proyecto de Redmine',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (selectedId != null)
              Row(
                children: [
                  const Icon(Icons.assignment_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(selectedName ?? 'Proyecto seleccionado')),
                  IconButton(
                    tooltip: 'Quitar proyecto',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
                ],
              )
            else
              const Text('No hay un proyecto configurado.'),
            if (initialFailure case final failure?) ...[
              const SizedBox(height: 8),
              Text(
                failure.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDialog<RedmineProjectOption>(
                  context: context,
                  builder: (_) => _RedmineProjectDialog(
                    selectedId: selectedId,
                    loadPage: loadPage,
                  ),
                );
                if (selected != null) onSelected(selected);
              },
              icon: const Icon(Icons.search),
              label: Text(
                selectedId == null
                    ? 'Seleccionar proyecto'
                    : 'Cambiar proyecto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedmineProjectDialog extends StatefulWidget {
  const _RedmineProjectDialog({
    required this.selectedId,
    required this.loadPage,
  });

  final String? selectedId;
  final Future<PagedResult<RedmineProjectOption>> Function({
    required int page,
  }) loadPage;

  @override
  State<_RedmineProjectDialog> createState() => _RedmineProjectDialogState();
}

class _RedmineProjectDialogState extends State<_RedmineProjectDialog> {
  PagedResult<RedmineProjectOption>? _result;
  AppFailure? _failure;
  bool _loading = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _failure = null;
      _page = nextPage;
    });
    try {
      final result = await widget.loadPage(page: nextPage);
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
          'No se pudieron consultar los proyectos de Redmine.',
        );
        _result = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar proyecto de Redmine'),
      content: SizedBox(
        width: 600,
        height: 380,
        child: _content(context),
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
        Text(
          failure.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
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
      child: Text('No se encontraron proyectos visibles.'),
    );
  }

  return Column(
    children: [
      Expanded(
        child: RadioGroup<String>(
          groupValue: widget.selectedId,
          onChanged: (value) {
            if (value == null) return;

            final project = result.items.firstWhere(
              (item) => item.id == value,
            );

            Navigator.of(context).pop(project);
          },
          child: ListView.separated(
            itemCount: result.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final project = result.items[index];

              return RadioListTile<String>(
                value: project.id,
                title: Text(project.name),
                subtitle: project.identifier == null
                    ? null
                    : Text(project.identifier!),
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
