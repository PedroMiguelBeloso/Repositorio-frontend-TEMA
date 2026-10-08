import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/verification_repository.dart';
import '../data/verification_repository_impl.dart';
import '../model/verification_history_models.dart';

final verificationRunPollingIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

const _unchanged = Object();

class VerificationRunDetailState {
  const VerificationRunDetailState({
    required this.run,
    this.isRefreshing = false,
    this.refreshFailure,
  });

  final VerificationRun run;
  final bool isRefreshing;
  final AppFailure? refreshFailure;

  VerificationRunDetailState copyWith({
    VerificationRun? run,
    bool? isRefreshing,
    Object? refreshFailure = _unchanged,
  }) {
    return VerificationRunDetailState(
      run: run ?? this.run,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailure: identical(refreshFailure, _unchanged)
          ? this.refreshFailure
          : refreshFailure as AppFailure?,
    );
  }
}

class VerificationRunViewModel
    extends AsyncNotifier<VerificationRunDetailState> {
  VerificationRunViewModel(this.runId);

  final String runId;
  Timer? _timer;
  bool _requestInProgress = false;

  VerificationRepository get _repository =>
      ref.read(verificationRepositoryProvider);

  @override
  Future<VerificationRunDetailState> build() async {
    ref.onDispose(_stopPolling);
    _requestInProgress = true;
    try {
      final run = await _repository.getVerification(runId);
      if (ref.mounted && run.isPollable) _startPolling();
      return VerificationRunDetailState(run: run);
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> refresh() async {
    final current = state.value;
    if (!ref.mounted || current == null || _requestInProgress) return;

    _requestInProgress = true;
    state = AsyncData(
      current.copyWith(isRefreshing: true, refreshFailure: null),
    );
    try {
      final run = await _repository.getVerification(runId);
      if (!ref.mounted) return;

      state = AsyncData(VerificationRunDetailState(run: run));
      if (run.isPollable) {
        _startPolling();
      } else {
        _stopPolling();
      }
    } catch (error) {
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isRefreshing: false,
          refreshFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo actualizar la ejecución.',
          ),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> retry() async {
    if (state.value == null) {
      ref.invalidateSelf();
      return;
    }
    await refresh();
  }

  void _startPolling() {
    if (_timer != null || !ref.mounted) return;
    final interval = ref.read(verificationRunPollingIntervalProvider);
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
}

final verificationRunViewModelProvider =
    AsyncNotifierProvider.family<
      VerificationRunViewModel,
      VerificationRunDetailState,
      String
    >(VerificationRunViewModel.new, isAutoDispose: true);
