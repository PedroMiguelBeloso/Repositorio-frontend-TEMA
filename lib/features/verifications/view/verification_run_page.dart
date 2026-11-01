import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/new_verification_models.dart';
import '../model/verification_history_models.dart';
import '../model/verification_work_item.dart';
import 'verification_copy_button.dart';
import '../viewmodel/verification_run_view_model.dart';

class VerificationRunPage extends ConsumerWidget {
  const VerificationRunPage({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(verificationRunViewModelProvider(runId));
    final viewModel = ref.read(
      verificationRunViewModelProvider(runId).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de verificación')),
      body: SelectionArea(
        child: value.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Cargando ejecución',
            ),
          ),
          error: (error, _) => AppErrorView(
            failure: safeAppFailure(
              error,
              fallbackMessage: 'No se pudo cargar la ejecución.',
            ),
            onRetry: viewModel.retry,
          ),
          data: (state) => _RunContent(
            state: state,
            isAdmin: ref.watch(sessionProvider)?.isAdmin == true,
            onRetry: viewModel.retry,
          ),
        ),
      ),
    );
  }
}

class _RunContent extends StatefulWidget {
  const _RunContent({
    required this.state,
    required this.isAdmin,
    required this.onRetry,
  });

  final VerificationRunDetailState state;
  final bool isAdmin;
  final VoidCallback onRetry;

  @override
  State<_RunContent> createState() => _RunContentState();
}

class _RunContentState extends State<_RunContent> {
  final ScrollController _scrollController = ScrollController();
  bool _showEvidence = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final onRetry = widget.onRetry;
    final isAdmin = widget.isAdmin;
    final run = state.run;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(8),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Ejecución', style: theme.textTheme.headlineSmall),
                      StatusChip(
                        label: run.status.label,
                        tone: _statusTone(run.status),
                      ),
                      if (state.isRefreshing) const _UpdatingIndicator(),
                    ],
                  ),
                  if (run.status == VerificationRunStatus.completed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Finalizada significa que terminó el procesamiento. El cumplimiento se determina por separado en cada resultado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const Key('open-verification-results'),
                        onPressed: () => context.push(
                          RouteNames.verificationResults(run.id),
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Ver resultados'),
                      ),
                    ),
                  ],
                  if (run.status == VerificationRunStatus.queued ||
                      run.status == VerificationRunStatus.running) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      run.status == VerificationRunStatus.queued
                          ? 'Todavía no se buscó ninguna evidencia. La ejecución está en espera.'
                          : 'Las evidencias pendientes aún no tienen una búsqueda terminada; alguna puede estar en consulta. Solo una búsqueda completa sin coincidencias se mostrará como «Se buscó y no se encontró».',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (state.refreshFailure != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RefreshFailureBanner(
                      message: state.refreshFailure!.message,
                      onRetry: onRetry,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _RunCard(
                    title: 'Progreso',
                    child: _ProgressDetails(progress: run.progress),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RunCard(
                    title: 'Datos de la ejecución',
                    child: _RunData(run: run),
                  ),
                  if (state.workItemsUnavailable) ...[
                    const SizedBox(height: AppSpacing.md),
                    Card.outlined(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'No se pudo consultar el estado de cada evidencia.',
                            ),
                            TextButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar detalle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (state.workItems.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RunCard(
                      title: 'Estado de cada evidencia',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${state.workItems.length} evidencias en esta ejecución.',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Estos estados describen la consulta de la fuente; el cumplimiento se explica en Resultados.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              key: const Key('toggle-evidence-list'),
                              onPressed: () => setState(
                                () => _showEvidence = !_showEvidence,
                              ),
                              icon: Icon(
                                _showEvidence
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              label: Text(
                                _showEvidence
                                    ? 'Ocultar evidencias'
                                    : 'Ver todas las evidencias',
                              ),
                            ),
                          ),
                          if (_showEvidence) ...[
                            const SizedBox(height: AppSpacing.md),
                            const Divider(height: 1),
                            for (final item in state.workItems)
                              _EvidenceProgressRow(item: item),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (run.status == VerificationRunStatus.failed &&
                      run.failureMessage?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RunCard(
                      title: 'Detalle del fallo',
                      child: Text(run.failureMessage!.trim()),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (run.status == VerificationRunStatus.failed) ...[
                    OutlinedButton(
                      onPressed: () => context.go(RouteNames.verificationsPath),
                      child: const Text('Volver a Verificaciones'),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: () =>
                            context.go(RouteNames.newVerificationPath),
                        child: const Text('Iniciar nueva verificación'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDetails extends StatelessWidget {
  const _ProgressDetails({required this.progress});

  final RunProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKnownTotal = progress.total > 0;
    final fraction = hasKnownTotal
        ? progress.fraction.clamp(0.0, 1.0).toDouble()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${progress.fractionLabel} registros procesados',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: hasKnownTotal
              ? 'Progreso: ${progress.fractionLabel} registros procesados'
              : 'Progreso indeterminado',
          value: hasKnownTotal
              ? '${(fraction! * 100).round()} por ciento'
              : null,
          child: LinearProgressIndicator(value: fraction, minHeight: 8),
        ),
        if (hasKnownTotal) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(fraction! * 100).round()} %',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Progreso indeterminado',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (hasKnownTotal && progress.total > progress.processed) ...[
          Text(
            'Pendientes de resultado: ${progress.total - progress.processed}. No se consideran ausentes mientras continúa la ejecución.',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text('Requieren revisión: ${progress.reviewRequired}'),
      ],
    );
  }
}

class _RunData extends StatelessWidget {
  const _RunData({required this.run});

  final VerificationRun run;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - AppSpacing.lg) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          SizedBox(
            width: width,
            child: _RunField(
              label: 'Servicio',
              value: run.serviceNameSnapshot ?? run.serviceId,
            ),
          ),
          SizedBox(
            width: width,
            child: _RunField(
              label: 'Versión del proceso',
              value: run.processNameSnapshot == null
                  ? run.processVersionId
                  : '${run.processNameSnapshot} · versión ${run.processOfficialVersionSnapshot ?? "—"}',
            ),
          ),
          SizedBox(
            width: width,
            child: _RunField(
              label: 'Alcance',
              value: _scopeLabel(
                run.scope,
                run.macroActivityNameSnapshot ?? run.macroActivityId,
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: _RunField(
              label: 'Iniciada',
              value: _formatDate(run.startedAt),
            ),
          ),
          if (run.finishedAt != null)
            SizedBox(
              width: width,
              child: _RunField(
                label: 'Finalizada',
                value: _formatDate(run.finishedAt!),
              ),
            ),
          if (run.note?.trim().isNotEmpty == true)
            SizedBox(
              width: constraints.maxWidth,
              child: _RunField(
                label: 'Contexto del caso aportado',
                value: run.note!.trim(),
              ),
            ),
          SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RunField(label: 'Identificador', value: run.id),
                VerificationCopyButton(
                  text: run.id,
                  label: 'Copiar identificador de ejecución',
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _EvidenceProgressRow extends StatelessWidget {
  const _EvidenceProgressRow({required this.item});

  final VerificationWorkItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, tone) = switch (item.searchStatus) {
      'IN_PROGRESS' => ('Consultando fuente', StatusTone.info),
      'FOUND' => ('Se encontró', StatusTone.success),
      'NOT_FOUND' => ('Se buscó y no se encontró', StatusTone.danger),
      'INCOMPLETE' => ('Consulta incompleta', StatusTone.warning),
      'UNKNOWN' => ('Resultado no concluyente', StatusTone.warning),
      'NOT_ATTEMPTED' when item.resultStatus == 'NOT_APPLICABLE' => (
        'No se consultó: no aplica',
        StatusTone.neutral,
      ),
      'NOT_ATTEMPTED' when item.resultStatus != null => (
        'No se consultó la fuente',
        StatusTone.warning,
      ),
      _ => ('Todavía no se buscó', StatusTone.neutral),
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final description = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName, style: theme.textTheme.titleSmall),
                if (item.subjectTicketId != null)
                  Text(
                    'Ticket #${item.subjectTicketId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.subjectTicketId == null
                      ? Icons.description_outlined
                      : Icons.confirmation_number_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: constraints.maxWidth < 520
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            description,
                            const SizedBox(height: AppSpacing.sm),
                            StatusChip(label: label, tone: tone),
                          ],
                        )
                      : description,
                ),
                if (constraints.maxWidth >= 520) ...[
                  const SizedBox(width: AppSpacing.md),
                  StatusChip(label: label, tone: tone),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _RunField extends StatelessWidget {
  const _RunField({required this.label, required this.value});

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
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _UpdatingIndicator extends StatelessWidget {
  const _UpdatingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.xs),
        Text('Actualizando…'),
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
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'No se pudo actualizar. $message',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            TextButton.icon(
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

StatusTone _statusTone(VerificationRunStatus status) => switch (status) {
  VerificationRunStatus.queued => StatusTone.info,
  VerificationRunStatus.running => StatusTone.info,
  VerificationRunStatus.completed => StatusTone.info,
  VerificationRunStatus.failed => StatusTone.danger,
  VerificationRunStatus.unknown => StatusTone.neutral,
};

String _scopeLabel(VerificationScope scope, String? macroActivityId) {
  return switch (scope) {
    VerificationScope.process => 'Proceso completo',
    VerificationScope.macroActivity =>
      'Macroactividad${macroActivityId == null ? '' : ': $macroActivityId'}',
    VerificationScope.unknown => 'Alcance no reconocido',
  };
}

String _formatDate(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
