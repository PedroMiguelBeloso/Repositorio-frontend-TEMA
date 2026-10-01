import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'process_repository.dart';
import 'process_repository_impl.dart';

final processRepositoryProvider = Provider<ProcessRepository>((ref) {
  return ProcessRepositoryImpl(ref.watch(apiClientProvider));
});
