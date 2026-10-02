import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/integrations/data/integration_status_dto.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_source.dart';
import 'package:proyecto_tema_frontend/features/integrations/model/integration_state.dart';

void main() {
  const statuses = <(String, IntegrationState, String)>[
    ('AVAILABLE', IntegrationState.available, 'Disponible'),
    ('AUTH_ERROR', IntegrationState.authError, 'Error de autenticación'),
    (
      'PERMISSION_ERROR',
      IntegrationState.permissionError,
      'Sin permiso para consultar',
    ),
    ('UNAVAILABLE', IntegrationState.unavailable, 'No disponible'),
    ('NOT_CONFIGURED', IntegrationState.notConfigured, 'No configurada'),
  ];

  for (final (apiValue, expectedState, label) in statuses) {
    test('$apiValue maps to $label', () {
      final dto = IntegrationStatusDto.tryFromJson(_json(status: apiValue));

      expect(dto?.state, expectedState);
      expect(dto?.state.label, label);
    });
  }

  test('maps both sources, parses checkedAt, and allows no message', () {
    final drive = IntegrationStatusDto.tryFromJson(_json(source: 'DRIVE'));
    final redmine = IntegrationStatusDto.tryFromJson(
      _json(source: 'REDMINE'),
    );

    expect(drive?.source, IntegrationSource.drive);
    expect(drive?.source.label, 'Google Drive');
    expect(redmine?.source, IntegrationSource.redmine);
    expect(redmine?.source.label, 'Redmine');
    expect(drive?.checkedAt, DateTime.parse('2026-10-01T12:30:00Z'));
    expect(drive?.message, isNull);
  });

  test('ignores an unknown source', () {
    expect(
      IntegrationStatusDto.tryFromJson(_json(source: 'OTHER')),
      isNull,
    );
  });

  test('unknown statuses become a safe AppFailure', () {
    expect(
      () => IntegrationStatusDto.tryFromJson(_json(status: 'UNKNOWN')),
      throwsA(
        isA<UnexpectedFailure>().having(
          (failure) => failure.message,
          'message',
          'La respuesta de integraciones contiene un estado desconocido.',
        ),
      ),
    );
  });
}

Map<String, dynamic> _json({
  String source = 'DRIVE',
  String status = 'AVAILABLE',
}) => {
  'source': source,
  'status': status,
  'checkedAt': '2026-10-01T12:30:00Z',
};