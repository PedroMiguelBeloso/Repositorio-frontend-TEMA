import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';

void main() {
  test('maps all API run states to the required Spanish labels', () {
    expect(VerificationRunStatus.fromApi('QUEUED').label, 'En espera');
    expect(VerificationRunStatus.fromApi('RUNNING').label, 'En curso');
    expect(VerificationRunStatus.fromApi('COMPLETED').label, 'Finalizada');
    expect(VerificationRunStatus.fromApi('FAILED').label, 'Fallida');
  });

  test('maps the progress values and accepts an unknown total', () {
    final progress = RunProgress.fromValues(total: 12, processed: 5);
    expect(progress.fractionLabel, '5 de 12');
    expect(progress.fraction, closeTo(5 / 12, 0.0001));
    expect(
      RunProgress.fromValues(total: 0, processed: 0).fractionLabel,
      '0 de 0',
    );
    expect(
      () => RunProgress.fromValues(total: -1, processed: 0),
      throwsA(isA<FormatException>()),
    );
  });

  test('maps unknown scope defensively', () {
    expect(
      VerificationScope.fromApi('SOMETHING_NEW'),
      VerificationScope.unknown,
    );
  });
}
