import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'integrations_repository.dart';
import 'integrations_repository_impl.dart';

final integrationsRepositoryProvider = Provider<IntegrationsRepository>((ref) {
  return IntegrationsRepositoryImpl(ref.watch(apiClientProvider));
});