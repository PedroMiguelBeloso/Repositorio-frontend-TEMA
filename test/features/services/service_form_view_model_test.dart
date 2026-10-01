import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/services/viewmodel/service_form_view_model.dart';

final _publishedVersion = ProcessVersionOption(
  id: 'version-1',
  processId: 'process-1',
  processName: 'Start Up',
  officialVersion: '2.0',
  versionDate: DateTime(2026, 9, 1),
  status: ProcessStatus.published,
);

final _service = Service(
  id: 'service-1',
  name: 'Servicio Norte',
  client: 'Cliente Norte',
  serviceType: ServiceType.supportAriba,
  status: ServiceStatus.active,
  revision: 4,
  processes: const [
    ServiceProcess(
      processVersionId: 'version-1',
      processId: 'process-1',
      processName: 'Start Up',
      officialVersion: '2.0',
      m2Enabled: true,
    ),
  ],
  sources: const ServiceSource(
    driveFolderId: 'drive-1',
    driveFolderName: '/Servicios/Norte',
    redmineProjectId: 'redmine-1',
    redmineProjectName: 'Cliente Norte',
  ),
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

void main() {
  test('create saves the selected source IDs and omits revision', () async {
    final repository = _FakeServiceRepository();
    final container = ProviderContainer(
      overrides: [
        serviceRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final provider = serviceFormViewModelProvider(null);

    await container.read(provider.future);

    final notifier = container.read(provider.notifier);

    notifier.updateName('Servicio nuevo');
    notifier.updateClient('Cliente nuevo');
    notifier.updateServiceType(ServiceType.projectErp);
    notifier.assignProcessVersion(_publishedVersion);

    notifier.selectDriveFolder(
      const DriveFolderOption(
        id: 'drive-9',
        name: 'Raíz',
        path: '/Servicios/Nuevo',
      ),
    );

    notifier.selectRedmineProject(
      const RedmineProjectOption(
        id: 'redmine-9',
        name: 'Nuevo',
      ),
    );

    await notifier.save();

    expect(repository.createdInput, isNotNull);
    expect(repository.createdInput!.revision, isNull);
    expect(repository.createdInput!.processVersionIds, ['version-1']);
    expect(repository.createdInput!.driveFolderId, 'drive-9');
    expect(repository.createdInput!.redmineProjectId, 'redmine-9');

    expect(
      container.read(provider).value!.savedService,
      isNotNull,
    );
  });

  test(
    'edit sends revision and preserves values not changed by the user',
    () async {
      final repository = _FakeServiceRepository(
        service: _service,
      );

      final container = ProviderContainer(
        overrides: [
          serviceRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final provider = serviceFormViewModelProvider('service-1');

      await container.read(provider.future);

      final notifier = container.read(provider.notifier);

      notifier.updateName('Servicio Norte actualizado');

      await notifier.save();

      expect(repository.updatedId, 'service-1');
      expect(repository.updatedInput!.revision, 4);
      expect(repository.updatedInput!.client, 'Cliente Norte');
      expect(repository.updatedInput!.processVersionIds, ['version-1']);
      expect(repository.updatedInput!.driveFolderId, 'drive-1');
      expect(repository.updatedInput!.redmineProjectId, 'redmine-1');

      expect(
        container.read(provider).value!.savedService,
        isNotNull,
      );
    },
  );

  test(
    '409 during edit remains a conflict and is not reported as saved',
    () async {
      final repository = _FakeServiceRepository(
        service: _service,
        updateFailure: const ConflictFailure(
          'El servicio fue modificado por otra persona.',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          serviceRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final provider = serviceFormViewModelProvider('service-1');

      await container.read(provider.future);

      await container.read(provider.notifier).save();

      final state = container.read(provider).value!;

      expect(state.isSaving, isFalse);
      expect(state.actionFailure, isA<ConflictFailure>());
      expect(state.savedService, isNull);
    },
  );
}

class _FakeServiceRepository implements ServiceRepository {
  _FakeServiceRepository({
    this.service,
    this.updateFailure,
  });

  final Service? service;
  final AppFailure? updateFailure;

  ServiceInput? createdInput;
  ServiceInput? updatedInput;
  String? updatedId;

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) async {
    return PagedResult(
      items: service == null ? const [] : [service!],
      page: PageInfo(
        page: page,
        size: size,
        totalElements: service == null ? 0 : 1,
        totalPages: service == null ? 0 : 1,
      ),
    );
  }

  @override
  Future<Service> getService(String id) async {
    return service ?? _createdService;
  }

  @override
  Future<Service> createService(ServiceInput input) async {
    createdInput = input;
    return _createdService;
  }

  @override
  Future<Service> updateService(
    String id,
    ServiceInput input,
  ) async {
    if (updateFailure != null) {
      throw updateFailure!;
    }

    updatedId = id;
    updatedInput = input;

    return _createdService;
  }

  @override
  Future<List<AssignableProcessGroup>> getAssignableProcessVersions() async {
    return [
      AssignableProcessGroup(
        process: const ProcessDefinitionSummary(
          id: 'process-1',
          code: ProcessCode.startUp,
          name: 'Start Up',
          m2Enabled: true,
        ),
        publishedVersions: [_publishedVersion],
      ),
    ];
  }

  @override
  Future<PagedResult<DriveFolderOption>> getDriveFolders({
    String query = '',
    required int page,
    required int size,
  }) async {
    return PagedResult(
      items: const [
        DriveFolderOption(
          id: 'drive-1',
          name: 'Raíz',
          path: '/Servicios/Norte',
        ),
      ],
      page: PageInfo(
        page: page,
        size: size,
        totalElements: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<PagedResult<RedmineProjectOption>> getRedmineProjects({
    required int page,
    required int size,
  }) async {
    return PagedResult(
      items: const [
        RedmineProjectOption(
          id: 'redmine-1',
          name: 'Cliente Norte',
        ),
      ],
      page: PageInfo(
        page: page,
        size: size,
        totalElements: 1,
        totalPages: 1,
      ),
    );
  }

  static final _createdService = Service(
    id: 'created-service',
    name: 'Servicio creado',
    client: 'Cliente',
    serviceType: ServiceType.projectErp,
    status: ServiceStatus.active,
    revision: 1,
    processes: const [_serviceProcess],
    sources: const ServiceSource(
      driveFolderId: 'drive-9',
      driveFolderName: '/Servicios/Nuevo',
      redmineProjectId: 'redmine-9',
      redmineProjectName: 'Nuevo',
    ),
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  static const _serviceProcess = ServiceProcess(
    processVersionId: 'version-1',
    processId: 'process-1',
    processName: 'Start Up',
    officialVersion: '2.0',
    m2Enabled: true,
  );
}