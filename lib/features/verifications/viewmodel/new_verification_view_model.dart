import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/verification_repository.dart';
import '../data/verification_repository_provider.dart';
import '../model/verification_models.dart';

class NewVerificationViewModel extends AsyncNotifier<NewVerificationState> {
  VerificationRepository get _repository => ref.read(verificationRepositoryProvider);

  @override
  Future<NewVerificationState> build() async => NewVerificationState();

  Future<void> loadPreview({
    required String serviceId,
    required String processVersionId,
    required VerificationScope scope,
    String? macroActivityId,
  }) async {
    final normalizedServiceId = serviceId.trim();
    final normalizedProcessVersionId = processVersionId.trim();
    if (normalizedServiceId.isEmpty || normalizedProcessVersionId.isEmpty) {
      final current = state.value ?? NewVerificationState();
      state = AsyncData(
        current.copyWith(
          preview: null,
          serviceId: normalizedServiceId,
          processVersionId: normalizedProcessVersionId,
          scope: scope,
          macroActivityId: macroActivityId?.trim(),
          previewFailure: const ValidationFailure(
            'Debés indicar servicio y versión del proceso.',
          ),
          clearPreviewFailure: false,
        ),
      );
      return;
    }

    final current = state.value ?? NewVerificationState();
    state = AsyncData(
      current.copyWith(
        serviceId: normalizedServiceId,
        processVersionId: normalizedProcessVersionId,
        scope: scope,
        macroActivityId: macroActivityId?.trim(),
        clearPreviewFailure: true,
        isLoadingPreview: true,
      ),
    );

    try {
      final preview = await _repository.previewVerification(
        serviceId: normalizedServiceId,
        processVersionId: normalizedProcessVersionId,
        scope: scope,
        macroActivityId: macroActivityId?.trim(),
      );
      state = AsyncData(
        current.copyWith(
          preview: preview,
          serviceId: normalizedServiceId,
          processVersionId: normalizedProcessVersionId,
          scope: scope,
          macroActivityId: macroActivityId?.trim(),
          previewFailure: null,
          isLoadingPreview: false,
          ticketSearchStates: const {},
          selections: const {},
        ),
      );
    } on AppFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          preview: null,
          isLoadingPreview: false,
          previewFailure: failure,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          preview: null,
          isLoadingPreview: false,
          previewFailure: const UnexpectedFailure(
            'No se pudo cargar la vista previa de verificación.',
          ),
        ),
      );
    }
  }

  Future<void> searchTicketsForGroup({
    required String groupId,
    required String query,
    int page = 0,
  }) async {
    final current = state.value ?? NewVerificationState();
    final serviceId = current.serviceId;
    if (serviceId == null || serviceId.isEmpty) return;

    final nextTicketState = (current.ticketSearchStates[groupId] ?? const TicketSearchState())
        .copyWith(
          query: query,
          isLoading: true,
          failure: null,
          clearFailure: true,
        );

    state = AsyncData(
      current.copyWith(
        ticketSearchStates: {
          ...current.ticketSearchStates,
          groupId: nextTicketState,
        },
      ),
    );

    try {
      final result = await _repository.searchServiceTickets(
        serviceId: serviceId,
        query: query,
        page: page,
        size: 10,
      );

      final updated = current.copyWith(
        ticketSearchStates: {
          ...current.ticketSearchStates,
          groupId: TicketSearchState(
            items: result.items,
            page: result.page,
            query: query,
            isLoading: false,
          ),
        },
      );
      state = AsyncData(updated);
    } on AppFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          ticketSearchStates: {
            ...current.ticketSearchStates,
            groupId: (current.ticketSearchStates[groupId] ?? const TicketSearchState())
                .copyWith(
                  isLoading: false,
                  failure: failure,
                ),
          },
        ),
      );
    }
  }

  void selectTicket({required String groupId, required String ticketId}) {
    final current = state.value ?? NewVerificationState();
    final nextSelections = {...current.selections};
    final group = current.preview?.ticketSelectionGroups.firstWhere(
      (item) => item.id == groupId,
      orElse: () => const TicketSelectionGroup(
        id: '',
        macroActivityId: '',
        label: '',
        cardinality: Cardinality.unknown,
      ),
    );

    final currentSelection = nextSelections[groupId] ?? <String>{};
    if (group?.isSingle == true) {
      nextSelections[groupId] = {ticketId};
    } else {
      final updated = {...currentSelection};
      if (updated.contains(ticketId)) {
        updated.remove(ticketId);
      } else {
        updated.add(ticketId);
      }
      if (updated.isEmpty) {
        nextSelections.remove(groupId);
      } else {
        nextSelections[groupId] = updated;
      }
    }
    state = AsyncData(current.copyWith(selections: nextSelections));
  }

  void removeTicket({required String groupId, required String ticketId}) {
    final current = state.value ?? NewVerificationState();
    final nextSelections = {...current.selections};
    final currentSelection = nextSelections[groupId] ?? <String>{};
    if (!currentSelection.contains(ticketId)) return;

    final updated = {...currentSelection}..remove(ticketId);
    if (updated.isEmpty) {
      nextSelections.remove(groupId);
    } else {
      nextSelections[groupId] = updated;
    }
    state = AsyncData(current.copyWith(selections: nextSelections));
  }

  void clearPreview() {
    final current = state.value ?? NewVerificationState();
    state = AsyncData(
      current.copyWith(
        preview: null,
        previewFailure: null,
        ticketSearchStates: const {},
        selections: const {},
      ),
    );
  }

  Future<void> startVerification({String? note}) async {
    final current = state.value ?? NewVerificationState();
    final preview = current.preview;
    if (preview == null) return;
    if (!current.canStart) return;

    state = AsyncData(current.copyWith(isStarting: true));

    try {
      await _repository.startVerification(
        StartVerificationRequest(
          serviceId: preview.serviceId,
          serviceRevision: preview.serviceRevision,
          processVersionId: preview.processVersionId,
          scope: preview.scope,
          macroActivityId: preview.macroActivityId,
          note: note,
          ticketSelections: current.buildTicketSelections(),
        ),
      );
      state = AsyncData(current.copyWith(isStarting: false));
    } on ConflictFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          isStarting: false,
          preview: null,
          previewFailure: failure,
          selections: const {},
          ticketSearchStates: const {},
        ),
      );
    } on AppFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          isStarting: false,
          previewFailure: failure,
        ),
      );
    }
  }
}

final newVerificationViewModelProvider =
    AsyncNotifierProvider<NewVerificationViewModel, NewVerificationState>(
  NewVerificationViewModel.new,
);
