import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/service_repository.dart';
import '../data/service_repository_provider.dart';
import '../model/service_models.dart';

class ServiceListState {
  const ServiceListState({
    required this.items,
    required this.page,
    this.isPaging = false,
    this.pageFailure,
  });

  final List<Service> items;
  final PageInfo page;
  final bool isPaging;
  final AppFailure? pageFailure;

  ServiceListState copyWith({
    List<Service>? items,
    PageInfo? page,
    bool? isPaging,
    AppFailure? pageFailure,
    bool clearPageFailure = false,
  }) {
    return ServiceListState(
      items: items ?? this.items,
      page: page ?? this.page,
      isPaging: isPaging ?? this.isPaging,
      pageFailure:
          clearPageFailure ? null : pageFailure ?? this.pageFailure,
    );
  }
}

class ServiceListViewModel
    extends AsyncNotifier<ServiceListState> {
  static const _pageSize = 20;

  ServiceRepository get _repository =>
      ref.read(serviceRepositoryProvider);

  @override
  Future<ServiceListState> build() => _loadPage(0);

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      state = AsyncData(
        await _loadPage(0),
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        _asFailure(error),
        stackTrace,
      );
    }
  }

  Future<void> nextPage() async {
    final current = state.value;

    if (current == null ||
        current.isPaging ||
        !current.page.hasNext) {
      return;
    }

    await _changePage(
      current.page.page + 1,
    );
  }

  Future<void> previousPage() async {
    final current = state.value;

    if (current == null ||
        current.isPaging ||
        !current.page.hasPrevious) {
      return;
    }

    await _changePage(
      current.page.page - 1,
    );
  }

  Future<void> _changePage(int page) async {
    final current = state.value;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        isPaging: true,
        clearPageFailure: true,
      ),
    );

    try {
      state = AsyncData(
        await _loadPage(page),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isPaging: false,
          pageFailure: _asFailure(error),
        ),
      );
    }
  }

  Future<ServiceListState> _loadPage(
    int page,
  ) async {
    final result = await _repository.listServices(
      page: page,
      size: _pageSize,
    );

    return ServiceListState(
      items: result.items,
      page: result.page,
    );
  }

  AppFailure _asFailure(Object error) {
    if (error is AppFailure) {
      return error;
    }

    return const UnexpectedFailure(
      'No se pudo cargar la lista de servicios.',
    );
  }
}

final serviceListViewModelProvider =
    AsyncNotifierProvider.autoDispose<
        ServiceListViewModel,
        ServiceListState>(
  ServiceListViewModel.new,
);