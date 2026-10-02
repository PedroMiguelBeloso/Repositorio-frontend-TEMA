import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/integration_status_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/integration_source.dart';
import '../model/integration_status.dart';
import '../viewmodel/integrations_view_model.dart';
import 'integration_state_presentation.dart';

class IntegrationsPage extends ConsumerWidget {
  const IntegrationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(integrationsViewModelProvider);
    final viewModel = ref.read(integrationsViewModelProvider.notifier);

    ref.listen(integrationsViewModelProvider, (previous, next) {
      final failure = next.value?.actionFailure;
      if (failure != null && previous?.value?.actionFailure != failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Integraciones', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estado general de las conexiones con Google Drive y Redmine. '
            'La disponibilidad no confirma el acceso a carpetas o proyectos '
            'configurados por servicio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: AsyncContent<IntegrationsViewState>(
              value: value,
              errorMessage: 'No se pudieron cargar las integraciones.',
              onRetry: viewModel.retry,
              builder: (state) => _IntegrationContent(
                state: state,
                onTest: viewModel.testIntegrations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationContent extends StatelessWidget {
  const _IntegrationContent({required this.state, required this.onTest});

  final IntegrationsViewState state;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _statusCard(IntegrationSource.drive),
          _statusCard(IntegrationSource.redmine),
        ];
        final cardLayout = constraints.maxWidth >= 700
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: cards[1]),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cards[0],
                  const SizedBox(height: AppSpacing.lg),
                  cards[1],
                ],
              );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cardLayout,
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: state.isTesting ? null : onTest,
                icon: state.isTesting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Probar integraciones'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusCard(IntegrationSource source) {
    final status = state.statusFor(source);
    if (status == null) {
      return IntegrationStatusCard(
        sourceLabel: source.label,
        statusLabel: 'Sin información',
        tone: StatusTone.neutral,
      );
    }
    return _resolvedStatusCard(source, status);
  }

  IntegrationStatusCard _resolvedStatusCard(
    IntegrationSource source,
    IntegrationStatus status,
  ) => IntegrationStatusCard(
    sourceLabel: source.label,
    statusLabel: status.state.label,
    tone: status.state.tone,
    checkedAtLabel: DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(status.checkedAt.toLocal()),
    message: status.message,
  );
}