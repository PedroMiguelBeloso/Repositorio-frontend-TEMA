import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/dto/verification_history_dtos.dart';

void main() {
  test('maps historical names from the backend without current service lookup', () {
    final dto = VerificationRunDto.fromJson({
      'id': 'run-1',
      'serviceId': 'service-1',
      'processVersionId': 'version-1',
      'scope': 'MACRO_ACTIVITY',
      'status': 'COMPLETED',
      'progress': {'total': 1, 'processed': 1, 'reviewRequired': 0},
      'startedAt': '2026-10-26T12:00:00Z',
      'serviceNameSnapshot': 'Servicio histórico',
      'processNameSnapshot': 'Start Up',
      'processOfficialVersionSnapshot': '2.0',
      'macroActivityNameSnapshot': 'Organización interna',
    });
    expect(dto.toModel().serviceNameSnapshot, 'Servicio histórico');
    expect(dto.toModel().processNameSnapshot, 'Start Up');
    expect(dto.toRun().macroActivityNameSnapshot, 'Organización interna');
  });
}
