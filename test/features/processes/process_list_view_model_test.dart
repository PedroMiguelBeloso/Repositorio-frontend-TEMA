import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/viewmodel/process_list_view_model.dart';

void main() {
  test('an existing process is removed from new-process options', () {
    final state = ProcessListState(
      items: [
        ProcessOverview(
          definition: ProcessDefinition(
            id: 'process-1',
            code: M1ProcessCode.startUp,
            name: 'Start Up',
            m2Enabled: true,
            createdAt: DateTime(2026, 10, 1),
          ),
          versions: const [],
        ),
      ],
    );

    expect(state.availableCodes, isNot(contains(M1ProcessCode.startUp)));
    expect(state.availableCodes, contains(M1ProcessCode.takeOver));
    expect(
      state.availableCodes,
      contains(M1ProcessCode.supportSoftwareFactory),
    );
    expect(
      state.availableCodes,
      contains(M1ProcessCode.qualityContinuousImprovement),
    );
  });
}
