import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../processes/model/process_models.dart';
import '../../services/model/service_models.dart';
import '../data/verification_result_location_resolver.dart';
import '../model/verification_history_models.dart';
import '../model/verification_result_models.dart';
import '../viewmodel/verification_results_view_model.dart';

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
          onRetry: viewModel.retry,
          onPageChanged: viewModel.goToPage,
          onToggleResult: viewModel.toggleResult,
        ),
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({
    required this.state,
    required this.onRetry,
    required this.onPageChanged,
    required this.onToggleResult,
  });

  final VerificationResultsState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onToggleResult;

  @override
  Widget build(BuildContext context) {
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
                child: _buildBody(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.run.status) {
      case VerificationRunStatus.queued:
      case VerificationRunStatus.running:
        return _ExecutionPendingContent(
          run: state.run,
          onBack: () => context.go(
            RouteNames.verificationDetails(state.run.id),
          ),
        );
      case VerificationRunStatus.failed:
        return _ExecutionFailedContent(
          run: state.run,
          onRetry: onRetry,
          onBack: () => context.go(
            RouteNames.verificationDetails(state.run.id),
          ),
        );
      case VerificationRunStatus.completed:
        return _CompletedResultsContent(
          state: state,
          onRetry: onRetry,
          onPageChanged: onPageChanged,
          onToggleResult: onToggleResult,
        );
      case VerificationRunStatus.unknown:
        return _UnknownExecutionState(onRetry: onRetry);
    }
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.state,
    required this.onRetry,
  });

  final VerificationResultsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = OutlinedButton.icon(
              onPressed: state.isChangingPage ? null : onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            );

            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resultados de la verificación',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Revisá qué ocurrió con cada evidencia esperada y el fundamento de la conclusión.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusChip(
                        label: state.run.status.label,
                        tone: StatusTone.success,
                      ),
                      actions,
                    ],
                  ),
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
                      Text(
                        'Resultados de la verificación',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Revisá qué ocurrió con cada evidencia esperada y el fundamento de la conclusión.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(
                      label: state.run.status.label,
                      tone: StatusTone.success,
                    ),
                    actions,
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _TraceabilityNote(),
      ],
    );
  }
}

class _CompletedResultsContent extends StatelessWidget {
  const _CompletedResultsContent({
    required this.state,
    required this.onRetry,
    required this.onPageChanged,
    required this.onToggleResult,
  });

  final VerificationResultsState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onToggleResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = state.page;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsHeader(state: state, onRetry: onRetry),
        const SizedBox(height: AppSpacing.lg),
        if (state.resultsFailure != null) ...[
          _ResultsFailureBanner(
            message: state.resultsFailure!.message,
            onRetry: onRetry,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (page != null && page.totalElements > 0) ...[
          Text(
            '${page.totalElements} resultados',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final result in state.items) ...[
            VerificationResultTile(
              result: result,
              locationContext: state.locationContext[result.id],
              isExpanded: result.id == state.selectedResultId,
              onToggle: () => onToggleResult(result.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (page.totalPages > 1) ...[
            const SizedBox(height: AppSpacing.md),
            _ResultsPagination(
              page: page,
              disabled: state.isChangingPage,
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

class _TraceabilityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Se muestran referencias y metadatos de evidencia. La pantalla no inspecciona ni promete inspeccionar el contenido de documentos confidenciales o adjuntos.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationResultTile extends StatelessWidget {
  const VerificationResultTile({
    super.key,
    required this.result,
    required this.locationContext,
    required this.isExpanded,
    required this.onToggle,
  });

  final VerificationResult result;
  final VerificationResultLocationContext? locationContext;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusTone = _resultStatusTone(result.effectiveStatus);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
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
                          Text(
                            result.displayName,
                            style: theme.textTheme.titleMedium,
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
                            ],
                          ),
                          if (locationContext != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _ProcessHierarchyBadge(
                              location: result.location,
                              contextData: locationContext!,
                            ),
                          ],
                        ],
                      );

                      final status = StatusChip(
                        label: result.effectiveStatus.label,
                        tone: statusTone,
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
                          isExpanded ? 'Ocultar fundamento' : 'Ver fundamento y referencias',
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
                    child: _ResultDetails(result: result),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
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
        _DetailSection(
          title: 'Fundamento',
          child: Text(result.rationale),
        ),
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
                      Expanded(child: Text(limitation)),
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
          _ApplicabilitySection(assessment: result.applicability),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: 'Propuesta automática',
          child: Row(
            children: [
              StatusChip(
                label: result.proposedStatus.label,
                tone: _resultStatusTone(result.proposedStatus),
              ),
            ],
          ),
        ),
        if (result.humanDecisions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _HumanDecisionsSection(events: result.humanDecisions),
        ],
        const SizedBox(height: AppSpacing.lg),
        _EvidenceReferencesSection(references: result.evidence),
      ],
    );
  }
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
  const _ApplicabilitySection({required this.assessment});

  final ApplicabilityAssessment assessment;

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
            Text(assessment.rationale),
            if (assessment.limitations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final limitation in assessment.limitations) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(limitation)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
            if (isUndetermined) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La aplicabilidad quedó indeterminada y requiere intervención de un Administrador. Esta pantalla solo permite consultar la decisión pendiente; su resolución pertenece a 7.3.5.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
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
      title: 'Decisiones humanas previas',
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
                          event.decisionType.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          _formatDate(event.decidedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (event.applicabilityDecision != null)
                      Text('Aplicabilidad: ${event.applicabilityDecision!.label}'),
                    if (event.finalStatus != null)
                      Text('Estado: ${event.finalStatus!.label}'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(event.rationale),
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
            Text(reference.displayName, style: theme.textTheme.titleSmall),
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
            Text(
              'Identificador externo: ${reference.externalId}',
              style: theme.textTheme.bodySmall,
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
        const SnackBar(
          content: Text('No se pudo abrir la referencia web.'),
        ),
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
          'Registro de actividad'
        ),
      EvidenceLocation.output => (Icons.output_outlined, 'Salida'),
      EvidenceLocation.unknown => (Icons.help_outline, 'Ubicación no reconocida'),
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
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessHierarchyBadge extends StatelessWidget {
  const _ProcessHierarchyBadge({
    required this.location,
    required this.contextData,
  });

  final EvidenceLocation location;
  final VerificationResultLocationContext contextData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActivityRecord = location == EvidenceLocation.activityRecord;
    final background = isActivityRecord
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final foreground = isActivityRecord
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            isActivityRecord
                ? Icons.account_tree_outlined
                : Icons.schema_outlined,
            size: 15,
            color: foreground,
          ),
          Text(
            'Macroactividad: ${contextData.macroActivityName}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isActivityRecord && contextData.hasActivity)
            Text(
              '· Actividad: ${contextData.activityName}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
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
                    const SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(),
                    ),
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
              value: hasTotal ? '${(fraction! * 100).round()} por ciento' : null,
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

StatusTone _resultStatusTone(VerificationResultStatus status) => switch (status) {
      VerificationResultStatus.complies => StatusTone.success,
      VerificationResultStatus.doesNotComply => StatusTone.danger,
      VerificationResultStatus.reviewRequired => StatusTone.warning,
      VerificationResultStatus.notApplicable => StatusTone.neutral,
      VerificationResultStatus.unknown => StatusTone.neutral,
    };

String _formatDate(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

int _endIndex(PageInfo page) {
  final end = (page.page + 1) * page.size;
  return end > page.totalElements ? page.totalElements : end;
}
