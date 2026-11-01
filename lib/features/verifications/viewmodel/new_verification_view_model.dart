import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../services/model/service_models.dart';
import '../data/verification_repository_impl.dart';
import 'verification_history_view_model.dart';
import '../model/new_verification_models.dart';

const _unchanged = Object();

class NewVerificationState {
  const NewVerificationState({
    required this.services,
    this.serviceId,
    this.processes = const [],
    this.processVersionId,
    this.scope = VerificationScope.process,
    this.macroActivityId,
    this.note = '',
    this.preview,
    this.tickets,
    this.ticketQuery = '',
    this.selectedTickets = const {},
    this.knownTickets = const {},
    this.isLoadingProcesses = false,
    this.isLoadingPreview = false,
    this.isLoadingTickets = false,
    this.isStarting = false,
    this.actionFailure,
  });

  final List<Service> services;
  final String? serviceId;
  final List<VerifiableProcess> processes;
  final String? processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final String note;
  final VerificationPreview? preview;
  final TicketPage? tickets;
  final String ticketQuery;
  final Map<String, Set<String>> selectedTickets;

  /// Tickets already seen in search results, retained across pages and filters.
  final Map<String, TicketSummary> knownTickets;
  final bool isLoadingProcesses;
  final bool isLoadingPreview;
  final bool isLoadingTickets;
  final bool isStarting;
  final AppFailure? actionFailure;

  Service? get service {
    for (final item in services) {
      if (item.id == serviceId) return item;
    }
    return null;
  }

  VerifiableProcess? get process {
    for (final item in processes) {
      if (item.id == processVersionId) return item;
    }
    return null;
  }

  bool get canPreview =>
      serviceId != null &&
      processVersionId != null &&
      (scope == VerificationScope.process || macroActivityId != null) &&
      note.length <= 1000 &&
      !isLoadingProcesses &&
      !isLoadingPreview &&
      !isStarting;

  bool get canStart {
    if (preview == null ||
        isStarting ||
        isLoadingTickets ||
        note.length > 1000) {
      return false;
    }
    for (final group in preview!.ticketSelectionGroups) {
      final count = selectedTickets[group.id]?.length ?? 0;
      if (group.isSingle && group.required && count != 1) return false;
      if (group.isSingle && count > 1) return false;
      if (group.required && count == 0) return false;
    }
    return true;
  }

  NewVerificationState copyWith({
    List<Service>? services,
    Object? serviceId = _unchanged,
    List<VerifiableProcess>? processes,
    Object? processVersionId = _unchanged,
    VerificationScope? scope,
    Object? macroActivityId = _unchanged,
    String? note,
    Object? preview = _unchanged,
    Object? tickets = _unchanged,
    String? ticketQuery,
    Map<String, Set<String>>? selectedTickets,
    Map<String, TicketSummary>? knownTickets,
    bool? isLoadingProcesses,
    bool? isLoadingPreview,
    bool? isLoadingTickets,
    bool? isStarting,
    Object? actionFailure = _unchanged,
  }) => NewVerificationState(
    services: services ?? this.services,
    serviceId: identical(serviceId, _unchanged)
        ? this.serviceId
        : serviceId as String?,
    processes: processes ?? this.processes,
    processVersionId: identical(processVersionId, _unchanged)
        ? this.processVersionId
        : processVersionId as String?,
    scope: scope ?? this.scope,
    macroActivityId: identical(macroActivityId, _unchanged)
        ? this.macroActivityId
        : macroActivityId as String?,
    note: note ?? this.note,
    preview: identical(preview, _unchanged)
        ? this.preview
        : preview as VerificationPreview?,
    tickets: identical(tickets, _unchanged)
        ? this.tickets
        : tickets as TicketPage?,
    ticketQuery: ticketQuery ?? this.ticketQuery,
    selectedTickets: selectedTickets ?? this.selectedTickets,
    knownTickets: knownTickets ?? this.knownTickets,
    isLoadingProcesses: isLoadingProcesses ?? this.isLoadingProcesses,
    isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
    isLoadingTickets: isLoadingTickets ?? this.isLoadingTickets,
    isStarting: isStarting ?? this.isStarting,
    actionFailure: identical(actionFailure, _unchanged)
        ? this.actionFailure
        : actionFailure as AppFailure?,
  );
}

class NewVerificationViewModel extends AsyncNotifier<NewVerificationState> {
  int _selectionRevision = 0;
  int _ticketRevision = 0;

  @override
  Future<NewVerificationState> build() async {
    final repository = ref.read(verificationRepositoryProvider);
    final services = <Service>[];
    var page = 0;
    while (true) {
      final result = await repository.listServices(page: page, size: 100);
      services.addAll(result.items);
      if (!result.page.hasNext) break;
      page++;
    }
    return NewVerificationState(services: services);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> selectService(String? id) async {
    final current = state.value;
    if (current == null || current.serviceId == id) return;
    final revision = ++_selectionRevision;
    state = AsyncData(
      current.copyWith(
        serviceId: id,
        processes: const [],
        processVersionId: null,
        macroActivityId: null,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        isLoadingProcesses: id != null,
        isLoadingPreview: false,
        isLoadingTickets: false,
        actionFailure: null,
      ),
    );
    if (id == null) return;
    try {
      final processes = await ref
          .read(verificationRepositoryProvider)
          .verifiableProcesses(id);
      if (!ref.mounted || revision != _selectionRevision) return;
      state = AsyncData(
        state.requireValue.copyWith(
          processes: processes,
          isLoadingProcesses: false,
        ),
      );
    } catch (error) {
      if (!ref.mounted || revision != _selectionRevision) return;
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingProcesses: false,
          actionFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudieron cargar los procesos.',
          ),
        ),
      );
    }
  }

  void selectProcess(String? id) {
    final current = state.value;
    if (current == null) return;
    ++_selectionRevision;
    state = AsyncData(
      current.copyWith(
        processVersionId: id,
        macroActivityId: null,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        isLoadingPreview: false,
        isLoadingTickets: false,
        actionFailure: null,
      ),
    );
  }

  void selectScope(VerificationScope scope) {
    final current = state.value;
    if (current == null) return;
    ++_selectionRevision;
    state = AsyncData(
      current.copyWith(
        scope: scope,
        macroActivityId: null,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        isLoadingPreview: false,
        isLoadingTickets: false,
        actionFailure: null,
      ),
    );
  }

  void selectMacroActivity(String? id) {
    final current = state.value;
    if (current == null) return;
    ++_selectionRevision;
    state = AsyncData(
      current.copyWith(
        macroActivityId: id,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        isLoadingPreview: false,
        isLoadingTickets: false,
        actionFailure: null,
      ),
    );
  }

  void setNote(String note) {
    final current = state.value;
    if (current == null) return;
    ++_selectionRevision;
    state = AsyncData(
      current.copyWith(
        note: note,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        isLoadingPreview: false,
        isLoadingTickets: false,
        actionFailure: null,
      ),
    );
  }

  Future<void> loadPreview() async {
    final current = state.value;
    if (current == null || !current.canPreview) return;
    final revision = _selectionRevision;
    state = AsyncData(
      current.copyWith(
        isLoadingPreview: true,
        preview: null,
        tickets: null,
        selectedTickets: const {},
        knownTickets: const {},
        actionFailure: null,
      ),
    );
    try {
      final preview = await ref
          .read(verificationRepositoryProvider)
          .preview(
            VerificationTarget(
              serviceId: current.serviceId!,
              processVersionId: current.processVersionId!,
              scope: current.scope,
              macroActivityId: current.macroActivityId,
              note: current.note.trim(),
            ),
          );
      if (!ref.mounted || revision != _selectionRevision) return;
      state = AsyncData(
        state.requireValue.copyWith(preview: preview, isLoadingPreview: false),
      );
      if (preview.ticketSelectionGroups.isNotEmpty) await searchTickets('');
    } catch (error) {
      if (!ref.mounted || revision != _selectionRevision) return;
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingPreview: false,
          actionFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo preparar la verificación.',
          ),
        ),
      );
    }
  }

  Future<void> searchTickets(String query, {int page = 0}) async {
    final current = state.value;
    if (current?.serviceId == null || current?.preview == null) return;
    final revision = _selectionRevision;
    final ticketRevision = ++_ticketRevision;
    state = AsyncData(
      current!.copyWith(
        isLoadingTickets: true,
        ticketQuery: query,
        actionFailure: null,
      ),
    );
    try {
      final tickets = await ref
          .read(verificationRepositoryProvider)
          .searchTickets(current.serviceId!, query: query, page: page);
      if (!ref.mounted ||
          revision != _selectionRevision ||
          ticketRevision != _ticketRevision) {
        return;
      }
      state = AsyncData(
        state.requireValue.copyWith(
          tickets: tickets,
          knownTickets: {
            ...state.requireValue.knownTickets,
            for (final ticket in tickets.items) ticket.id: ticket,
          },
          isLoadingTickets: false,
        ),
      );
    } catch (error) {
      if (!ref.mounted ||
          revision != _selectionRevision ||
          ticketRevision != _ticketRevision) {
        return;
      }
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingTickets: false,
          actionFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudieron consultar los tickets.',
          ),
        ),
      );
    }
  }

  void toggleTicket(TicketSelectionGroup group, String ticketId) {
    final current = state.value;
    if (current == null) return;
    final selections = {
      for (final entry in current.selectedTickets.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final ids = selections[group.id] ?? <String>{};
    if (!ids.remove(ticketId)) {
      if (group.isSingle) ids.clear();
      ids.add(ticketId);
    }
    selections[group.id] = ids;
    state = AsyncData(
      current.copyWith(selectedTickets: selections, actionFailure: null),
    );
  }

  Future<String?> start() async {
    final current = state.value;
    if (current == null || !current.canStart) return null;
    state = AsyncData(current.copyWith(isStarting: true, actionFailure: null));
    try {
      final id = await ref
          .read(verificationRepositoryProvider)
          .start(
            current.preview!,
            current.note.trim(),
            current.selectedTickets,
          );
      await ref.read(verificationHistoryViewModelProvider.notifier).refresh();
      return id;
    } catch (error) {
      if (ref.mounted) {
        final failure = safeAppFailure(
          error,
          fallbackMessage: 'No se pudo iniciar la verificación.',
        );
        state = AsyncData(
          state.requireValue.copyWith(
            preview: failure is ConflictFailure ? null : _unchanged,
            tickets: failure is ConflictFailure ? null : _unchanged,
            selectedTickets: failure is ConflictFailure ? const {} : null,
            knownTickets: failure is ConflictFailure ? const {} : null,
            actionFailure: failure,
          ),
        );
      }
      return null;
    } finally {
      if (ref.mounted) {
        state = AsyncData(state.requireValue.copyWith(isStarting: false));
      }
    }
  }
}

final newVerificationViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      NewVerificationViewModel,
      NewVerificationState
    >(NewVerificationViewModel.new);
