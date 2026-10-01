import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';

import '../../../core/errors/app_failure.dart';

import '../model/service_models.dart';

import '../viewmodel/service_form_view_model.dart';

import '../widgets/drive_folder_selector.dart';

import '../widgets/process_version_selector.dart';

import '../widgets/redmine_project_selector.dart';

import '../model/service_draft.dart';

class ServiceFormPage extends ConsumerStatefulWidget {
  const ServiceFormPage({super.key, this.serviceId});

  final String? serviceId;

  @override
  ConsumerState<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends ConsumerState<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clientController;
  int? _loadedRevision;
  bool _controllersInitialized = false;
  bool _allowNextPop = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _clientController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = serviceFormViewModelProvider(widget.serviceId);
    final state = ref.watch(provider);

    ref.listen<AsyncValue<ServiceFormState>>(provider, (previous, next) {
      final savedService = next.value?.savedService;
      if (savedService != null && mounted) {
        context.go(RouteNames.serviceDetails(savedService.id));
      }
    });

    return PopScope(
      canPop: _allowNextPop ||
          !ref
              .read(
                serviceFormViewModelProvider(widget.serviceId).notifier,
              )
              .hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowNextPop) return;

        final shouldLeave = await _confirmLeaveIfNeeded();

        if (!mounted || !shouldLeave) return;

        setState(() {
          _allowNextPop = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.serviceId == null ? 'Nuevo servicio' : 'Editar servicio',
          ),
        ),
        body: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _LoadError(
            failure: _asFailure(error),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (data) => _buildForm(context, data),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ServiceFormState data) {
    _syncControllers(data.draft);
    final vm = ref.read(serviceFormViewModelProvider(widget.serviceId).notifier);
    final validation = data.actionFailure;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (validation case final failure?) ...[
            _ActionError(
              failure: failure,
              onRetry: failure is ConflictFailure
                  ? () => vm.reload()
                  : vm.clearActionFailure,
            ),
            const SizedBox(height: 16),
          ],
          _SectionCard(
            title: 'Datos generales',
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del servicio',
                  errorText: _fieldError(validation, 'name'),
                ),
                textInputAction: TextInputAction.next,
                onChanged: vm.updateName,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Ingresá el nombre del servicio.'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientController,
                decoration: InputDecoration(
                  labelText: 'Cliente',
                  errorText: _fieldError(validation, 'client'),
                ),
                textInputAction: TextInputAction.next,
                onChanged: vm.updateClient,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Ingresá el cliente.'
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServiceType>(
                initialValue: data.draft.serviceType == ServiceType.unknown
                    ? null
                    : data.draft.serviceType,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  errorText: _fieldError(validation, 'serviceType'),
                ),
                items: [
                  for (final type in ServiceType.values)
                    if (type != ServiceType.unknown)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                ],
                onChanged: (value) {
                  if (value != null) vm.updateServiceType(value);
                },
                validator: (value) =>
                    value == null ? 'Seleccioná un tipo de servicio.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServiceStatus>(
                initialValue: data.draft.status == ServiceStatus.unknown
                    ? null
                    : data.draft.status,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  errorText: _fieldError(validation, 'status'),
                ),
                items: [
                  for (final status in ServiceStatus.values)
                    if (status != ServiceStatus.unknown)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                ],
                onChanged: (value) {
                  if (value != null) vm.updateStatus(value);
                },
                validator: (value) =>
                    value == null ? 'Seleccioná un estado.' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Procesos aplicables',
            children: [
              const Text(
                'Seleccioná, como máximo, una versión publicada por cada proceso.',
              ),
              const SizedBox(height: 12),
              if (_fieldError(validation, 'processVersionIds') case final error?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ProcessVersionSelector(
                groups: data.processGroups,
                selectedVersions: data.draft.selectedProcessVersions,
                onVersionSelected: vm.assignProcessVersion,
                onProcessRemoved: vm.clearProcess,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Fuentes de evidencia',
            children: [
              DriveFolderSelector(
                selectedId: data.draft.driveFolderId,
                selectedName: data.draft.driveFolderName,
                initialFailure: data.driveFailure,
                loadPage: ({required query, required page}) =>
                    vm.searchDriveFolders(query: query, page: page),
                onSelected: vm.selectDriveFolder,
                onClear: vm.clearDriveFolder,
              ),
              if (_fieldError(validation, 'driveFolderId') case final error?) ...[
                const SizedBox(height: 6),
                _FieldErrorText(text: error),
              ],
              const SizedBox(height: 16),
              RedmineProjectSelector(
                selectedId: data.draft.redmineProjectId,
                selectedName: data.draft.redmineProjectName,
                initialFailure: data.redmineFailure,
                loadPage: ({required page}) => vm.getRedmineProjects(page: page),
                onSelected: vm.selectRedmineProject,
                onClear: vm.clearRedmineProject,
              ),
              if (_fieldError(validation, 'redmineProjectId')
                  case final error?) ...[
                const SizedBox(height: 6),
                _FieldErrorText(text: error),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _InfoBanner(
            text:
                'Los cambios se usarán en las próximas verificaciones. Las verificaciones anteriores conservan su información.',
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: data.isSaving ? null : _submit,
              icon: data.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(data.isSaving ? 'Guardando...' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  void _syncControllers(ServiceDraft draft) {
    if (_controllersInitialized && _loadedRevision == draft.revision) return;

    _nameController.text = draft.name;
    _clientController.text = draft.client;
    _loadedRevision = draft.revision;
    _controllersInitialized = true;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(serviceFormViewModelProvider(widget.serviceId).notifier)
        .save();
  }

  Future<bool> _confirmLeaveIfNeeded() async {
    final vm = ref.read(serviceFormViewModelProvider(widget.serviceId).notifier);
    if (!vm.hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambios sin guardar'),
            content: const Text(
              'Tenés cambios sin guardar. ¿Querés salir sin guardarlos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Seguir editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir sin guardar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String? _fieldError(AppFailure? failure, String field) {
    if (failure is! ValidationFailure) return null;
    return failure.fieldErrors[field];
  }

  AppFailure _asFailure(Object error) {
    if (error is AppFailure) return error;

    return const UnexpectedFailure(
      'No se pudo cargar el formulario del servicio.',
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionError extends StatelessWidget {
  const _ActionError({
    required this.failure,
    required this.onRetry,
  });

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isConflict = failure is ConflictFailure;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isConflict ? Icons.sync_problem_outlined : Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(failure.message),
                  if (isConflict) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'El servicio fue modificado por otra persona. Podés recargar la versión actual o seguir editando sin sobrescribirla todavía.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(isConflict ? 'Recargar' : 'Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}