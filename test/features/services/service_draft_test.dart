import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_draft.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';

ProcessVersionOption _version({
  required String id,
  required String processId,
  required String version,
  ProcessStatus status = ProcessStatus.published,
}) {
  return ProcessVersionOption(
    id: id,
    processId: processId,
    processName: 'Start Up',
    officialVersion: version,
    versionDate: DateTime(2026, 9, 1),
    status: status,
  );
}

void main() {
  group('ServiceDraft', () {
    test('assignProcessVersion replaces the previous version of the same process', () {
      final first = _version(
        id: 'v1',
        processId: 'p1',
        version: '1.0',
      );
      final second = _version(
        id: 'v2',
        processId: 'p1',
        version: '2.0',
      );

      final draft = ServiceDraft.empty().assignProcessVersion(first);
      final updated = draft.assignProcessVersion(second);

      expect(updated.processVersionIds, ['v2']);
      expect(updated.selectedProcessVersions.single.officialVersion, '2.0');
    });

    test('does not allow an unpublished process version', () {
      final draft = ServiceDraft.empty();
      final unpublished = _version(
        id: 'draft-1',
        processId: 'p1',
        version: '3.0',
        status: ProcessStatus.draft,
      );

      expect(
        () => draft.assignProcessVersion(unpublished),
        throwsArgumentError,
      );
    });

    test('create input trims fields and omits revision', () {
      final draft = ServiceDraft.empty()
          .copyWith(
            name: '  Servicio Norte  ',
            client: '  Cliente Norte  ',
            serviceType: ServiceType.supportErp,
          )
          .assignProcessVersion(
            _version(id: 'v1', processId: 'p1', version: '1.0'),
          );

      final input = draft.toServiceInput(isEditing: false);

      expect(input.name, 'Servicio Norte');
      expect(input.client, 'Cliente Norte');
      expect(input.serviceType, ServiceType.supportErp);
      expect(input.revision, isNull);
    });

    test(
      'create input allows no process assignment when the contract does not require one',
      () {
        final draft = ServiceDraft.empty().copyWith(
          name: 'Servicio',
          client: 'Cliente',
          serviceType: ServiceType.supportAriba,
        );

        final input = draft.toServiceInput(isEditing: false);

        expect(input.processVersionIds, isEmpty);
        expect(input.revision, isNull);
      },
    );

    test('edit input keeps revision and selected source IDs', () {
      final folder = const DriveFolderOption(
        id: 'drive-1',
        name: 'Soporte',
        path: '/Servicios/Soporte',
      );
      final project = const RedmineProjectOption(
        id: 'redmine-1',
        name: 'Soporte Norte',
      );
      final draft = ServiceDraft.empty()
          .copyWith(
            name: 'Servicio',
            client: 'Cliente',
            serviceType: ServiceType.softwareFactory,
            revision: 7,
          )
          .assignProcessVersion(
            _version(id: 'v1', processId: 'p1', version: '2.0'),
          )
          .selectDriveFolder(folder)
          .selectRedmineProject(project);

      final input = draft.toServiceInput(isEditing: true);

      expect(input.revision, 7);
      expect(input.processVersionIds, ['v1']);
      expect(input.driveFolderId, 'drive-1');
      expect(input.redmineProjectId, 'redmine-1');
    });

    test('edit input without revision is rejected by the model', () {
      final draft = ServiceDraft.empty().copyWith(
        name: 'Servicio',
        client: 'Cliente',
        serviceType: ServiceType.supportAriba,
      ).assignProcessVersion(
        _version(id: 'v1', processId: 'p1', version: '1.0'),
      );

      expect(
        () => draft.toServiceInput(isEditing: true),
        throwsStateError,
      );
    });

    test('empty name or client cannot become a command', () {
      final base = ServiceDraft.empty()
          .copyWith(
            serviceType: ServiceType.supportAriba,
            name: '  ',
            client: 'Cliente',
          )
          .assignProcessVersion(
            _version(id: 'v1', processId: 'p1', version: '1.0'),
          );

      expect(() => base.toServiceInput(isEditing: false), throwsArgumentError);
    });
  });
}
