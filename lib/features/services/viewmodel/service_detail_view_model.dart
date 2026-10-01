import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_repository_provider.dart';
import '../model/service_models.dart';

class ServiceDetailViewModel extends AsyncNotifier<Service> {
  ServiceDetailViewModel(this.serviceId);

  final String serviceId;

  @override
  Future<Service> build() {
    return ref.read(serviceRepositoryProvider).getService(serviceId);
  }

  void refresh() => ref.invalidateSelf();
}

final serviceDetailViewModelProvider =
    AsyncNotifierProvider.family<ServiceDetailViewModel, Service, String>(
  ServiceDetailViewModel.new,
  isAutoDispose: true,
);
