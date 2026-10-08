import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/verification_repository.dart';
import '../data/verification_repository_impl.dart';
import '../data/verification_result_location_resolver.dart';
import '../data/verification_result_location_resolver_provider.dart';
import '../model/verification_history_models.dart';
import '../../services/model/service_models.dart' as service_models;
import '../model/verification_result_models.dart';

const verificationResultsPageSize = 20;
const _unchanged = Object();

class VerificationResultsState {
  const VerificationResultsState({
    required this.run,
    required this.items,
    this.page,
    this.selectedResultId,
    this.isChangingPage = false,
    this.resultsFailure,
    this.locationContext = const {},
  });

  final VerificationRun run;
  final List<VerificationResult> items;
  final service_models.PageInfo? page;
  final String? selectedResultId;
  final bool isChangingPage;
  final AppFailure? resultsFailure;
  final Map<String, VerificationResultLocationContext> locationContext;

  bool get hasResultsPage => page != null;

  VerificationResult? get selectedResult {
    final id = selectedResultId;
    if (id == null) return null;
    for (final result in items) {
      if (result.id == id) return result;
    }
    return null;
  }

  VerificationResultsState copyWith({
    VerificationRun? run,
    List<VerificationResult>? items,
    Object? page = _unchanged,
    Object? selectedResultId = _unchanged,
    bool? isChangingPage,
    Object? resultsFailure = _unchanged,
    Object? locationContext = _unchanged,
  }) {
    return VerificationResultsState(
      run: run ?? this.run,
      items: items ?? this.items,
      page: identical(page, _unchanged)
          ? this.page
          : page as service_models.PageInfo?,
      selectedResultId: identical(selectedResultId, _unchanged)
          ? this.selectedResultId
          : selectedResultId as String?,
      isChangingPage: isChangingPage ?? this.isChangingPage,
      resultsFailure: identical(resultsFailure, _unchanged)
          ? this.resultsFailure
          : resultsFailure as AppFailure?,
      locationContext: identical(locationContext, _unchanged)
          ? this.locationContext
          : Map.unmodifiable(
              locationContext as Map<String, VerificationResultLocationContext>,
            ),
    );
  }
}

class VerificationResultsViewModel
    extends AsyncNotifier<VerificationResultsState> {
  VerificationResultsViewModel(this.runId);

  final String runId;
  int _requestVersion = 0;
  int _locationContextVersion = 0;
  int _requestedPage = 0;
  bool _requestInProgress = false;

  VerificationRepository get _repository =>
      ref.read(verificationRepositoryProvider);

  @override
  Future<VerificationResultsState> build() async {
    // Keep an auto-dispose provider alive before the first async gap.
    // Otherwise the provider can be disposed while build() is awaiting the
    // repository, and later notifier actions may run against a new instance.
    final buildKeepAlive = ref.keepAlive();
    _locationContextVersion = 0;
    _requestInProgress = true;
    try {
      final run = await _repository.getVerification(runId);
      if (!ref.mounted) return _stateForRun(run);

      if (run.status != VerificationRunStatus.completed) {
        return _stateForRun(run);
      }

      try {
        final results = await _repository.listResults(
          runId: runId,
          page: _requestedPage,
          size: verificationResultsPageSize,
        );
        final screenState = VerificationResultsState(
          run: run,
          items: results.items,
          page: results.page,
        );
        unawaited(_loadLocationContext(screenState.run, screenState.items));
        return screenState;
      } catch (error) {
        return VerificationResultsState(
          run: run,
          items: const [],
          page: const service_models.PageInfo(
            page: 0,
            size: verificationResultsPageSize,
            totalElements: 0,
            totalPages: 0,
          ),
          resultsFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudieron cargar los resultados.',
          ),
        );
      }
    } finally {
      _requestInProgress = false;
      buildKeepAlive.close();
    }
  }

  void toggleResult(String resultId) {
    final current = state.value;
    if (current == null) return;
    final nextId = current.selectedResultId == resultId ? null : resultId;
    state = AsyncData(current.copyWith(selectedResultId: nextId));
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    final pageInfo = current?.page;
    if (current == null ||
        pageInfo == null ||
        current.isChangingPage ||
        page < 0 ||
        page >= pageInfo.totalPages ||
        page == pageInfo.page) {
      return;
    }

    _requestedPage = page;
    final requestVersion = ++_requestVersion;
    _requestInProgress = true;
    state = AsyncData(
      current.copyWith(
        isChangingPage: true,
        selectedResultId: null,
        resultsFailure: null,
      ),
    );

    try {
      final results = await _repository.listResults(
        runId: runId,
        page: page,
        size: verificationResultsPageSize,
      );
      if (!ref.mounted || requestVersion != _requestVersion) return;

      _requestedPage = results.page.page;

      final currentState = state.value ?? current;
      final nextState = currentState.copyWith(
        items: results.items,
        page: results.page,
        selectedResultId: null,
        isChangingPage: false,
        resultsFailure: null,
        locationContext: const <String, VerificationResultLocationContext>{},
      );
      state = AsyncData(nextState);
      unawaited(_loadLocationContext(nextState.run, nextState.items));
    } catch (error) {
      if (!ref.mounted || requestVersion != _requestVersion) return;
      state = AsyncData(
        current.copyWith(
          isChangingPage: false,
          resultsFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudo cargar la página solicitada.',
          ),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> retry() async {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    if (_requestInProgress) return;

    final requestVersion = ++_requestVersion;
    _requestInProgress = true;
    final targetPage = _requestedPage;

    try {
      final run = await _repository.getVerification(runId);
      if (!ref.mounted || requestVersion != _requestVersion) return;

      if (run.status != VerificationRunStatus.completed) {
        state = AsyncData(
          VerificationResultsState(run: run, items: const []),
        );
        return;
      }

      final results = await _repository.listResults(
        runId: runId,
        page: targetPage,
        size: verificationResultsPageSize,
      );
      if (!ref.mounted || requestVersion != _requestVersion) return;

      _requestedPage = results.page.page;
      final nextState = VerificationResultsState(
        run: run,
        items: results.items,
        page: results.page,
      );
      state = AsyncData(nextState);
      unawaited(_loadLocationContext(nextState.run, nextState.items));
    } catch (error) {
      if (!ref.mounted || requestVersion != _requestVersion) return;

      state = AsyncData(
        current.copyWith(
          run: current.run,
          isChangingPage: false,
          resultsFailure: safeAppFailure(
            error,
            fallbackMessage: 'No se pudieron actualizar los resultados.',
          ),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> _loadLocationContext(
    VerificationRun run,
    List<VerificationResult> results,
  ) async {
    final requestVersion = ++_locationContextVersion;
    final resolver = ref.read(verificationResultLocationResolverProvider);
    final resolved = await resolver.resolve(run: run, results: results);
    if (!ref.mounted || requestVersion != _locationContextVersion) return;
    final current = state.value;
    if (current == null || current.run.id != run.id) return;
    state = AsyncData(current.copyWith(locationContext: resolved));
  }

  VerificationResultsState _stateForRun(VerificationRun run) {
    return VerificationResultsState(run: run, items: const []);
  }
}

final verificationResultsViewModelProvider =
    AsyncNotifierProvider.family<
      VerificationResultsViewModel,
      VerificationResultsState,
      String
    >(VerificationResultsViewModel.new, isAutoDispose: true);
