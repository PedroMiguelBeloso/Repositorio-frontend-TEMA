import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_models.dart';

void main() {
  group('ticket selection state', () {
    test('ONE replaces the previous selection and blocks start until one is chosen', () {
      final preview = VerificationPreview(
        serviceId: 'svc-1',
        serviceRevision: 2,
        processVersionId: 'proc-1',
        scope: VerificationScope.macroActivity,
        macroActivityId: 'macro-1',
        expectations: const [],
        ticketSelectionGroups: [
          TicketSelectionGroup(
            id: 'group-1',
            macroActivityId: 'macro-1',
            label: 'TICKET: revisión',
            cardinality: Cardinality.one,
            inputExpectationIds: const ['exp-1'],
            relatedExpectationIds: const ['exp-2'],
            required: true,
          ),
        ],
      );

      final state = NewVerificationState(preview: preview);
      state.selectTicket(groupId: 'group-1', ticketId: '204');
      expect(state.selections['group-1'], {'204'});
      expect(state.canStart, isTrue);

      state.selectTicket(groupId: 'group-1', ticketId: '205');
      expect(state.selections['group-1'], {'205'});
      expect(state.canStart, isTrue);
      expect(state.buildTicketSelections(), [
        const TicketSelection(groupId: 'group-1', ticketIds: ['205']),
      ]);
    });

    test('MULTIPLE keeps multiple selections and preserves them independently by group', () {
      final preview = VerificationPreview(
        serviceId: 'svc-1',
        serviceRevision: 2,
        processVersionId: 'proc-1',
        scope: VerificationScope.macroActivity,
        macroActivityId: 'macro-1',
        expectations: const [],
        ticketSelectionGroups: [
          TicketSelectionGroup(
            id: 'group-1',
            macroActivityId: 'macro-1',
            label: 'Primera solicitud',
            cardinality: Cardinality.multiple,
            inputExpectationIds: const ['exp-1'],
            relatedExpectationIds: const [],
            required: true,
          ),
          TicketSelectionGroup(
            id: 'group-2',
            macroActivityId: 'macro-1',
            label: 'Segunda solicitud',
            cardinality: Cardinality.one,
            inputExpectationIds: const ['exp-3'],
            relatedExpectationIds: const [],
            required: true,
          ),
        ],
      );

      final state = NewVerificationState(preview: preview);
      state.selectTicket(groupId: 'group-1', ticketId: '204');
      state.selectTicket(groupId: 'group-1', ticketId: '205');
      state.selectTicket(groupId: 'group-2', ticketId: '999');

      expect(state.selections['group-1'], {'204', '205'});
      expect(state.selections['group-2'], {'999'});
      expect(state.canStart, isTrue);

      state.removeTicket(groupId: 'group-1', ticketId: '204');
      expect(state.selections['group-1'], {'205'});
      expect(state.buildTicketSelections(), [
        const TicketSelection(groupId: 'group-1', ticketIds: ['205']),
        const TicketSelection(groupId: 'group-2', ticketIds: ['999']),
      ]);
    });

    test('group without tickets does not add ids and leaves the request empty', () {
      final preview = VerificationPreview(
        serviceId: 'svc-1',
        serviceRevision: 2,
        processVersionId: 'proc-1',
        scope: VerificationScope.macroActivity,
        macroActivityId: 'macro-1',
        expectations: const [],
        ticketSelectionGroups: const [],
      );

      final state = NewVerificationState(preview: preview);
      expect(state.hasTicketGroups, isFalse);
      expect(state.buildTicketSelections(), isEmpty);
      expect(state.canStart, isTrue);
    });
  });
}
