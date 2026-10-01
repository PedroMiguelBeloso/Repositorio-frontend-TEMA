import '../model/service_models.dart';

abstract interface class ServiceRepository {
  Future<PagedResult<Service>> listServices({required int page, required int size});
  Future<Service> getService(String id);
  Future<Service> createService(ServiceInput input);
  Future<Service> updateService(String id, ServiceInput input);

  Future<List<AssignableProcessGroup>> getAssignableProcessVersions();

  Future<PagedResult<DriveFolderOption>> getDriveFolders({
    String query,
    required int page,
    required int size,
  });

  Future<PagedResult<RedmineProjectOption>> getRedmineProjects({
    required int page,
    required int size,
  });
}
