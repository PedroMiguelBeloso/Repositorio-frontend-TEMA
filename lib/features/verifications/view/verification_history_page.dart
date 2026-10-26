import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../services/model/service_models.dart';
import '../model/verification_history_models.dart';
import '../viewmodel/verification_history_view_model.dart';

class VerificationHistoryPage extends ConsumerWidget {
  const VerificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(verificationHistoryViewModelProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificaciones')),
      body: AsyncContent<VerificationHistoryState>(
        value: history,
        errorMessage: 'No se pudo cargar el historial de verificaciones.',
        onRetry: () => ref
            .read(verificationHistoryViewModelProvider.notifier)
            .retry(),
        builder: (data) => _HistoryContent(
          state: data,
          isAdmin: isAdmin,
          onRefresh: ref
              .read(verificationHistoryViewModelProvider.notifier)
              .refresh,
          onServiceChanged: ref
              .read(verificationHistoryViewModelProvider.notifier)
              .selectService,
          onPageChanged: ref
              .read(verificationHistoryViewModelProvider.notifier)
              .goToPage,
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.state,
    required this.isAdmin,
    required this.onRefresh,
    required this.onServiceChanged,
    required this.onPageChanged,
  });

  final VerificationHistoryState state;
  final bool isAdmin;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 700
            ? AppSpacing.lg
            : AppSpacing.xl;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.xl,
            horizontalPadding,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HistoryHeader(
                      isAdmin: isAdmin,
                      isRefreshing: state.isRefreshing,
                      onRefresh: onRefresh,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ServiceFilter(
                      services: state.services,
                      selectedServiceId: state.serviceId,
                      isDisabled: state.isRefreshing,
                      onChanged: onServiceChanged,
                    ),
                    if (state.refreshFailure != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _RefreshFailureBanner(
                        message: state.refreshFailure!.message,
                        onRetry: onRefresh,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (state.items.isEmpty)
                      const _EmptyHistoryState()
                    else ...[
                      Text(
                        '${state.page.totalElements} ejecuciones',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final run in state.items) ...[
                        _VerificationRunCard(state: state, run: run),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (state.page.totalPages > 1) ...[
                        const SizedBox(height: AppSpacing.md),
                        _Pagination(
                          page: state.page,
                          onPageChanged: onPageChanged,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.isAdmin,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isAdmin;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            if (isAdmin)
              FilledButton.icon(
                onPressed: () => context.go(RouteNames.newVerificationPath),
                icon: const Icon(Icons.add),
                label: const Text('Nueva verificación'),
              ),
          ],
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Historial de ejecuciones', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Consultá ejecuciones anteriores, su estado y el progreso técnico '
                'de cada ejecución.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial de ejecuciones', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Consultá ejecuciones anteriores, su estado y el progreso técnico '
                    'de cada ejecución.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            actions,
          ],
        );
      },
    );
  }
}

class _ServiceFilter extends StatelessWidget {
  const _ServiceFilter({
    required this.services,
    required this.selectedServiceId,
    required this.isDisabled,
    required this.onChanged,
  });

  static const _allServicesValue = '';

  final List<Service> services;
  final String? selectedServiceId;
  final bool isDisabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DropdownButtonFormField<String>(
          initialValue: selectedServiceId ?? _allServicesValue,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Filtrar por servicio',
            helperText: 'El filtro vuelve a la primera página.',
          ),
          items: [
            const DropdownMenuItem(
              value: _allServicesValue,
              child: Text('Todos los servicios'),
            ),
            for (final service in services)
              DropdownMenuItem(
                value: service.id,
                child: Text(service.name),
              ),
          ],
          onChanged: isDisabled
              ? null
              : (value) => onChanged(
                    value == null || value == _allServicesValue ? null : value,
                  ),
        ),
      ),
    );
  }
}

class _VerificationRunCard extends StatelessWidget {
  const _VerificationRunCard({required this.state, required this.run});

  final VerificationHistoryState state;
  final VerificationRunSummary run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final process = state.processFor(run);
    final service = state.serviceFor(run);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('verification-run-${run.id}'),
        onTap: () => context.push(RouteNames.verificationDetails(run.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(run.startedAt.toLocal()),
                    style: theme.textTheme.titleMedium,
                  ),
                  StatusChip(label: run.status.label, tone: _statusTone(run.status)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  if (compact) {
                    return _RunDetailsColumn(
                      service: service,
                      process: process,
                      run: run,
                    );
                  }
                  return _RunDetailsRow(
                    service: service,
                    process: process,
                    run: run,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProgressSection(run: run),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'ID de ejecución',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    run.id,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunDetailsRow extends StatelessWidget {
  const _RunDetailsRow({required this.service, required this.process, required this.run});

  final Service? service;
  final ServiceProcess? process;
  final VerificationRunSummary run;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DetailField(
            label: 'Servicio',
            value: run.serviceNameSnapshot ?? service?.name ?? 'ID de servicio: ${run.serviceId}',
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: _DetailField(
            label: 'Proceso / versión',
            value: run.processNameSnapshot != null
                ? '${run.processNameSnapshot} · versión ${run.processOfficialVersionSnapshot ?? "—"}'
                : process == null
                    ? 'ID de versión: ${run.processVersionId}'
                    : '${process!.processName} · versión ${process!.officialVersion}',
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: _DetailField(
            label: 'Alcance',
            value: run.macroActivityNameSnapshot == null
                ? run.scope.label : 'Macroactividad: ${run.macroActivityNameSnapshot}',
          ),
        ),
      ],
    );
  }
}

class _RunDetailsColumn extends StatelessWidget {
  const _RunDetailsColumn({required this.service, required this.process, required this.run});

  final Service? service;
  final ServiceProcess? process;
  final VerificationRunSummary run;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailField(
          label: 'Servicio',
          value: run.serviceNameSnapshot ?? service?.name ?? 'ID de servicio: ${run.serviceId}',
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailField(
          label: 'Proceso / versión',
          value: run.processNameSnapshot != null
              ? '${run.processNameSnapshot} · versión ${run.processOfficialVersionSnapshot ?? "—"}'
              : process == null
                  ? 'ID de versión: ${run.processVersionId}'
                  : '${process!.processName} · versión ${process!.officialVersion}',
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailField(label: 'Alcance', value: run.macroActivityNameSnapshot == null
            ? run.scope.label : 'Macroactividad: ${run.macroActivityNameSnapshot}'),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.run});

  final VerificationRunSummary run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Progreso técnico',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              run.progress.fractionLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Progreso técnico ${run.progress.fractionLabel}',
          value: '${(run.progress.fraction * 100).round()} por ciento',
          child: LinearProgressIndicator(value: run.progress.fraction, minHeight: 8),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.onPageChanged,
  });

  final PageInfo page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Página ${page.page + 1} de ${page.totalPages}'),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          key: const ValueKey('verification-history-previous-page'),
          tooltip: 'Página anterior',
          onPressed: page.page > 0
              ? () => onPageChanged(page.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const ValueKey('verification-history-next-page'),
          tooltip: 'Página siguiente',
          onPressed: page.page + 1 < page.totalPages
              ? () => onPageChanged(page.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const EmptyState(
          icon: Icons.fact_check_outlined,
          message: 'No hay ejecuciones de verificación para mostrar.',
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _RefreshFailureBanner extends StatelessWidget {
  const _RefreshFailureBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: errorColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

StatusTone _statusTone(VerificationRunStatus status) => switch (status) {
      VerificationRunStatus.queued => StatusTone.warning,
      VerificationRunStatus.running => StatusTone.info,
      // COMPLETED is technical completion, not compliance success.
      VerificationRunStatus.completed => StatusTone.info,
      VerificationRunStatus.failed => StatusTone.danger,
      VerificationRunStatus.unknown => StatusTone.neutral,
    };
