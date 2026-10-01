import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/service_models.dart';
import '../viewmodel/service_detail_view_model.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceDetailViewModelProvider(serviceId));
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del servicio'),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: isCompact
                  ? IconButton(
                      tooltip: 'Editar',
                      onPressed: () =>
                          context.push(RouteNames.serviceEdit(serviceId)),
                      icon: const Icon(Icons.edit_outlined),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          context.push(RouteNames.serviceEdit(serviceId)),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
            ),
        ],
      ),
      body: AsyncContent<Service>(
        value: state,
        errorMessage: 'No se pudo cargar el detalle del servicio.',
        onRetry: () => ref.invalidate(
          serviceDetailViewModelProvider(serviceId),
        ),
        builder: (service) => _DetailContent(service: service),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
        _SectionCard(
          title: 'Datos del servicio',
          children: [
            _DetailRow(label: 'Nombre del servicio', value: service.name),
            _DetailRow(label: 'Cliente', value: service.client),
            _DetailRow(label: 'Tipo', value: service.serviceType.label),
            _StatusDetailRow(
              label: 'Estado',
              status: service.status,
            ),
            _DetailRow(label: 'Revisión', value: '${service.revision}'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Procesos asignados',
          children: service.processes.isEmpty
              ? [
                  const Text('No hay procesos asignados.'),
                ]
              : [
                  for (final process in service.processes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text(process.processName),
                      subtitle: Text(
                        'Versión ${process.officialVersion}',
                      ),
                    ),
                ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Fuentes de evidencia',
          children: [
            _SourceRow(
              icon: Icons.folder_outlined,
              label: 'Google Drive',
              value: service.sources.hasDrive
                  ? service.sources.driveFolderName ?? 'Carpeta configurada'
                  : 'No configurada',
            ),
            _SourceRow(
              icon: Icons.assignment_outlined,
              label: 'Redmine',
              value: service.sources.hasRedmine
                  ? service.sources.redmineProjectName ?? 'Proyecto configurado'
                  : 'No configurado',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
            const _InfoBanner(
              text:
                  'Los cambios se usarán en las próximas verificaciones. Las verificaciones anteriores conservan su información.',
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: AppSpacing.xs),
                Text(value),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(label, style: labelStyle),
              ),
              Expanded(child: Text(value)),
            ],
          ),
        );
      },
    );
  }
}

class _StatusDetailRow extends StatelessWidget {
  const _StatusDetailRow({required this.label, required this.status});

  final String label;
  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final statusChip = StatusChip(
            label: status.label,
            tone: _statusTone(status),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: AppSpacing.xs),
                statusChip,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: Text(label, style: labelStyle),
              ),
              statusChip,
            ],
          );
        },
      ),
    );
  }

  StatusTone _statusTone(ServiceStatus status) => switch (status) {
    ServiceStatus.active => StatusTone.success,
    ServiceStatus.inactive => StatusTone.neutral,
    ServiceStatus.unknown => StatusTone.warning,
  };
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
