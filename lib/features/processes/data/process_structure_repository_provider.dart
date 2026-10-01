import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'process_structure_repository.dart';
import 'process_structure_repository_impl.dart';

final processStructureRepositoryProvider =
    Provider<ProcessStructureRepository>((ref) {
  return ProcessStructureRepositoryImpl(ref.watch(apiClientProvider));
});
