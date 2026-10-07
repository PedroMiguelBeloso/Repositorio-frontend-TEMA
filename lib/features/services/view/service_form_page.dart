import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../model/service_draft.dart';
import '../model/service_models.dart';
import '../viewmodel/service_form_view_model.dart';
import '../viewmodel/service_detail_view_model.dart';
import '../viewmodel/service_list_view_model.dart';
import '../widgets/drive_folder_selector.dart';
import '../widgets/process_version_selector.dart';
import '../widgets/redmine_project_selector.dart';

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
        ref.invalidate(serviceDetailViewModelProvider(savedService.id));
        ref.invalidate(serviceListViewModelProvider);
        context.go(RouteNames.serviceDetails(savedService.id));
      }
    });

    return PopScope(
      canPop:
          _allowNextPop ||
          !ref
              .read(serviceFormViewModelProvider(widget.serviceId).notifier)
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
        body: AsyncContent<ServiceFormState>(
          value: state,
          errorMessage: 'No se pudo cargar el formulario del servicio.',
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _buildForm(context, data),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ServiceFormState data) {
    _syncControllers(data.draft);
    final vm = ref.read(
      serviceFormViewModelProvider(widget.serviceId).notifier,
    );
    final validation = data.actionFailure;

    return Form(
      key: _formKey,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              if (validation case final failure?) ...[
                _ActionError(
                  failure: failure,
                  onRetry: failure is ConflictFailure
                      ? () => vm.reload()
                      : vm.clearActionFailure,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresá el nombre del servicio.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _clientController,
                    decoration: InputDecoration(
                      labelText: 'Cliente',
                      errorText: _fieldError(validation, 'client'),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: vm.updateClient,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresá el cliente.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    validator: (value) => value == null
                        ? 'Seleccioná un tipo de servicio.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (widget.serviceId == null)
                    const _InfoBanner(
                      text:
                          'El servicio se crea como Activo. Podés cambiarlo a Inactivo al editarlo más adelante.',
                    )
                  else
                    DropdownButtonFormField<ServiceStatus>(
                      key: ValueKey(data.draft.status),
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
                  if (widget.serviceId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                    'Inactivo identifica un servicio que ya no está en operación. El cambio de estado no quita sus procesos ni sus fuentes de evidencia.',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Procesos aplicables',
                children: [
                  const Text(
                    'Seleccioná, como máximo, una versión publicada por cada proceso.',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    data.draft.selectedProcessVersions.isEmpty
                        ? 'Todavía no seleccionaste ningún proceso.'
                        : data.draft.selectedProcessVersions.length == 1
                        ? '1 proceso seleccionado.'
                        : '${data.draft.selectedProcessVersions.length} procesos seleccionados.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_fieldError(validation, 'processVersionIds')
                      case final error?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              const SizedBox(height: AppSpacing.lg),
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
                  if (_fieldError(validation, 'driveFolderId')
                      case final error?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _FieldErrorText(text: error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  RedmineProjectSelector(
                    selectedId: data.draft.redmineProjectId,
                    selectedName: data.draft.redmineProjectName,
                    initialFailure: data.redmineFailure,
                    loadPage: ({required page}) =>
                        vm.getRedmineProjects(page: page),
                    onSelected: vm.selectRedmineProject,
                    onClear: vm.clearRedmineProject,
                  ),
                  if (_fieldError(validation, 'redmineProjectId')
                      case final error?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _FieldErrorText(text: error),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _InfoBanner(
                text:
                    'Los cambios se usarán en las próximas verificaciones. Las verificaciones anteriores conservan su información.',
              ),
              const SizedBox(height: AppSpacing.xl),
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
        ),
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

    final draft = ref
        .read(serviceFormViewModelProvider(widget.serviceId))
        .value
        ?.draft;
    if (draft == null) return;
    if (draft.selectedProcessVersions.isEmpty) {
      final continueWithoutProcesses = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Servicio sin procesos asignados'),
          content: const Text(
            'No seleccionaste ninguna versión publicada. Si guardás ahora, el servicio no tendrá procesos para consultar ni verificar. Podés asignarlos después desde Editar servicio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver al formulario'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Guardar sin procesos'),
            ),
          ],
        ),
      );
      if (!mounted || continueWithoutProcesses != true) return;
    }

    await ref
        .read(serviceFormViewModelProvider(widget.serviceId).notifier)
        .save();
  }

  Future<bool> _confirmLeaveIfNeeded() async {
    final vm = ref.read(
      serviceFormViewModelProvider(widget.serviceId).notifier,
    );
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
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConflict = failure is ConflictFailure;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final message = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(failure.message),
                if (isConflict) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'El servicio fue modificado por otra persona. Podés recargar la versión actual o seguir editando sin sobrescribirla todavía.',
                  ),
                ],
              ],
            );
            final icon = Icon(
              isConflict ? Icons.sync_problem_outlined : Icons.error_outline,
              color: theme.colorScheme.error,
            );
            final action = TextButton(
              onPressed: onRetry,
              child: Text(isConflict ? 'Recargar' : 'Cerrar'),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: message),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: message),
                const SizedBox(width: AppSpacing.sm),
                action,
              ],
            );
          },
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
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
