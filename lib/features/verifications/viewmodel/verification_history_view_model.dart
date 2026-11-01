import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../services/model/service_models.dart';
import '../data/verification_repository.dart';
import '../data/verification_repository_impl.dart';
import '../model/verification_history_models.dart';

const verificationHistoryPageSize = 20;
const _serviceLookupPageSize = 100;
const _unchanged = Object();

final verificationHistoryPollingIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

class VerificationHistoryState {
  const VerificationHistoryState({
    required this.items,
    required this.page,
    required this.services,
    this.serviceId,
    this.isRefreshing = false,
    this.refreshFailure,
  });

  final List<VerificationRunSummary> items;
  final PageInfo page;
  final List<Service> services;
  final String? serviceId;
  final bool isRefreshing;
  final AppFailure? refreshFailure;

  Service? serviceFor(VerificationRunSummary run) {
    for (final service in services) {
      if (service.id == run.serviceId) return service;
    }
    return null;
  }

  ServiceProcess? processFor(VerificationRunSummary run) {
    return serviceFor(run)?.processForVersion(run.processVersionId);
  }

  VerificationHistoryState copyWith({
    List<VerificationRunSummary>? items,
    PageInfo? page,
    List<Service>? services,
    Object? serviceId = _unchanged,
    bool? isRefreshing,
    Object? refreshFailure = _unchanged,
  }) {
    return VerificationHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      services: services ?? this.services,
      serviceId: identical(serviceId, _unchanged)
          ? this.serviceId
          : serviceId as String?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailure: identical(refreshFailure, _unchanged)
          ? this.refreshFailure
          : refreshFailure as AppFailure?,
    );
  }
}

class VerificationHistoryViewModel
    extends AsyncNotifier<VerificationHistoryState> {
  int _requestVersion = 0;
  int _requestedPage = 0;
  String? _requestedServiceId;
  Timer? _pollTimer;

  VerificationRepository get _repository =>
      ref.read(verificationRepositoryProvider);

  @override
  Future<VerificationHistoryState> build() async {
    ref.onDispose(() => _pollTimer?.cancel());
    _requestedPage = 0;
    _requestedServiceId = null;
    final snapshot = await _loadSnapshot(
      page: _requestedPage,
      serviceId: _requestedServiceId,
    );
    _syncPolling(snapshot);
    return snapshot;
  }

  Future<void> selectService(String? serviceId) async {
    final current = state.value;
    if (current == null) return;
    if (current.serviceId == serviceId) return;

    _requestedPage = 0;
    _requestedServiceId = serviceId;
    final requestVersion = ++_requestVersion;
    state = const AsyncLoading();

    try {
      final result = await _repository.listRuns(
        page: _requestedPage,
        size: verificationHistoryPageSize,
        serviceId: _requestedServiceId,
      );
      if (!ref.mounted || requestVersion != _requestVersion) return;

      state = AsyncData(
        current.copyWith(
          items: result.items,
          page: result.page,
          serviceId: _requestedServiceId,
          refreshFailure: null,
        ),
      );
      _syncPolling(state.requireValue);
    } catch (error, stackTrace) {
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current == null) return;
    if (page < 0 ||
        page >= current.page.totalPages ||
        page == current.page.page) {
      return;
    }

    _requestedPage = page;
    _requestedServiceId = current.serviceId;
    final requestVersion = ++_requestVersion;
    state = const AsyncLoading();

    try {
      final result = await _repository.listRuns(
        page: _requestedPage,
        size: verificationHistoryPageSize,
        serviceId: _requestedServiceId,
      );
      if (!ref.mounted || requestVersion != _requestVersion) return;

      state = AsyncData(
        current.copyWith(
          items: result.items,
          page: result.page,
          refreshFailure: null,
        ),
      );
      _syncPolling(state.requireValue);
    } catch (error, stackTrace) {
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null || current.isRefreshing) return;

    _requestedPage = current.page.page;
    _requestedServiceId = current.serviceId;
    final requestVersion = ++_requestVersion;
    state = AsyncData(
      current.copyWith(isRefreshing: true, refreshFailure: null),
    );

    try {
      final servicesFuture = _loadAllServices().catchError(
        (_) => current.services,
      );
      final runsFuture = _repository.listRuns(
        page: _requestedPage,
        size: verificationHistoryPageSize,
        serviceId: _requestedServiceId,
      );
      final services = await servicesFuture;
      final result = await runsFuture;

      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncData(
        current.copyWith(
          items: result.items,
          page: result.page,
          services: services,
          isRefreshing: false,
          refreshFailure: null,
        ),
      );
      _syncPolling(state.requireValue);
    } catch (error) {
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          refreshFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo actualizar el historial.',
          ),
        ),
      );
    }
  }

  Future<void> retry() async {
    final requestVersion = ++_requestVersion;
    final page = _requestedPage;
    final serviceId = _requestedServiceId;
    state = const AsyncLoading();

    try {
      final snapshot = await _loadSnapshot(page: page, serviceId: serviceId);
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncData(snapshot);
      _syncPolling(snapshot);
    } catch (error, stackTrace) {
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<VerificationHistoryState> _loadSnapshot({
    required int page,
    required String? serviceId,
  }) async {
    _requestedPage = page;
    _requestedServiceId = serviceId;

    final servicesFuture = _loadAllServices().catchError((_) => <Service>[]);
    final runsFuture = _repository.listRuns(
      page: page,
      size: verificationHistoryPageSize,
      serviceId: serviceId,
    );
    final services = await servicesFuture;
    final result = await runsFuture;

    return VerificationHistoryState(
      items: result.items,
      page: result.page,
      services: services,
      serviceId: serviceId,
    );
  }

  Future<List<Service>> _loadAllServices() async {
    var page = 0;
    final services = <Service>[];

    while (true) {
      final result = await _repository.listServices(
        page: page,
        size: _serviceLookupPageSize,
      );
      services.addAll(result.items);
      if (!result.page.hasNext) return services;
      page = result.page.page + 1;
    }
  }

  void _syncPolling(VerificationHistoryState snapshot) {
    final hasActiveRuns = snapshot.items.any((run) => !run.isTerminal);
    if (!hasActiveRuns || !ref.mounted) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(
      ref.read(verificationHistoryPollingIntervalProvider),
      (_) => refresh(),
    );
  }
}

final verificationHistoryViewModelProvider =
    AsyncNotifierProvider<
      VerificationHistoryViewModel,
      VerificationHistoryState
    >(VerificationHistoryViewModel.new);
