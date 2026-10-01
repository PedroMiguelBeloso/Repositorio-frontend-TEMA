import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/data/dto/service_dtos.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';

void main() {
  test('all service types expose Spanish labels and API enums', () {
    expect(ServiceType.supportAriba.label, 'Soporte Ariba');
    expect(ServiceType.supportAriba.apiValue, 'SUPPORT_ARIBA');
    expect(ServiceType.supportErp.label, 'Soporte ERP');
    expect(ServiceType.supportErp.apiValue, 'SUPPORT_ERP');
    expect(ServiceType.softwareFactory.label, 'Software Factory');
    expect(ServiceType.softwareFactory.apiValue, 'SOFTWARE_FACTORY');
    expect(ServiceType.projectSapAriba.label, 'Proyecto SAP Ariba');
    expect(ServiceType.projectSapAriba.apiValue, 'PROJECT_SAP_ARIBA');
    expect(ServiceType.projectErp.label, 'Proyecto ERP');
    expect(ServiceType.projectErp.apiValue, 'PROJECT_ERP');
  });

  test('create payload omits revision and source values are IDs', () {
    const input = ServiceInput(
      name: 'Servicio',
      client: 'Cliente',
      serviceType: ServiceType.supportAriba,
      status: ServiceStatus.active,
      processVersionIds: ['version-1'],
      revision: 4,
      driveFolderId: 'drive-1',
      redmineProjectId: 'redmine-1',
    );

    final dto = ServiceWriteRequestDto.fromModel(input);
    final json = dto.toJson(includeRevision: false);

    expect(json['serviceType'], 'SUPPORT_ARIBA');
    expect(json['processVersionIds'], ['version-1']);
    expect(json['driveFolderId'], 'drive-1');
    expect(json['redmineProjectId'], 'redmine-1');
    expect(json.containsKey('revision'), isFalse);
    expect(json.containsValue('Servicio'), isTrue);
    expect(json.containsValue('/Servicios/Cliente'), isFalse);
  });

  test('update payload includes the current revision', () {
    const input = ServiceInput(
      name: 'Servicio',
      client: 'Cliente',
      serviceType: ServiceType.projectErp,
      status: ServiceStatus.inactive,
      processVersionIds: ['version-1'],
      revision: 8,
    );

    final json = ServiceWriteRequestDto.fromModel(input).toJson(
      includeRevision: true,
    );

    expect(json['revision'], 8);
  });
}
