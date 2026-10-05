import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
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
  final Future<PagedResult<RedmineProjectOption>> Function({required int page})
  loadPage;
  final ValueChanged<RedmineProjectOption> onSelected;
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
              'Proyecto de Redmine',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (selectedId != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(selectedName ?? 'Proyecto seleccionado'),
                  ),
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
              const SizedBox(height: AppSpacing.sm),
              AppErrorView(failure: failure),
            ],
            const SizedBox(height: AppSpacing.md),
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
  final Future<PagedResult<RedmineProjectOption>> Function({required int page})
  loadPage;

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
    final viewport = MediaQuery.sizeOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      title: const Text('Seleccionar proyecto de Redmine'),
      content: SizedBox(
        width: math.min(600, math.max(1, viewport.width - 80)),
        height: math.min(
          380,
          math.max(1, viewport.height - keyboardHeight - 180),
        ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_failure case final failure?) {
      return AppErrorView(failure: failure, onRetry: _load);
    }

    final result = _result!;

    if (result.items.isEmpty) {
      return const EmptyState(
        message: 'No se encontraron proyectos visibles.',
        icon: Icons.assignment_outlined,
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
