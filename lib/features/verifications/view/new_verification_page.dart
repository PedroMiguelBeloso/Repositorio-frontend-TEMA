import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import '../model/verification_models.dart';
import '../viewmodel/new_verification_view_model.dart';

class NewVerificationPage extends ConsumerStatefulWidget {
  const NewVerificationPage({super.key});

  @override
  ConsumerState<NewVerificationPage> createState() => _NewVerificationPageState();
}

class _NewVerificationPageState extends ConsumerState<NewVerificationPage> {
  final _serviceIdController = TextEditingController();
  final _processVersionController = TextEditingController();
  final _macroActivityController = TextEditingController();
  final Map<String, TextEditingController> _queryControllers = {};

  VerificationScope _scope = VerificationScope.macroActivity;

  @override
  void dispose() {
    _serviceIdController.dispose();
    _processVersionController.dispose();
    _macroActivityController.dispose();
    for (final controller in _queryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newVerificationViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva verificación'),
      ),
      body: AsyncContent<NewVerificationState>(
        value: state,
        errorMessage: 'No se pudo cargar la vista previa de verificación.',
        onRetry: () => ref.read(newVerificationViewModelProvider.notifier).loadPreview(
          serviceId: _serviceIdController.text,
          processVersionId: _processVersionController.text,
          scope: _scope,
          macroActivityId: _macroActivityController.text,
        ),
        builder: (data) {
          final serviceId = _serviceIdController.text.trim();
          final processVersionId = _processVersionController.text.trim();
          final viewModel = ref.read(newVerificationViewModelProvider.notifier);

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alcance y vista previa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _serviceIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Service ID',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _processVersionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Process version ID',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<VerificationScope>(
                                    initialValue: _scope,
                                    decoration: const InputDecoration(
                                      labelText: 'Alcance',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: VerificationScope.values
                                        .map(
                                          (scope) => DropdownMenuItem(
                                            value: scope,
                                            child: Text(
                                              scope == VerificationScope.process
                                                  ? 'Proceso'
                                                  : 'Macroactividad',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _scope = value);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _macroActivityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Macroactivity ID (opcional)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: data.isLoadingPreview
                                    ? null
                                    : () => viewModel.loadPreview(
                                          serviceId: serviceId,
                                          processVersionId: processVersionId,
                                          scope: _scope,
                                          macroActivityId: _macroActivityController.text,
                                        ),
                                icon: const Icon(Icons.preview_outlined),
                                label: const Text('Cargar vista previa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (data.previewFailure != null && data.preview == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(data.previewFailure!.message),
                          ),
                        ),
                      ),
                    if (data.preview != null) ...[
                      const SizedBox(height: 20),
                      if (data.preview!.ticketSelectionGroups.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No hay grupos de tickets para este alcance. La verificación se iniciará sin selecciones de tickets.',
                            ),
                          ),
                        )
                      else ...[
                        for (final group in data.preview!.ticketSelectionGroups)
                          _TicketGroupCard(
                            group: group,
                            state: data,
                            onSearch: (query) => viewModel.searchTicketsForGroup(
                              groupId: group.id,
                              query: query,
                            ),
                            onSearchPage: (page) => viewModel.searchTicketsForGroup(
                              groupId: group.id,
                              query: data.ticketSearchStates[group.id]?.query ?? '',
                              page: page,
                            ),
                            onSelect: (ticketId) => viewModel.selectTicket(
                              groupId: group.id,
                              ticketId: ticketId,
                            ),
                            onRemove: (ticketId) => viewModel.removeTicket(
                              groupId: group.id,
                              ticketId: ticketId,
                            ),
                            queryController: _queryControllers.putIfAbsent(
                              group.id,
                              () => TextEditingController(
                                text: data.ticketSearchStates[group.id]?.query ?? '',
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: !data.canStart || data.isStarting
                                ? null
                                : () => viewModel.startVerification(),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Iniciar verificación'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TicketGroupCard extends StatelessWidget {
  const _TicketGroupCard({
    required this.group,
    required this.state,
    required this.onSearch,
    required this.onSearchPage,
    required this.onSelect,
    required this.onRemove,
    required this.queryController,
  });

  final TicketSelectionGroup group;
  final NewVerificationState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onSearchPage;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final TextEditingController queryController;

  @override
  Widget build(BuildContext context) {
    final ticketState = state.ticketSearchStates[group.id] ?? const TicketSearchState();
    final selectedIds = state.selections[group.id] ?? const <String>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    group.cardinality == Cardinality.one ? 'ONE' : 'MULTIPLE',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.required
                  ? 'Selección obligatoria'
                  : 'Selección opcional',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por asunto o ID',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => onSearch(queryController.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ticketState.failure != null)
              Text(
                ticketState.failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (ticketState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (ticketState.items.isEmpty)
              const Text('No se encontraron tickets con este criterio.')
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ticketState.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final ticket = ticketState.items[index];
                  final selected = selectedIds.contains(ticket.id);

                  return group.isSingle
                      ? ChoiceChip(
                          label: Text('${ticket.id} · ${ticket.subject}'),
                          selected: selected,
                          onSelected: (_) => onSelect(ticket.id),
                          avatar: selected ? const Icon(Icons.check) : null,
                          showCheckmark: false,
                        )
                      : CheckboxListTile(
                          value: selected,
                          onChanged: (value) {
                            if (value == true) {
                              onSelect(ticket.id);
                            } else {
                              onRemove(ticket.id);
                            }
                          },
                          title: Text('${ticket.id} · ${ticket.subject}'),
                          subtitle: Text(ticket.status),
                        );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: ticketState.page.hasPrevious
                        ? () => onSearchPage(ticketState.page.page - 1)
                        : null,
                    child: const Text('Anterior'),
                  ),
                  TextButton(
                    onPressed: ticketState.page.hasNext
                        ? () => onSearchPage(ticketState.page.page + 1)
                        : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
            if (selectedIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Seleccionados'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedIds
                    .map(
                      (ticketId) => InputChip(
                        label: Text(ticketId),
                        onDeleted: () => onRemove(ticketId),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
