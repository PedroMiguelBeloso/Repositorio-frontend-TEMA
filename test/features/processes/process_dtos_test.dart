import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/data/dto/process_dtos.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';

import 'process_test_fixtures.dart';

void main() {
  test('the four process options expose visible names and API codes', () {
    final expected = {
      M1ProcessCode.startUp: ('Start Up', 'START_UP'),
      M1ProcessCode.takeOver: ('Take Over', 'TAKE_OVER'),
      M1ProcessCode.supportSoftwareFactory: (
        'Soporte y Software Factory',
        'SUPPORT_SOFTWARE_FACTORY',
      ),
      M1ProcessCode.qualityContinuousImprovement: (
        'Calidad y Mejora Continua',
        'QUALITY_CONTINUOUS_IMPROVEMENT',
      ),
    };

    expect(M1ProcessCode.creatableValues.length, 4);
    for (final entry in expected.entries) {
      expect(entry.key.label, entry.value.$1);
      final json = CreateProcessRequestDto(
        code: entry.key,
        name: entry.key.label,
      ).toJson();
      expect(json['name'], entry.value.$1);
      expect(json['code'], entry.value.$2);
    }
  });

  test('save draft payload preserves node and evidence IDs', () {
    final version = sampleProcessVersion();
    final json = SaveDraftRequestDto(version: version).toJson();

    expect(json['revision'], 7);
    expect((json['policies'] as List).first['id'], 'policy-1');

    final macro =
        (json['macroActivities'] as List).first as Map<String, dynamic>;
    expect(macro['id'], 'macro-1');
    expect((macro['inputs'] as List).first['id'], 'input-1');
    expect((macro['outputs'] as List).first['id'], 'output-1');

    final activity =
        (macro['activities'] as List).first as Map<String, dynamic>;
    expect(activity['id'], 'activity-1');
    expect((activity['records'] as List).first['id'], 'record-1');
  });
}
