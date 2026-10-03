import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../model/process_models.dart';
import '../model/registry_definition.dart';
import '../viewmodel/registry_catalog_view_model.dart';

class RegistryIndexPage extends StatelessWidget {
  const RegistryIndexPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Índice de registros')),
    body: const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: RegistryCatalogContent(),
    ),
  );
}

Future<RegistryDefinition?> selectRegistryDefinition(BuildContext context) =>
    showDialog<RegistryDefinition>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 650),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seleccionar registro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                const Expanded(
                  child: RegistryCatalogContent(selectionMode: true),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

class RegistryCatalogContent extends ConsumerStatefulWidget {
  const RegistryCatalogContent({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  ConsumerState<RegistryCatalogContent> createState() =>
      _RegistryCatalogContentState();
}

class _RegistryCatalogContentState
    extends ConsumerState<RegistryCatalogContent> {
  final _query = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(registryCatalogViewModelProvider);
    final canCreate = ref.watch(sessionProvider)?.isAdmin == true;
    final notifier = ref.read(registryCatalogViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => notifier.search(value),
                  );
                },
              ),
            ),
            if (canCreate)
              OutlinedButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear registro'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    safeAppFailure(
                      error,
                      fallbackMessage: 'No se pudo cargar el índice.',
                    ).message,
                  ),
                  TextButton(
                    onPressed: notifier.refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (page) => page.items.isEmpty
                ? const Center(
                    child: Text('No hay registros para esta búsqueda.'),
                  )
                : ListView.separated(
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = page.items[index];
                      return ListTile(
                        title: Text(item.canonicalName),
                        subtitle: Text(
                          [
                            item.evidenceType.label,
                            if (item.officialNomenclature?.isNotEmpty == true)
                              'Nomenclatura: ${item.officialNomenclature}',
                          ].join(' · '),
                        ),
                        trailing: widget.selectionMode
                            ? const Icon(Icons.chevron_right)
                            : item.preloaded
                            ? const Tooltip(
                                message: 'Registro precargado',
                                child: Icon(Icons.lock_outline),
                              )
                            : null,
                        onTap: widget.selectionMode
                            ? () => Navigator.pop(context, item)
                            : null,
                      );
                    },
                  ),
          ),
        ),
        if (catalog.value case final page?)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Página ${page.page + 1} de ${page.totalPages == 0 ? 1 : page.totalPages}',
              ),
              IconButton(
                tooltip: 'Página anterior',
                onPressed: page.page > 0
                    ? () => notifier.goToPage(page.page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: page.page + 1 < page.totalPages
                    ? () => notifier.goToPage(page.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final created = await showDialog<RegistryDefinition>(
      context: context,
      builder: (context) => const _CreateRegistryDialog(),
    );
    if (created != null && mounted && widget.selectionMode) {
      Navigator.pop(this.context, created);
    }
  }
}

class _CreateRegistryDialog extends ConsumerStatefulWidget {
  const _CreateRegistryDialog();

  @override
  ConsumerState<_CreateRegistryDialog> createState() =>
      _CreateRegistryDialogState();
}

class _CreateRegistryDialogState extends ConsumerState<_CreateRegistryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nomenclature = TextEditingController();
  EvidenceType _type = EvidenceType.document;
  bool _saving = false;
  String? _failure;

  bool get _needsNomenclature =>
      _type == EvidenceType.document || _type == EvidenceType.folder;

  @override
  void dispose() {
    _name.dispose();
    _nomenclature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear registro del índice'),
    content: Form(
      key: _form,
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre del registro',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresá un nombre.'
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
                    (type) => type != EvidenceType.unknown,
                  ))
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _type = value!),
              ),
              if (_needsNomenclature) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nomenclature,
                  decoration: const InputDecoration(
                    labelText: 'Nomenclatura oficial',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'La nomenclatura es obligatoria para documentos y carpetas.'
                      : null,
                ),
              ],
              if (_failure != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _failure!,
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
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Guardando...' : 'Crear'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      final created = await ref
          .read(registryCatalogViewModelProvider.notifier)
          .create(
            canonicalName: _name.text,
            evidenceType: _type,
            officialNomenclature: _needsNomenclature
                ? _nomenclature.text
                : null,
          );
      if (mounted) Navigator.pop(context, created);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo crear el registro.',
        ).message;
      });
    }
  }
}
