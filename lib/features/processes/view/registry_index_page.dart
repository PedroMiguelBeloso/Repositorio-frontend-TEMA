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
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: RegistryCatalogContent(),
        ),
      ),
    ),
  );
}

Future<RegistryDefinition?> selectRegistryDefinition(BuildContext context) =>
    showDialog<RegistryDefinition>(
      context: context,
      builder: (context) => ProviderScope(
        overrides: [
          registryCatalogViewModelProvider.overrideWith(
            RegistryCatalogViewModel.new,
          ),
        ],
        child: Dialog(
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
        if (!widget.selectionMode) ...[
          Semantics(
            header: true,
            child: Text(
              'Índice de registros',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Definiciones de referencia para las entradas, salidas y registros de actividades.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: widget.selectionMode ? 310 : 420,
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
              FilledButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear registro'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
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
                ? Center(
                    child: Text(
                      _query.text.trim().isEmpty
                          ? 'Todavía no hay registros en el índice.'
                          : 'No se encontraron registros para esta búsqueda.',
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      return SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppRadii.card),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (wide) const _RegistryHeader(),
                              for (
                                var index = 0;
                                index < page.items.length;
                                index++
                              ) ...[
                                if (index > 0) const Divider(height: 1),
                                _RegistryRow(
                                  item: page.items[index],
                                  wide: wide,
                                  onTap: widget.selectionMode
                                      ? () => Navigator.pop(
                                          context,
                                          page.items[index],
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (catalog.value case final page?) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  page.totalPages <= 1
                      ? '${page.totalElements} ${page.totalElements == 1 ? 'registro' : 'registros'}'
                      : 'Mostrando ${page.page * page.size + 1}–${page.page * page.size + page.items.length} de ${page.totalElements}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (page.totalPages > 1) ...[
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
            ],
          ),
        ],
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

class _RegistryHeader extends StatelessWidget {
  const _RegistryHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'Registro',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Nomenclatura',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('Origen', style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    ),
  );
}

class _RegistryRow extends StatelessWidget {
  const _RegistryRow({
    required this.item,
    required this.wide,
    required this.onTap,
  });

  final RegistryDefinition item;
  final bool wide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (item.evidenceType) {
      EvidenceType.document => Icons.description_outlined,
      EvidenceType.folder => Icons.folder_outlined,
      EvidenceType.ticket => Icons.confirmation_number_outlined,
      EvidenceType.imputations => Icons.access_time_outlined,
      _ => Icons.dataset_outlined,
    };
    final name = Row(
      children: [
        Icon(icon, size: 20, color: AppColors.info),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.canonicalName, style: theme.textTheme.titleSmall),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
    final type = Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Text(
          item.evidenceType.label,
          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.info),
        ),
      ),
    );
    final nomenclature = Text(
      item.officialNomenclature?.trim().isNotEmpty == true
          ? item.officialNomenclature!
          : 'No corresponde',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
    final origin = Text(
      item.preloaded ? 'Precargado' : 'Creado por administrador',
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 4, child: name),
                  Expanded(flex: 2, child: type),
                  Expanded(flex: 3, child: nomenclature),
                  Expanded(flex: 2, child: origin),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 4, children: [type, origin]),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Nomenclatura  '),
                        TextSpan(text: nomenclature.data),
                      ],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
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
