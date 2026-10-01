import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../model/service_models.dart';
import '../viewmodel/service_detail_view_model.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceDetailViewModelProvider(serviceId));
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del servicio'),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () =>
                    context.push(RouteNames.serviceEdit(serviceId)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          failure: _asFailure(error),
          onRetry: () => ref.invalidate(
            serviceDetailViewModelProvider(serviceId),
          ),
        ),
        data: (service) => _DetailContent(service: service),
      ),
    );
  }

  AppFailure _asFailure(Object error) {
    if (error is AppFailure) return error;
    return const UnexpectedFailure(
      'No se pudo cargar el detalle del servicio.',
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionCard(
          title: 'Datos del servicio',
          children: [
            _DetailRow(label: 'Nombre del servicio', value: service.name),
            _DetailRow(label: 'Cliente', value: service.client),
            _DetailRow(label: 'Tipo', value: service.serviceType.label),
            _DetailRow(label: 'Estado', value: service.status.label),
            _DetailRow(label: 'Revisión', value: '${service.revision}'),
          ],
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        const _InfoBanner(
          text:
              'Los cambios se usarán en las próximas verificaciones. Las verificaciones anteriores conservan su información.',
        ),
      ],
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
            const SizedBox(height: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.failure, required this.onRetry});

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
