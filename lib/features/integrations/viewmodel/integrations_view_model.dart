import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/integrations_repository_provider.dart';
import '../model/integration_source.dart';
import '../model/integration_status.dart';

class IntegrationsViewState {
  const IntegrationsViewState({
    required this.statuses,
    this.isTesting = false,
    this.actionFailure,
  });

  final List<IntegrationStatus> statuses;
  final bool isTesting;
  final AppFailure? actionFailure;

  IntegrationStatus? statusFor(IntegrationSource source) {
    for (final status in statuses) {
      if (status.source == source) return status;
    }
    return null;
  }

  IntegrationsViewState copyWith({
    List<IntegrationStatus>? statuses,
    bool? isTesting,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => IntegrationsViewState(
    statuses: statuses ?? this.statuses,
    isTesting: isTesting ?? this.isTesting,
    actionFailure: clearActionFailure
        ? null
        : actionFailure ?? this.actionFailure,
  );
}

class IntegrationsViewModel extends AsyncNotifier<IntegrationsViewState> {
  bool _isTesting = false;

  @override
  Future<IntegrationsViewState> build() async {
    final statuses = await ref
        .watch(integrationsRepositoryProvider)
        .testIntegrations();
    return IntegrationsViewState(statuses: statuses);
  }

  Future<void> retry() async {
    state = const AsyncLoading<IntegrationsViewState>();
    state = await AsyncValue.guard(
      () => ref
          .read(integrationsRepositoryProvider)
          .testIntegrations()
          .then((statuses) => IntegrationsViewState(statuses: statuses)),
    );
  }

  Future<void> testIntegrations() async {
    final current = state.value;
    if (current == null || _isTesting) return;

    _isTesting = true;
    state = AsyncData(
      current.copyWith(isTesting: true, clearActionFailure: true),
    );

    try {
      final statuses = await ref
          .read(integrationsRepositoryProvider)
          .testIntegrations();
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          statuses: statuses,
          isTesting: false,
          clearActionFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isTesting: false, actionFailure: failure),
      );
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isTesting: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo probar las integraciones. Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      _isTesting = false;
    }
  }
}

final integrationsViewModelProvider =
    AsyncNotifierProvider<IntegrationsViewModel, IntegrationsViewState>(
      IntegrationsViewModel.new,
      isAutoDispose: true,
      retry: (retryCount, error) => null,
    );
