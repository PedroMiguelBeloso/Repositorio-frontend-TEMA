import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../model/service_models.dart';
import '../viewmodel/service_list_view_model.dart';

class ServiceListPage extends ConsumerWidget {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceListViewModelProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => context.push(RouteNames.servicesNewPath),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo servicio'),
              ),
            ),
        ],
      ),
      body: state.when(
        loading: () => const AsyncContent(
          isLoading: true,
          child: SizedBox.shrink(),
        ),
        error: (error, _) => AsyncContent(
          failure: _asFailure(error),
          onRetry: () => ref.invalidate(serviceListViewModelProvider),
          child: const SizedBox.shrink(),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return _EmptyServices(isAdmin: isAdmin);
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(serviceListViewModelProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: data.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ServiceCard(
                      service: data.items[index],
                      onOpen: () => context.push(
                        RouteNames.serviceDetails(data.items[index].id),
                      ),
                    ),
                  ),
                ),
              ),
              _PaginationBar(
                page: data.page,
                isLoading: data.isPaging,
                failure: data.pageFailure,
                onPrevious: () => ref
                    .read(serviceListViewModelProvider.notifier)
                    .previousPage(),
                onNext: () => ref
                    .read(serviceListViewModelProvider.notifier)
                    .nextPage(),
                onRetry: () => ref.invalidate(serviceListViewModelProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  AppFailure _asFailure(Object error) {
    if (error is AppFailure) return error;
    return const UnexpectedFailure(
      'No se pudo cargar la lista de servicios.',
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onOpen});

  final Service service;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor = service.status == ServiceStatus.active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('Cliente: ${service.client}'),
                    const SizedBox(height: 4),
                    Text('Tipo: ${service.serviceType.label}'),
                  ],
                ),
              ),
              Chip(
                avatar: Icon(Icons.circle, size: 10, color: statusColor),
                label: Text(service.status.label),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Ver detalle',
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  const _EmptyServices({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.miscellaneous_services_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No hay servicios configurados.'),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(RouteNames.servicesNewPath),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo servicio'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.isLoading,
    required this.failure,
    required this.onPrevious,
    required this.onNext,
    required this.onRetry,
  });

  final PageInfo page;
  final bool isLoading;
  final AppFailure? failure;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          if (failure case final error?) ...[
            Row(
              children: [
                Expanded(child: Text(error.message)),
                TextButton(onPressed: onRetry, child: const Text('Reintentar')),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Página ${page.page + 1} de ${page.totalPages}'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isLoading || !page.hasPrevious ? null : onPrevious,
                tooltip: 'Página anterior',
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: isLoading || !page.hasNext ? null : onNext,
                tooltip: 'Página siguiente',
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
