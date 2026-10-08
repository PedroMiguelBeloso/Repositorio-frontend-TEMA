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
      body: value.when(
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
    );
  }
}

class _RunContent extends StatelessWidget {
  const _RunContent({
    required this.state,
    required this.isAdmin,
    required this.onRetry,
  });

  final VerificationRunDetailState state;
  final bool isAdmin;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = state.run;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RunField(
                        label: 'Alcance',
                        value: _scopeLabel(run.scope, run.macroActivityId),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RunField(
                        label: 'Iniciada',
                        value: _formatDate(run.startedAt),
                      ),
                      if (run.finishedAt != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RunField(
                          label: 'Finalizada',
                          value: _formatDate(run.finishedAt!),
                        ),
                      ],
                      if (run.note?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RunField(label: 'Nota', value: run.note!.trim()),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _RunField(label: 'Identificador', value: run.id),
                      const SizedBox(height: AppSpacing.md),
                      _RunField(label: 'Servicio', value: run.serviceId),
                      const SizedBox(height: AppSpacing.md),
                      _RunField(
                        label: 'Versión del proceso',
                        value: run.processVersionId,
                      ),
                    ],
                  ),
                ),
                if (run.status == VerificationRunStatus.failed &&
                    run.failureMessage?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RunCard(
                    title: 'Detalle del fallo',
                    child: Text(run.failureMessage!.trim()),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (run.status == VerificationRunStatus.completed) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(RouteNames.verificationResults(run.id)),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ver resultados'),
                  ),
                ],
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
        Text('Requieren revisión: ${progress.reviewRequired}'),
      ],
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
  VerificationRunStatus.completed => StatusTone.success,
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
