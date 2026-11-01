import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../processes/model/process_models.dart';
import '../../processes/model/evidence_expectation.dart' as evidence_model;
import '../../services/model/service_models.dart';
import '../data/verification_result_location_resolver.dart';
import '../data/verification_repository_impl.dart';
import '../model/verification_history_models.dart';
import '../model/verification_result_models.dart';
import '../viewmodel/verification_results_view_model.dart';
import 'ai_retry_history_dialog.dart';
import 'verification_copy_button.dart';
import 'verification_text_format.dart';

typedef ResultDecisionAction =
    Future<VerificationResult> Function({
      required String resultId,
      required VerificationResultStatus finalStatus,
      required String rationale,
    });

class VerificationResultsPage extends ConsumerWidget {
  const VerificationResultsPage({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(verificationResultsViewModelProvider(runId));
    final viewModel = ref.read(
      verificationResultsViewModelProvider(runId).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados de verificación')),
      body: value.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Cargando resultados',
          ),
        ),
        error: (error, _) => AppErrorView(
          failure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo cargar la ejecución.',
          ),
          onRetry: viewModel.retry,
        ),
        data: (data) => _ResultsContent(
          state: data,
          isAdmin: ref.watch(sessionProvider)?.isAdmin == true,
          onRetry: viewModel.retry,
          onPageChanged: viewModel.goToPage,
          onToggleResult: viewModel.toggleResult,
          onResolveApplicability: viewModel.resolveApplicability,
          onDecideResult: viewModel.decideResult,
          onRetryAi: viewModel.retryAi,
          onLoadAiRetries: viewModel.loadAiRetries,
        ),
      ),
    );
  }
}

class _ResultsContent extends StatefulWidget {
  const _ResultsContent({
    required this.state,
    required this.isAdmin,
    required this.onRetry,
    required this.onPageChanged,
    required this.onToggleResult,
    required this.onResolveApplicability,
    required this.onDecideResult,
    required this.onRetryAi,
    required this.onLoadAiRetries,
  });

  final VerificationResultsState state;
  final bool isAdmin;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onToggleResult;
  final Future<VerificationResult> Function({
    required String resultId,
    required HumanApplicabilityDecision decision,
    required String rationale,
  })
  onResolveApplicability;
  final ResultDecisionAction onDecideResult;
  final Future<VerificationResult> Function(String) onRetryAi;
  final Future<List<AiRetryAttempt>> Function(String) onLoadAiRetries;

  @override
  State<_ResultsContent> createState() => _ResultsContentState();
}

class _ResultsContentState extends State<_ResultsContent> {
  final ScrollController _scrollController = ScrollController();

  void _changePage(int page) {
    widget.onPageChanged(page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 700
            ? AppSpacing.lg
            : AppSpacing.xl;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          thickness: 8,
          radius: const Radius.circular(8),
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xl,
              horizontalPadding + AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (widget.state.run.status) {
      case VerificationRunStatus.queued:
      case VerificationRunStatus.running:
        return _ExecutionPendingContent(
          run: widget.state.run,
          onBack: () =>
              context.go(RouteNames.verificationDetails(widget.state.run.id)),
        );
      case VerificationRunStatus.failed:
        return _ExecutionFailedContent(
          run: widget.state.run,
          onRetry: widget.onRetry,
          onBack: () =>
              context.go(RouteNames.verificationDetails(widget.state.run.id)),
        );
      case VerificationRunStatus.completed:
        return _CompletedResultsContent(
          state: widget.state,
          isAdmin: widget.isAdmin,
          onRetry: widget.onRetry,
          onPageChanged: _changePage,
          onToggleResult: widget.onToggleResult,
          onResolveApplicability: widget.onResolveApplicability,
          onDecideResult: widget.onDecideResult,
          onRetryAi: widget.onRetryAi,
          onLoadAiRetries: widget.onLoadAiRetries,
        );
      case VerificationRunStatus.unknown:
        return _UnknownExecutionState(onRetry: widget.onRetry);
    }
  }
}

class _CompletedResultsContent extends StatelessWidget {
  const _CompletedResultsContent({
    required this.state,
    required this.isAdmin,
    required this.onRetry,
    required this.onPageChanged,
    required this.onToggleResult,
    required this.onResolveApplicability,
    required this.onDecideResult,
    required this.onRetryAi,
    required this.onLoadAiRetries,
  });

  final VerificationResultsState state;
  final bool isAdmin;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onToggleResult;
  final Future<VerificationResult> Function({
    required String resultId,
    required HumanApplicabilityDecision decision,
    required String rationale,
  })
  onResolveApplicability;
  final ResultDecisionAction onDecideResult;
  final Future<VerificationResult> Function(String) onRetryAi;
  final Future<List<AiRetryAttempt>> Function(String) onLoadAiRetries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = state.page;
    final groups = <String, List<VerificationResult>>{};
    for (final result in state.items) {
      final contextName =
          state.locationContext[result.id]?.macroActivityName ?? '';
      groups
          .putIfAbsent('${result.macroActivityId}|$contextName', () => [])
          .add(result);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunOverview(state: state, onRetry: onRetry),
        const SizedBox(height: AppSpacing.xxl),
        if (state.resultsFailure != null) ...[
          _ResultsFailureBanner(
            message: state.resultsFailure!.message,
            onRetry: onRetry,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (page != null && page.totalElements > 0) ...[
          Text('Evidencias evaluadas', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${page.totalElements} resultados en total · se muestran ${state.items.length} en esta página. '
            'Abrí una evidencia para ver su fundamento, referencias y decisiones.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (page.totalPages > 1) ...[
            _ResultsPagination(
              page: page,
              disabled:
                  state.isChangingPage ||
                  state.isResolvingApplicability ||
                  state.isDecidingResult,
              onPageChanged: onPageChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (final group in groups.entries) ...[
            Card.outlined(
              color: AppColors.surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'MACROACTIVIDAD',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.info,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state
                              .locationContext[group.value.first.id]
                              ?.macroActivityName ??
                          'Macroactividad del proceso',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${group.value.length} evidencias en esta página',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final result in group.value) ...[
                      VerificationResultTile(
                        result: result,
                        locationContext: state.locationContext[result.id],
                        isAdmin: isAdmin,
                        isResolvingApplicability:
                            state.isResolvingApplicability,
                        isDecidingResult: state.isDecidingResult,
                        onResolveApplicability: onResolveApplicability,
                        onDecideResult: onDecideResult,
                        onRetryAi: onRetryAi,
                        onLoadAiRetries: onLoadAiRetries,
                        isRetryingAi: state.isRetryingAi,
                        isExpanded: result.id == state.selectedResultId,
                        onToggle: () => onToggleResult(result.id),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (page.totalPages > 1) ...[
            const SizedBox(height: AppSpacing.md),
            _ResultsPagination(
              page: page,
              disabled:
                  state.isChangingPage ||
                  state.isResolvingApplicability ||
                  state.isDecidingResult,
              onPageChanged: onPageChanged,
            ),
          ],
        ] else if (state.resultsFailure == null) ...[
          const EmptyState(
            icon: Icons.fact_check_outlined,
            message: 'La ejecución finalizó y no hay resultados para mostrar.',
          ),
        ],
      ],
    );
  }
}

class _RunOverview extends StatelessWidget {
  const _RunOverview({required this.state, required this.onRetry});

  final VerificationResultsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = state.run;
    final process = run.processNameSnapshot?.trim();
    final service = run.serviceNameSnapshot?.trim();
    final reviewCount = state.items
        .where(
          (item) =>
              item.effectiveStatus == VerificationResultStatus.reviewRequired,
        )
        .length;
    final compliesCount = state.items
        .where(
          (item) => item.effectiveStatus == VerificationResultStatus.complies,
        )
        .length;
    final notCompliesCount = state.items
        .where(
          (item) =>
              item.effectiveStatus == VerificationResultStatus.doesNotComply,
        )
        .length;

    return Card.outlined(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VERIFICACIÓN FINALIZADA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              process?.isNotEmpty == true ? process! : 'Resultados del proceso',
              style: theme.textTheme.headlineSmall,
            ),
            if (service?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Servicio: $service', style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(label: run.status.label, tone: StatusTone.info),
                if (run.processOfficialVersionSnapshot?.isNotEmpty == true)
                  Text(
                    'Versión ${run.processOfficialVersionSnapshot}',
                    style: theme.textTheme.bodyMedium,
                  ),
                Text(
                  'Inicio: ${DateFormat('dd/MM/yyyy HH:mm').format(run.startedAt.toLocal())}',
                  style: theme.textTheme.bodyMedium,
                ),
                OutlinedButton.icon(
                  onPressed: state.isChangingPage || state.isRetryingAi
                      ? null
                      : onRetry,
                  icon: const Icon(Icons.sync),
                  label: const Text('Volver a consultar'),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Text('Estado de esta página', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'La ejecución terminó; eso no indica que todas las evidencias cumplan. Revisá los estados de cada resultado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _CountLabel(
                  count: reviewCount,
                  label: 'requieren revisión',
                  color: AppColors.warning,
                ),
                _CountLabel(
                  count: compliesCount,
                  label: 'cumplen',
                  color: AppColors.success,
                ),
                _CountLabel(
                  count: notCompliesCount,
                  label: 'no cumplen',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'El estado visible de cada evidencia es el vigente. Si hubo una decisión humana, '
              'se conserva por separado la propuesta automática.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({
    required this.count,
    required this.label,
    required this.color,
  });
  final int count;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          '$count $label',
          softWrap: true,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

class VerificationResultTile extends StatelessWidget {
  const VerificationResultTile({
    super.key,
    required this.result,
    required this.locationContext,
    this.isAdmin = false,
    this.isResolvingApplicability = false,
    this.isDecidingResult = false,
    this.onResolveApplicability,
    this.onDecideResult,
    this.onRetryAi,
    this.onLoadAiRetries,
    this.isRetryingAi = false,
    required this.isExpanded,
    required this.onToggle,
  });

  final VerificationResult result;
  final VerificationResultLocationContext? locationContext;
  final bool isAdmin;
  final bool isResolvingApplicability;
  final bool isDecidingResult;
  final Future<VerificationResult> Function({
    required String resultId,
    required HumanApplicabilityDecision decision,
    required String rationale,
  })?
  onResolveApplicability;
  final ResultDecisionAction? onDecideResult;
  final Future<VerificationResult> Function(String)? onRetryAi;
  final Future<List<AiRetryAttempt>> Function(String)? onLoadAiRetries;
  final bool isRetryingAi;

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusTone = _resultStatusTone(result.effectiveStatus);

    return Card.outlined(
      color: AppColors.surfaceWhite,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ValueKey('result-status-bar-${result.id}'),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: .38),
              border: Border(
                left: BorderSide(
                  color: _resultStatusColor(result.effectiveStatus),
                  width: 4,
                ),
              ),
            ),
            child: Semantics(
              button: true,
              expanded: isExpanded,
              label:
                  '${result.displayName}. Estado vigente: ${result.effectiveStatus.label}. '
                  '${isExpanded ? 'Ocultar detalle' : 'Ver detalle'}',
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final titleAndStatus = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (locationContext?.hasActivity == true) ...[
                                Text(
                                  'ACTIVIDAD · ${locationContext!.activityName}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                              ],
                              Text(
                                result.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _LocationBadge(location: result.location),
                                  _MetaBadge(
                                    icon: Icons.category_outlined,
                                    label: result.evidenceType.label,
                                  ),
                                  if (result.subjectTicketId != null)
                                    _MetaBadge(
                                      icon: Icons.confirmation_num_outlined,
                                      label: 'Ticket ${result.subjectTicketId}',
                                    ),
                                  if (result
                                      .applicability
                                      .requiresHumanIntervention)
                                    _MetaBadge(
                                      icon: Icons.rule_outlined,
                                      label: 'Aplicabilidad pendiente',
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _MethodBadge(
                                    icon:
                                        result.applicability.origin ==
                                            DecisionOrigin.aiApplicability
                                        ? Icons.auto_awesome_outlined
                                        : result.applicability.origin ==
                                              DecisionOrigin.human
                                        ? Icons.person_outline
                                        : Icons.rule_outlined,
                                    label: applicabilityMethodLabel(result),
                                    isAi:
                                        result.applicability.origin ==
                                        DecisionOrigin.aiApplicability,
                                  ),
                                  _MethodBadge(
                                    icon:
                                        TicketAiRationale.parse(
                                              result.rationale,
                                            ) ==
                                            null
                                        ? Icons.rule_outlined
                                        : Icons.auto_awesome_outlined,
                                    label: resultMethodLabel(result),
                                    isAi:
                                        TicketAiRationale.parse(
                                          result.rationale,
                                        ) !=
                                        null,
                                  ),
                                ],
                              ),
                            ],
                          );

                          final status = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESTADO VIGENTE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StatusChip(
                                label: result.effectiveStatus.label,
                                tone: statusTone,
                              ),
                            ],
                          );

                          if (constraints.maxWidth < 560) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleAndStatus,
                                const SizedBox(height: AppSpacing.md),
                                status,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: titleAndStatus),
                              const SizedBox(width: AppSpacing.lg),
                              status,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              isExpanded
                                  ? 'Ocultar detalle'
                                  : 'Ver análisis y referencias',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: _ResultDetails(
                      result: result,
                      locationContext: locationContext,
                      isAdmin: isAdmin,
                      isResolvingApplicability: isResolvingApplicability,
                      isDecidingResult: isDecidingResult,
                      onResolveApplicability: onResolveApplicability,
                      onDecideResult: onDecideResult,
                      onRetryAi: onRetryAi,
                      onLoadAiRetries: onLoadAiRetries,
                      isRetryingAi: isRetryingAi,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({
    required this.result,
    required this.locationContext,
    required this.isAdmin,
    required this.isResolvingApplicability,
    required this.isDecidingResult,
    required this.onResolveApplicability,
    required this.onDecideResult,
    required this.onRetryAi,
    required this.onLoadAiRetries,
    required this.isRetryingAi,
  });

  final VerificationResult result;
  final VerificationResultLocationContext? locationContext;
  final bool isAdmin;
  final bool isResolvingApplicability;
  final bool isDecidingResult;
  final Future<VerificationResult> Function({
    required String resultId,
    required HumanApplicabilityDecision decision,
    required String rationale,
  })?
  onResolveApplicability;
  final ResultDecisionAction? onDecideResult;
  final Future<VerificationResult> Function(String)? onRetryAi;
  final Future<List<AiRetryAttempt>> Function(String)? onLoadAiRetries;
  final bool isRetryingAi;

  String get _searchLabel {
    if (result.searchStatus != EvidenceSearchStatus.notAttempted) {
      return result.searchStatus.label;
    }
    return switch (result.applicability.decision) {
      ApplicabilityDecision.notApplicable => 'No se consultó: no aplica',
      ApplicabilityDecision.undetermined =>
        'No se consultó: aplicabilidad pendiente',
      _ => 'No se consultó la fuente',
    };
  }

  String get _searchExplanation {
    if (result.searchStatus != EvidenceSearchStatus.notAttempted) {
      return result.searchStatus.explanation;
    }
    return switch (result.applicability.decision) {
      ApplicabilityDecision.notApplicable =>
        'La evidencia no aplica a este caso, por eso no se buscó en la fuente.',
      ApplicabilityDecision.undetermined =>
        'Primero debe resolverse la aplicabilidad; todavía no se consultó la fuente.',
      _ => 'La evaluación terminó sin consultar esta fuente.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ticketAiRationale = TicketAiRationale.parse(result.rationale);
    final lacksCaseFacts =
        result.evidenceType != EvidenceType.ticket &&
        result.applicability.limitations.any(
          (text) => text.contains('No se recibieron datos del caso'),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        if (result.hasHumanStatusDecision) ...[
          _HumanOverrideNotice(
            proposedStatus: result.proposedStatus,
            effectiveStatus: result.effectiveStatus,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: VerificationCopyButton(
            text: formatVerificationResultForCopy(result),
            label: 'Copiar resultado completo',
          ),
        ),
        if (result.evidenceType == EvidenceType.toolRecord &&
            result.displayName.toLowerCase().contains(
              'servicio en herramienta de tracking',
            )) ...[
          Text(
            'Aquí se comprueba la existencia del proyecto Redmine vinculado al servicio. Si este registro figura en otro paso del proceso, ese uso conserva un resultado independiente.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _ResultDetailTabs(
          analysis: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card.outlined(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consulta de la fuente',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _searchLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color:
                                  result.searchStatus ==
                                      EvidenceSearchStatus.notFound
                                  ? AppColors.warning
                                  : AppColors.textPrimary,
                            ),
                      ),
                      Text(_searchExplanation),
                    ],
                  ),
                ),
              ),
              if (result.proposedStatus ==
                      VerificationResultStatus.reviewRequired &&
                  (result.effectiveStatus ==
                          VerificationResultStatus.reviewRequired ||
                      result.hasHumanStatusDecision)) ...[
                const SizedBox(height: AppSpacing.md),
                Card.outlined(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.effectiveStatus ==
                                  VerificationResultStatus.reviewRequired
                              ? 'Por qué requiere revisión'
                              : 'Por qué la propuesta automática requiere revisión',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          result.reviewReason.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(result.reviewReason.explanation),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                title: 'Fundamento',
                child: SelectableText(
                  humanizeVerificationText(
                    ticketAiRationale?.explanation ?? result.rationale,
                  ),
                ),
              ),
              if (ticketAiRationale != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Esta interpretación del ticket fue propuesta por Gemini y pasó las reglas programadas de seguridad.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (ticketAiRationale.citedFields.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Campos del ticket considerados: ${ticketAiRationale.citedFields.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (ticketAiRationale.model != null ||
                    ticketAiRationale.responseId != null)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Datos técnicos de la respuesta de IA'),
                    children: [
                      if (ticketAiRationale.model != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            'Modelo: ${ticketAiRationale.model}',
                          ),
                        ),
                      if (ticketAiRationale.responseId != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            'ID de respuesta de Gemini: ${ticketAiRationale.responseId}',
                          ),
                        ),
                    ],
                  ),
              ],
              if (result.limitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _DetailSection(
                  title: 'Limitaciones',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final limitation in result.limitations) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(
                              child: SelectableText(
                                humanizeVerificationText(limitation),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
              if (result.applicability.hasContextualAssessment) ...[
                const SizedBox(height: AppSpacing.lg),
                _ApplicabilitySection(
                  assessment: result.applicability,
                  canResolve:
                      isAdmin &&
                      locationContext?.applicabilityMode ==
                          evidence_model.ApplicabilityMode.caseDependent &&
                      onResolveApplicability != null,
                  isAdmin: isAdmin,
                  isResolving: isResolvingApplicability || isDecidingResult,
                  onResolve: () => _openApplicabilityDialog(context),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Card.outlined(
                color: AppColors.surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evaluación automática del sistema',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusChip(
                        label: result.proposedStatus.label,
                        tone: _resultStatusTone(result.proposedStatus),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        result.applicability.requiresHumanIntervention
                            ? 'Antes de decidir si cumple, un Administrador debe confirmar si esta evidencia aplica al caso.'
                            : result.proposedStatus ==
                                  VerificationResultStatus.reviewRequired
                            ? 'El motivo concreto está indicado en «Por qué requiere revisión». Este estado no significa que la evidencia incumpla.'
                            : 'Es la conclusión propuesta por el sistema. Si hubo una decisión humana, el estado vigente puede ser diferente.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (lacksCaseFacts) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Esta ejecución no contiene hechos del caso para volver a evaluar esta evidencia. '
                          'Resolvé la aplicabilidad manualmente o iniciá una nueva verificación con una nota del caso.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isAdmin &&
                  onRetryAi != null &&
                  (result.evidenceType == EvidenceType.ticket ||
                      result.applicability.requiresHumanIntervention)) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (!lacksCaseFacts)
                      OutlinedButton.icon(
                        onPressed: isRetryingAi
                            ? null
                            : () => _retryGemini(context),
                        icon: isRetryingAi
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Reintentar con Gemini'),
                      ),
                    if (onLoadAiRetries != null)
                      TextButton.icon(
                        onPressed: () => _showAiHistory(context),
                        icon: const Icon(Icons.history),
                        label: const Text('Historial de propuestas IA'),
                      ),
                  ],
                ),
              ],
            ],
          ),
          review: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdmin && onDecideResult != null) ...[
                _HumanStatusReviewSection(
                  result: result,
                  choices: allowedHumanFinalStatuses(
                    result,
                    locationContext?.applicabilityMode,
                  ),
                  busy: isResolvingApplicability || isDecidingResult,
                  onReview: () => _openStatusDecisionDialog(context),
                ),
              ],
              if (result.humanDecisions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _HumanDecisionsSection(events: result.humanDecisions),
              ] else if (!isAdmin) ...[
                const Text(
                  'No hay decisiones humanas registradas para esta evidencia.',
                ),
              ],
            ],
          ),
          sources: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdmin && result.evidenceType == EvidenceType.ticket) ...[
                _OriginalTicketObservation(
                  runId: result.runId,
                  resultId: result.id,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _EvidenceReferencesSection(references: result.evidence),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _retryGemini(BuildContext context) async {
    final retry = onRetryAi;
    if (retry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reintentar interpretación'),
        content: Text(
          result.evidenceType == EvidenceType.ticket
              ? 'Se volverá a leer el ticket actual de Redmine y se consultará Gemini. '
                    'La propuesta anterior quedará en el historial; una decisión humana no se modificará.'
              : 'Se volverá a evaluar la aplicabilidad con los hechos registrados para esta verificación. '
                    'Si no hay nota del caso ni tickets seleccionados, no hay información suficiente y deberás resolverla manualmente. '
                    'La propuesta anterior quedará en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await retry(result.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nueva propuesta guardada en el historial.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              safeAppFailure(
                error,
                fallbackMessage: 'No se pudo reintentar Gemini.',
              ).message,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showAiHistory(BuildContext context) async {
    final load = onLoadAiRetries;
    if (load == null) return;
    try {
      final attempts = await load(result.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AiRetryHistoryDialog(attempts: attempts),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              safeAppFailure(
                error,
                fallbackMessage: 'No se pudo cargar el historial de IA.',
              ).message,
            ),
          ),
        );
      }
    }
  }

  Future<void> _openApplicabilityDialog(BuildContext context) async {
    final resolve = onResolveApplicability;
    if (resolve == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ApplicabilityDecisionDialog(
        result: result,
        onSubmit: ({required decision, required rationale}) => resolve(
          resultId: result.id,
          decision: decision,
          rationale: rationale,
        ),
      ),
    );
  }

  Future<void> _openStatusDecisionDialog(BuildContext context) async {
    final decide = onDecideResult;
    if (decide == null) return;
    final choices = allowedHumanFinalStatuses(
      result,
      locationContext?.applicabilityMode,
    );
    if (choices.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StatusDecisionDialog(
        result: result,
        choices: choices,
        onSubmit: ({required finalStatus, required rationale}) => decide(
          resultId: result.id,
          finalStatus: finalStatus,
          rationale: rationale,
        ),
      ),
    );
  }
}

class _ResultDetailTabs extends StatefulWidget {
  const _ResultDetailTabs({
    required this.analysis,
    required this.review,
    required this.sources,
  });

  final Widget analysis;
  final Widget review;
  final Widget sources;

  @override
  State<_ResultDetailTabs> createState() => _ResultDetailTabsState();
}

class _ResultDetailTabsState extends State<_ResultDetailTabs> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          isScrollable: false,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.border,
          onTap: (index) => setState(() => _selected = index),
          tabs: const [
            Tab(text: 'Evaluación'),
            Tab(text: 'Decisiones'),
            Tab(text: 'Fuentes'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        [widget.analysis, widget.review, widget.sources][_selected],
      ],
    ),
  );
}

class _HumanOverrideNotice extends StatelessWidget {
  const _HumanOverrideNotice({
    required this.proposedStatus,
    required this.effectiveStatus,
  });

  final VerificationResultStatus proposedStatus;
  final VerificationResultStatus effectiveStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hubo una decisión humana posterior',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'La propuesta automática fue «${proposedStatus.label}» y el estado efectivo es «${effectiveStatus.label}».',
          ),
        ],
      ),
    );
  }
}

class _ApplicabilitySection extends StatelessWidget {
  const _ApplicabilitySection({
    required this.assessment,
    required this.canResolve,
    required this.isAdmin,
    required this.isResolving,
    required this.onResolve,
  });

  final ApplicabilityAssessment assessment;
  final bool canResolve;
  final bool isAdmin;
  final bool isResolving;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUndetermined = assessment.requiresHumanIntervention;

    return _DetailSection(
      title: 'Aplicabilidad',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUndetermined
              ? AppColors.warning.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isUndetermined
                ? AppColors.warning.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(
                  label: assessment.decision.label,
                  tone: isUndetermined ? StatusTone.warning : StatusTone.info,
                ),
                Text(
                  'Origen: ${assessment.origin.label}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(humanizeVerificationText(assessment.rationale)),
            if (assessment.limitations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final limitation in assessment.limitations) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: SelectableText(
                        humanizeVerificationText(limitation),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
            if (isUndetermined) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La aplicabilidad quedó indeterminada y requiere intervención de un Administrador.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canResolve) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: isResolving ? null : onResolve,
                  icon: const Icon(Icons.rule_outlined),
                  label: const Text('Resolver aplicabilidad'),
                ),
              ] else if (isAdmin) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No se pudo confirmar «Depende del caso» en la versión del proceso. Actualizá los resultados o consultá la configuración antes de decidir.',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicabilityDecisionDialog extends StatefulWidget {
  const _ApplicabilityDecisionDialog({
    required this.result,
    required this.onSubmit,
  });

  final VerificationResult result;
  final Future<VerificationResult> Function({
    required HumanApplicabilityDecision decision,
    required String rationale,
  })
  onSubmit;

  @override
  State<_ApplicabilityDecisionDialog> createState() =>
      _ApplicabilityDecisionDialogState();
}

class _ApplicabilityDecisionDialogState
    extends State<_ApplicabilityDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rationaleController = TextEditingController();
  HumanApplicabilityDecision? _decision;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_decision == null) {
      setState(() => _error = 'Elegí si esta evidencia aplica.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final updated = await widget.onSubmit(
        decision: _decision!,
        rationale: _rationaleController.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Aplicabilidad guardada. Estado actual: ${updated.effectiveStatus.label}.',
          ),
        ),
      );
    } on ConflictFailure {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'El resultado cambió. Revisá la versión actual antes de decidir nuevamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo guardar la decisión.',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.result.subjectTicketId;
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Resolver aplicabilidad'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.result.displayName),
                  if (ticket != null) Text('Ticket $ticket'),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Decidí si esta evidencia corresponde al caso verificado. La decisión y su fundamento quedarán registrados.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RadioGroup<HumanApplicabilityDecision>(
                    groupValue: _decision,
                    onChanged: _submitting
                        ? (_) {}
                        : (value) => setState(() {
                            _decision = value;
                            _error = null;
                          }),
                    child: Column(
                      children: [
                        for (final option in HumanApplicabilityDecision.values)
                          RadioListTile<HumanApplicabilityDecision>(
                            title: Text(option.label),
                            value: option,
                            enabled: !_submitting,
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _rationaleController,
                    enabled: !_submitting,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Fundamento',
                      hintText:
                          'Explicá por qué aplica o no aplica en este caso',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribí el fundamento de la decisión.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar decisión'),
          ),
        ],
      ),
    );
  }
}

class _HumanStatusReviewSection extends StatelessWidget {
  const _HumanStatusReviewSection({
    required this.result,
    required this.choices,
    required this.busy,
    required this.onReview,
  });

  final VerificationResult result;
  final List<VerificationResultStatus> choices;
  final bool busy;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    String? explanation;
    if (result.applicability.requiresHumanIntervention) {
      explanation =
          'Primero resolvé la aplicabilidad pendiente de esta evidencia.';
    } else if (choices.isEmpty) {
      explanation =
          'No se pudo confirmar que «No aplica» esté permitido en la versión del proceso. Actualizá los resultados antes de decidir.';
    }

    return _DetailSection(
      title: 'Revisión humana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Estado actual:'),
              StatusChip(
                label: result.effectiveStatus.label,
                tone: _resultStatusTone(result.effectiveStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            explanation ??
                'Podés confirmar el estado actual o corregirlo. La decisión quedará en el historial con su fundamento.',
          ),
          if (choices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: busy ? null : onReview,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Confirmar o corregir resultado'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDecisionDialog extends StatefulWidget {
  const _StatusDecisionDialog({
    required this.result,
    required this.choices,
    required this.onSubmit,
  });

  final VerificationResult result;
  final List<VerificationResultStatus> choices;
  final Future<VerificationResult> Function({
    required VerificationResultStatus finalStatus,
    required String rationale,
  })
  onSubmit;

  @override
  State<_StatusDecisionDialog> createState() => _StatusDecisionDialogState();
}

class _StatusDecisionDialogState extends State<_StatusDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rationaleController = TextEditingController();
  VerificationResultStatus? _selectedStatus;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.choices.contains(widget.result.effectiveStatus)) {
      _selectedStatus = widget.result.effectiveStatus;
    }
  }

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedStatus == null) {
      setState(() => _error = 'Elegí el estado final.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final updated = await widget.onSubmit(
        finalStatus: _selectedStatus!,
        rationale: _rationaleController.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Decisión registrada. Estado actual: ${updated.effectiveStatus.label}.',
          ),
        ),
      );
    } on ConflictFailure {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'El resultado cambió. Revisá su estado actual antes de decidir nuevamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo registrar la decisión.',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketId = widget.result.subjectTicketId;
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Confirmar o corregir resultado'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.result.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (ticketId != null) Text('Ticket $ticketId'),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Propuesta automática: ${widget.result.proposedStatus.label}',
                  ),
                  Text('Estado actual: ${widget.result.effectiveStatus.label}'),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Seleccioná el estado final. La propuesta automática se conserva y esta decisión se agrega al historial.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RadioGroup<VerificationResultStatus>(
                    groupValue: _selectedStatus,
                    onChanged: _submitting
                        ? (_) {}
                        : (value) => setState(() {
                            _selectedStatus = value;
                            _error = null;
                          }),
                    child: Column(
                      children: [
                        for (final option in widget.choices)
                          RadioListTile<VerificationResultStatus>(
                            title: Text(option.label),
                            value: option,
                            enabled: !_submitting,
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _rationaleController,
                    enabled: !_submitting,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Fundamento',
                      hintText:
                          'Explicá por qué confirmás o corregís el resultado',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribí el fundamento de la decisión.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrar decisión'),
          ),
        ],
      ),
    );
  }
}

class _HumanDecisionsSection extends StatelessWidget {
  const _HumanDecisionsSection({required this.events});

  final List<HumanDecisionEvent> events;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Decisiones registradas por Administradores',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final event in events) ...[
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          event.decisionType == HumanDecisionType.applicability
                              ? 'Decisión sobre aplicabilidad'
                              : 'Decisión sobre cumplimiento',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          _formatDate(event.decidedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Decisión',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(
                      label:
                          event.applicabilityDecision?.label ??
                          event.finalStatus?.label ??
                          '—',
                      tone:
                          event.applicabilityDecision ==
                              HumanApplicabilityDecision.applies
                          ? StatusTone.info
                          : event.applicabilityDecision ==
                                HumanApplicabilityDecision.notApplicable
                          ? StatusTone.neutral
                          : _resultStatusTone(
                              event.finalStatus ??
                                  VerificationResultStatus.unknown,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border(
                          left: BorderSide(color: AppColors.info, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fundamento escrito por el Administrador',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SelectableText(
                            event.rationale,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: VerificationCopyButton(
                        text: formatHumanDecisionForCopy(event),
                        label: 'Copiar decisión y fundamento',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _OriginalTicketObservation extends ConsumerStatefulWidget {
  const _OriginalTicketObservation({
    required this.runId,
    required this.resultId,
  });

  final String runId;
  final String resultId;

  @override
  ConsumerState<_OriginalTicketObservation> createState() =>
      _OriginalTicketObservationState();
}

class _OriginalTicketObservationState
    extends ConsumerState<_OriginalTicketObservation> {
  late Future<Map<String, dynamic>?> _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = ref
        .read(verificationRepositoryProvider)
        .ticketObservation(runId: widget.runId, resultId: widget.resultId);
  }

  @override
  Widget build(BuildContext context) => _DetailSection(
    title: 'Ticket consultado en la verificación inicial',
    child: FutureBuilder<Map<String, dynamic>?>(
      future: _ticket,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return TextButton.icon(
            onPressed: () => setState(() {
              _ticket = ref
                  .read(verificationRepositoryProvider)
                  .ticketObservation(
                    runId: widget.runId,
                    resultId: widget.resultId,
                  );
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('No se pudo cargar el ticket. Reintentar'),
          );
        }
        final ticket = snapshot.data;
        if (ticket == null) {
          return const Text(
            'Esta ejecución no conservó una copia del ticket. Las ejecuciones nuevas guardan los datos leídos para su revisión.',
          );
        }
        final readAt = DateTime.tryParse(
          ticket['observedAt']?.toString() ?? '',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (readAt != null) ...[
              Text('Datos leídos de Redmine el ${_formatDate(readAt)}'),
              const SizedBox(height: AppSpacing.sm),
            ],
            TicketSnapshotView(ticket: ticket),
          ],
        );
      },
    ),
  );
}

class _EvidenceReferencesSection extends StatelessWidget {
  const _EvidenceReferencesSection({required this.references});

  final List<EvidenceReference> references;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Referencias encontradas',
      child: references.isEmpty
          ? Text(
              'No hay referencias registradas para este resultado.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reference in references) ...[
                  _EvidenceReferenceCard(reference: reference),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _EvidenceReferenceCard extends StatelessWidget {
  const _EvidenceReferenceCard({required this.reference});

  final EvidenceReference reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = reference.safeWebUri;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              reference.displayName,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _MetaBadge(
                  icon: Icons.source_outlined,
                  label: reference.source.label,
                ),
                if (reference.kind.label != reference.source.label)
                  _MetaBadge(
                    icon: Icons.category_outlined,
                    label: reference.kind.label,
                  ),
                _MetaBadge(
                  icon: Icons.schedule_outlined,
                  label: _formatDate(reference.observedAt),
                ),
                if (reference.ticketId != null)
                  _MetaBadge(
                    icon: Icons.confirmation_num_outlined,
                    label: 'Ticket ${reference.ticketId}',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              'Identificador externo: ${reference.externalId}',
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: VerificationCopyButton(
                text:
                    'Referencia: ${reference.displayName}\nFuente: ${reference.source.label}\nIdentificador externo: ${reference.externalId}${uri == null ? '' : '\nEnlace: $uri'}',
                label: 'Copiar datos de la referencia',
              ),
            ),
            if (uri != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openReference(context, uri),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir referencia'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openReference(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la referencia web.')),
      );
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.location});

  final EvidenceLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label) = switch (location) {
      EvidenceLocation.input => (Icons.input_outlined, 'Entrada'),
      EvidenceLocation.activityRecord => (
        Icons.fact_check_outlined,
        'Registro de actividad',
      ),
      EvidenceLocation.output => (Icons.output_outlined, 'Salida'),
      EvidenceLocation.unknown => (
        Icons.help_outline,
        'Ubicación no reconocida',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({
    required this.icon,
    required this.label,
    required this.isAi,
  });

  final IconData icon;
  final String label;
  final bool isAi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isAi ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isAi
            ? AppColors.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainer,
        border: Border.all(
          color: isAi
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPagination extends StatelessWidget {
  const _ResultsPagination({
    required this.page,
    required this.disabled,
    required this.onPageChanged,
  });

  final PageInfo page;
  final bool disabled;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = page.page;
    final total = page.totalPages;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: disabled || current == 0
                  ? null
                  : () => onPageChanged(current - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Página ${current + 1} de $total',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Resultados ${current * page.size + 1}–${_endIndex(page)} de ${page.totalElements}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (disabled) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const SizedBox(height: 2, child: LinearProgressIndicator()),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: disabled || current + 1 >= total
                  ? null
                  : () => onPageChanged(current + 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsFailureBanner extends StatelessWidget {
  const _ResultsFailureBanner({required this.message, required this.onRetry});

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
              'No se pudieron cargar los resultados. $message',
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

class _ExecutionPendingContent extends StatelessWidget {
  const _ExecutionPendingContent({required this.run, required this.onBack});

  final VerificationRun run;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTotal = run.progress.total > 0;
    final fraction = hasTotal
        ? run.progress.fraction.clamp(0.0, 1.0).toDouble()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusChip(label: run.status.label, tone: StatusTone.info),
            const SizedBox(height: AppSpacing.lg),
            Text(
              run.status == VerificationRunStatus.queued
                  ? 'La ejecución todavía está en espera.'
                  : 'La verificación está procesando evidencias.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Los resultados se habilitan cuando la ejecución queda finalizada.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '${run.progress.fractionLabel} evidencias procesadas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: hasTotal
                  ? 'Progreso: ${run.progress.fractionLabel}'
                  : 'Progreso indeterminado',
              value: hasTotal
                  ? '${(fraction! * 100).round()} por ciento'
                  : null,
              child: LinearProgressIndicator(value: fraction, minHeight: 8),
            ),
            if (hasTotal) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(fraction! * 100).round()} %',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Volver al detalle de la ejecución'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutionFailedContent extends StatelessWidget {
  const _ExecutionFailedContent({
    required this.run,
    required this.onRetry,
    required this.onBack,
  });

  final VerificationRun run;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = run.failureMessage?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusChip(label: 'Fallida', tone: StatusTone.danger),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'La ejecución tuvo un error',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message?.isNotEmpty == true
                  ? message!
                  : 'No se informó el detalle del error de la ejecución.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No se presentan resultados porque la ejecución no terminó correctamente.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Volver al detalle de la ejecución'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownExecutionState extends StatelessWidget {
  const _UnknownExecutionState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      failure: const UnexpectedFailure(
        'La ejecución devolvió un estado no reconocido. No se pueden presentar resultados de forma segura.',
      ),
      onRetry: onRetry,
    );
  }
}

StatusTone _resultStatusTone(VerificationResultStatus status) =>
    switch (status) {
      VerificationResultStatus.complies => StatusTone.success,
      VerificationResultStatus.doesNotComply => StatusTone.danger,
      VerificationResultStatus.reviewRequired => StatusTone.warning,
      VerificationResultStatus.notApplicable => StatusTone.neutral,
      VerificationResultStatus.unknown => StatusTone.neutral,
    };

Color _resultStatusColor(VerificationResultStatus status) => switch (status) {
  VerificationResultStatus.complies => AppColors.success,
  VerificationResultStatus.doesNotComply => AppColors.danger,
  VerificationResultStatus.reviewRequired => AppColors.warningAccent,
  VerificationResultStatus.notApplicable => AppColors.textSecondary,
  VerificationResultStatus.unknown => AppColors.textSecondary,
};

String _formatDate(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

int _endIndex(PageInfo page) {
  final end = (page.page + 1) * page.size;
  return end > page.totalElements ? page.totalElements : end;
}
