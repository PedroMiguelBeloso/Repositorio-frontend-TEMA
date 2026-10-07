import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'verification_repository.dart';
import 'verification_repository_impl.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepositoryImpl(ref.watch(apiClientProvider));
});
