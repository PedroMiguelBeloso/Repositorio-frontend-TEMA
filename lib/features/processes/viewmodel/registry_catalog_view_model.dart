import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/registry_repository_impl.dart';
import '../model/process_models.dart';
import '../model/registry_definition.dart';

class RegistryCatalogViewModel extends AsyncNotifier<RegistryPage> {
  String query = '';
  int page = 0;

  @override
  Future<RegistryPage> build() => _load();

  Future<RegistryPage> _load() =>
      ref.read(registryRepositoryProvider).search(query: query, page: page);

  Future<void> search(String value) async {
    query = value.trim();
    page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> goToPage(int value) async {
    if (value < 0) return;
    page = value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<RegistryDefinition> create({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) async {
    final created = await ref
        .read(registryRepositoryProvider)
        .create(
          canonicalName: canonicalName,
          evidenceType: evidenceType,
          officialNomenclature: officialNomenclature,
        );
    await refresh();
    return created;
  }
}

final registryCatalogViewModelProvider =
    AsyncNotifierProvider<RegistryCatalogViewModel, RegistryPage>(
      RegistryCatalogViewModel.new,
    );
