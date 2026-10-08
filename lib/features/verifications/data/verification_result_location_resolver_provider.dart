import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../processes/data/process_structure_repository_provider.dart';
import '../../services/data/service_repository_provider.dart';
import 'verification_result_location_resolver.dart';

final verificationResultLocationResolverProvider =
    Provider<VerificationResultLocationResolver>((ref) {
  return VerificationResultLocationResolverImpl(
    ref.watch(serviceRepositoryProvider),
    ref.watch(processStructureRepositoryProvider),
  );
});
