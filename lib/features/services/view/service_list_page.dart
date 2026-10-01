import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/service_models.dart';
import '../viewmodel/service_list_view_model.dart';

class ServiceListPage extends ConsumerWidget {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceListViewModelProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin == true;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: isCompact
                  ? IconButton(
                      tooltip: 'Nuevo servicio',
                      onPressed: () =>
                          context.push(RouteNames.servicesNewPath),
                      icon: const Icon(Icons.add),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          context.push(RouteNames.servicesNewPath),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo servicio'),
                    ),
            ),
        ],
      ),
      body: AsyncContent<ServiceListState>(
        value: state,
        errorMessage: 'No se pudo cargar la lista de servicios.',
        onRetry: () => ref.invalidate(serviceListViewModelProvider),
        builder: (data) {
          if (data.items.isEmpty) {
            return _EmptyServices(isAdmin: isAdmin);
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(serviceListViewModelProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        itemCount: data.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
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
                    onRetry: () =>
                        ref.invalidate(serviceListViewModelProvider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onOpen});

  final Service service;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final status = StatusChip(
          label: service.status.label,
          tone: _statusTone(service.status),
        );
        final openAction = IconButton(
          tooltip: 'Ver detalle',
          onPressed: onOpen,
          icon: const Icon(Icons.chevron_right),
        );

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ServiceSummary(service: service, theme: theme),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            status,
                            openAction,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ServiceSummary(
                            service: service,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        status,
                        const SizedBox(width: AppSpacing.sm),
                        openAction,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  StatusTone _statusTone(ServiceStatus status) => switch (status) {
    ServiceStatus.active => StatusTone.success,
    ServiceStatus.inactive => StatusTone.neutral,
    ServiceStatus.unknown => StatusTone.warning,
  };
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service, required this.theme});

  final Service service;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service.name,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Cliente: ${service.client}'),
        const SizedBox(height: AppSpacing.xs),
        Text('Tipo: ${service.serviceType.label}'),
      ],
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
          const EmptyState(
            message: 'No hay servicios configurados.',
            icon: Icons.miscellaneous_services_outlined,
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          if (failure case final error?) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    error.message,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Página ${page.page + 1} de ${page.totalPages}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.xs),
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
