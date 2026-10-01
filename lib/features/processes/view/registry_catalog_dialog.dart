import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../model/evidence_expectation.dart';
import '../viewmodel/process_view_models.dart';

class RegistryCatalogDialog extends StatefulWidget {
  const RegistryCatalogDialog({super.key, required this.notifier});

  final ProcessEditorViewModel notifier;

  @override
  State<RegistryCatalogDialog> createState() => _RegistryCatalogDialogState();
}

class _RegistryCatalogDialogState extends State<RegistryCatalogDialog> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<RegistryDefinition> _items = const [];
  AppFailure? _failure;
  var _page = 0;
  var _totalPages = 0;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _failure = null;
      _page = page;
    });
    try {
      final result = await widget.notifier.searchRegistry(
        query: _queryController.text,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = result.page;
        _totalPages = result.totalPages;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo consultar el catálogo.',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Seleccionar registro del catálogo'),
    content: SizedBox(
      width: 560,
      height: 480,
      child: Column(
        children: [
          TextField(
            controller: _queryController,
            decoration: InputDecoration(
              labelText: 'Buscar registros',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _queryController.clear();
                  _load();
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildResults()),
          if (!_isLoading && _failure == null)
            Row(
              children: [
                Text(
                  'Página ${_page + 1} de ${_totalPages == 0 ? 1 : _totalPages}',
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: _page > 0 ? () => _load(page: _page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: _page + 1 < _totalPages
                      ? () => _load(page: _page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
      FilledButton.icon(
        onPressed: _createDefinition,
        icon: const Icon(Icons.add),
        label: const Text('Crear registro en el catálogo'),
      ),
    ],
  );

  Widget _buildResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_failure!.message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No se encontraron registros.'));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.canonicalName),
          subtitle: Text(
            '${item.evidenceType.label}'
            '${item.officialNomenclature == null ? '' : ' · ${item.officialNomenclature}'}',
          ),
          trailing: item.preloaded
              ? const Tooltip(
                  message: 'Registro precargado, solo lectura',
                  child: Icon(Icons.lock_outline, size: 18),
                )
              : null,
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }

  Future<void> _createDefinition() async {
    final created = await showDialog<RegistryDefinition>(
      context: context,
      builder: (context) => _CreateRegistryDialog(notifier: widget.notifier),
    );
    if (created != null && mounted) Navigator.pop(context, created);
  }
}

class _CreateRegistryDialog extends StatefulWidget {
  const _CreateRegistryDialog({required this.notifier});

  final ProcessEditorViewModel notifier;

  @override
  State<_CreateRegistryDialog> createState() => _CreateRegistryDialogState();
}

class _CreateRegistryDialogState extends State<_CreateRegistryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nomenclatureController = TextEditingController();
  EvidenceType _type = EvidenceType.document;
  AppFailure? _failure;
  var _isSaving = false;

  bool get _needsNomenclature =>
      _type == EvidenceType.document || _type == EvidenceType.folder;

  @override
  void dispose() {
    _nameController.dispose();
    _nomenclatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear registro en el catálogo'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresá el nombre del registro.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<EvidenceType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evidencia',
                ),
                items: [
                  for (final type in EvidenceType.values.where(
                    (item) => item != EvidenceType.unknown,
                  ))
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _type = value!),
              ),
              if (_needsNomenclature) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nomenclatureController,
                  decoration: const InputDecoration(
                    labelText: 'Nomenclatura oficial',
                  ),
                  validator: (value) =>
                      _needsNomenclature &&
                          (value == null || value.trim().isEmpty)
                      ? 'La nomenclatura oficial es obligatoria.'
                      : null,
                ),
              ],
              if (_failure != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _failure!.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Crear y seleccionar'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _failure = null;
    });
    try {
      final created = await widget.notifier.createRegistryDefinition(
        canonicalName: _nameController.text,
        evidenceType: _type,
        officialNomenclature: _needsNomenclature
            ? _nomenclatureController.text
            : null,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo crear el registro.',
        );
        _isSaving = false;
      });
    }
  }
}
