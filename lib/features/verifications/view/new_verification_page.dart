import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/errors/app_failure.dart';
import '../model/new_verification_models.dart';
import '../viewmodel/new_verification_view_model.dart';
import 'verification_copy_button.dart';

class NewVerificationPage extends ConsumerStatefulWidget {
  const NewVerificationPage({super.key});

  @override
  ConsumerState<NewVerificationPage> createState() =>
      _NewVerificationPageState();
}

class _NewVerificationPageState extends ConsumerState<NewVerificationPage> {
  final _ticketQuery = TextEditingController();

  @override
  void dispose() {
    _ticketQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(newVerificationViewModelProvider);
    final viewModel = ref.read(newVerificationViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva verificación')),
      body: SelectionArea(
        child: value.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Cargando servicios',
            ),
          ),
          error: (error, _) => AppErrorView(
            failure: safeAppFailure(
              error,
              fallbackMessage: 'No se pudieron cargar los servicios.',
            ),
            onRetry: viewModel.reload,
          ),
          data: (data) => _content(context, data, viewModel),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    NewVerificationState state,
    NewVerificationViewModel vm,
  ) {
    final theme = Theme.of(context);
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Definí qué se revisará',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Elegí el servicio y el alcance. Después revisá qué evidencias se comprobarán y, si corresponde, seleccioná los tickets. La verificación comienza solo al pulsar «Iniciar verificación».',
                ),
                const SizedBox(height: AppSpacing.xl),
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Alcance', style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<String>(
                          key: ValueKey('service-${state.serviceId}'),
                          initialValue: state.serviceId,
                          decoration: const InputDecoration(
                            labelText: 'Servicio',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final service in state.services)
                              DropdownMenuItem(
                                value: service.id,
                                child: Text(
                                  '${service.name} · ${service.client}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: state.isStarting ? null : vm.selectService,
                        ),
                        if (state.services.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Todavía no hay servicios. Creá uno y asignale una versión publicada antes de verificar.',
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.isLoadingProcesses)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Cargando procesos verificables',
                          ),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'process-${state.serviceId}-${state.processVersionId}',
                          ),
                          initialValue: state.processVersionId,
                          decoration: const InputDecoration(
                            labelText: 'Proceso y versión',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final process in state.processes)
                              DropdownMenuItem(
                                value: process.id,
                                child: Text(
                                  '${process.name} · versión ${process.officialVersion}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged:
                              state.serviceId == null ||
                                  state.isLoadingProcesses ||
                                  state.isStarting
                              ? null
                              : vm.selectProcess,
                        ),
                        if (state.serviceId != null &&
                            !state.isLoadingProcesses &&
                            state.processes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Este servicio no tiene una versión publicada y habilitada para M2.',
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        SegmentedButton<VerificationScope>(
                          segments: [
                            for (final scope in VerificationScope.values.where(
                              (scope) => scope != VerificationScope.unknown,
                            ))
                              ButtonSegment(
                                value: scope,
                                label: Text(scope.label),
                              ),
                          ],
                          selected: {state.scope},
                          onSelectionChanged:
                              state.processVersionId == null || state.isStarting
                              ? null
                              : (selected) => vm.selectScope(selected.first),
                        ),
                        if (state.scope == VerificationScope.macroActivity) ...[
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              'macro-${state.processVersionId}-${state.macroActivityId}',
                            ),
                            initialValue: state.macroActivityId,
                            decoration: const InputDecoration(
                              labelText: 'Macroactividad',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final macro
                                  in state.process?.macroActivities ??
                                      <VerifiableMacroActivity>[])
                                DropdownMenuItem(
                                  value: macro.id,
                                  child: Text(macro.name),
                                ),
                            ],
                            onChanged: state.process == null || state.isStarting
                                ? null
                                : vm.selectMacroActivity,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          enabled: !state.isStarting,
                          decoration: InputDecoration(
                            labelText: 'Contexto del caso (opcional)',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Describí hechos del caso que ayuden a decidir si una evidencia «depende del caso». No es una decisión de aplicabilidad. ${state.note.length}/1000 caracteres.',
                            errorText: state.note.length > 1000
                                ? 'La nota no puede superar 1000 caracteres.'
                                : null,
                          ),
                          maxLines: 2,
                          maxLength: 1000,
                          onChanged: vm.setNote,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: state.canPreview ? vm.loadPreview : null,
                          icon: state.isLoadingPreview
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.preview_outlined),
                          label: Text(
                            state.isLoadingPreview
                                ? 'Cargando evidencias y tickets…'
                                : 'Revisar evidencias y elegir tickets',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.actionFailure case final failure?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ErrorNotice(failure: failure, onRetry: vm.reload),
                ],
                if (state.preview case final preview?) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _preview(context, state, preview, vm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(
    BuildContext context,
    NewVerificationState state,
    VerificationPreview preview,
    NewVerificationViewModel vm,
  ) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpansionTile(
              key: ValueKey('preview-expectations-${preview.processVersionId}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
              title: Text(
                '2. Registros que se comprobarán',
                style: theme.textTheme.titleLarge,
              ),
              subtitle: Text(
                '${preview.expectations.length} registros esperados · revisión del servicio ${preview.serviceRevision}',
              ),
              children: [
                if (preview.expectations.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Este alcance no tiene registros esperados configurados.',
                    ),
                  ),
                for (final location in const [
                  'INPUT',
                  'ACTIVITY_RECORD',
                  'OUTPUT',
                ]) ...[
                  if (preview.expectations.any(
                    (e) => e.location == location,
                  )) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(switch (location) {
                        'INPUT' => 'Entradas',
                        'OUTPUT' => 'Salidas',
                        _ => 'Registros de actividades',
                      }, style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in preview.expectations.where(
                      (e) => e.location == location,
                    ))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(item.displayName),
                        subtitle: Text(
                          '${_evidenceLabel(item.evidenceType)} · ${item.applicability == 'CASE_DEPENDENT' ? 'Depende del caso' : 'Siempre'} · ${item.cardinality == 'ONE' ? 'Una' : 'Una o varias'}',
                        ),
                      ),
                    const Divider(),
                  ],
                ],
              ],
            ),
            if (preview.ticketSelectionGroups.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('3. Tickets de entrada', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Elegí los tickets del proyecto Redmine asociado al servicio. Cada grupo usa únicamente los IDs elegidos.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                enabled: !state.isStarting,
                controller: _ticketQuery,
                onSubmitted: vm.searchTickets,
                decoration: InputDecoration(
                  labelText: 'Buscar ticket por ID o asunto',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.search),
                    onPressed: () => vm.searchTickets(_ticketQuery.text),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isLoadingTickets)
                const LinearProgressIndicator(
                  semanticsLabel: 'Buscando tickets',
                ),
              if (!state.isLoadingTickets && state.tickets == null)
                TextButton(
                  onPressed: () => vm.searchTickets(_ticketQuery.text),
                  child: const Text('Reintentar búsqueda'),
                ),
              if (state.tickets case final ticketPage?) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      '${ticketPage.page.totalElements} tickets encontrados',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Página anterior',
                          onPressed:
                              ticketPage.page.hasPrevious &&
                                  !state.isLoadingTickets
                              ? () => vm.searchTickets(
                                  state.ticketQuery,
                                  page: ticketPage.page.page - 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '${ticketPage.page.page + 1} / ${ticketPage.page.totalPages}',
                        ),
                        IconButton(
                          tooltip: 'Página siguiente',
                          onPressed:
                              ticketPage.page.hasNext && !state.isLoadingTickets
                              ? () => vm.searchTickets(
                                  state.ticketQuery,
                                  page: ticketPage.page.page + 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
                if (ticketPage.items.isEmpty)
                  const Text('No se encontraron tickets para esta búsqueda.'),
              ],
              for (final group in preview.ticketSelectionGroups) ...[
                const SizedBox(height: AppSpacing.md),
                _TicketSelectionCard(
                  group: group,
                  state: state,
                  onToggle: (id) => vm.toggleTicket(group, id),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: state.canStart
                  ? () async {
                      final id = await vm.start();
                      if (id != null && context.mounted) {
                        context.go(RouteNames.verificationDetails(id));
                      }
                    }
                  : null,
              icon: state.isStarting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                state.isStarting
                    ? 'Iniciando verificación…'
                    : 'Iniciar verificación',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _evidenceLabel(String value) => switch (value) {
    'DOCUMENT' => 'Documento',
    'FOLDER' => 'Carpeta',
    'TICKET' => 'Ticket',
    'IMPUTATIONS' => 'Imputaciones',
    'TOOL_RECORD' => 'Registro de herramienta',
    _ => value,
  };
}

class _TicketSelectionCard extends StatelessWidget {
  const _TicketSelectionCard({
    required this.group,
    required this.state,
    required this.onToggle,
  });

  final TicketSelectionGroup group;
  final NewVerificationState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds = state.selectedTickets[group.id] ?? const <String>{};
    return Card.outlined(
      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(group.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              group.isSingle
                  ? 'Seleccioná exactamente un ticket.'
                  : 'Seleccioná uno o más tickets.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.tickets case final ticketPage?)
              for (final ticket in ticketPage.items) ...[
                Material(
                  color: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    side: BorderSide(
                      color: selectedIds.contains(ticket.id)
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: CheckboxListTile(
                    key: ValueKey('ticket-${group.id}-${ticket.id}'),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    title: Text('#${ticket.id} · ${ticket.subject}'),
                    subtitle: Text('Estado: ${ticket.status}'),
                    value: selectedIds.contains(ticket.id),
                    onChanged: state.isStarting
                        ? null
                        : (_) => onToggle(ticket.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            const Divider(height: AppSpacing.xl),
            Text(
              'Tickets elegidos en este grupo · ${selectedIds.length}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (selectedIds.isEmpty)
              Text(
                'Ninguno. La selección se conserva al buscar o cambiar de página.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final id in selectedIds)
                      InputChip(
                        label: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth - 64,
                          ),
                          child: Text(
                            state.knownTickets[id] == null
                                ? 'Ticket #$id'
                                : '#$id · ${state.knownTickets[id]!.subject}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        tooltip: 'Quitar ticket #$id de «${group.label}»',
                        onDeleted: state.isStarting ? null : () => onToggle(id),
                      ),
                  ],
                ),
              ),
              VerificationCopyButton(
                text: [
                  'Tickets elegidos para ${group.label}:',
                  for (final id in selectedIds)
                    '#$id · ${state.knownTickets[id]?.subject ?? 'Asunto no disponible'}',
                ].join('\n'),
                label: 'Copiar tickets elegidos',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.failure, required this.onRetry});
  final AppFailure failure;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(failure.message)),
          TextButton(onPressed: onRetry, child: const Text('Volver a cargar')),
        ],
      ),
    ),
  );
}
