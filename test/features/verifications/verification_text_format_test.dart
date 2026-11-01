import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/verification_text_format.dart';

void main() {
  test('separates Gemini explanation from technical response metadata', () {
    final parsed = TicketAiRationale.parse(
      "Propuesta IA: El ticket sigue en estado 'To Do'. Campos citados: [statusName, assignedTo, description]. Modelo: gemini-3.5-flash-lite; respuesta: 2inmatWXMdiUmtkP2cmUoQ0.",
    );

    expect(parsed?.explanation, "El ticket sigue en estado 'To Do'.");
    expect(parsed?.citedFields, ['statusName', 'assignedTo', 'description']);
    expect(parsed?.model, 'gemini-3.5-flash-lite');
    expect(parsed?.responseId, '2inmatWXMdiUmtkP2cmUoQ0');
    expect(
      TicketAiRationale.parse(
        'Nueva propuesta de Gemini: El ticket no cumple.',
      )?.explanation,
      'El ticket no cumple.',
    );
    expect(TicketAiRationale.parse('Se encontró el archivo.'), isNull);
  });

  test('technical source codes are readable in evaluation text', () {
    expect(
      humanizeVerificationText('TOOL_RECORD no disponible: SOURCE_UNAVAILABLE'),
      'registro de herramienta no disponible: fuente no disponible',
    );
  });

  test(
    'ticket copy keeps metadata, notes and custom fields on separate lines',
    () {
      final text = formatTicketSnapshotForCopy({
        'id': '42',
        'subject': 'Issue-Prueba',
        'projectName': 'Proyecto-prueba',
        'statusName': 'To Do',
        'closed': false,
        'customFields': [
          {'name': 'Validación', 'value': 'Pendiente'},
        ],
        'journals': [
          {
            'user': 'Martín',
            'notes': 'Se revisó el requisito.',
            'changes': [
              {'field': 'Estado', 'oldValue': 'Nuevo', 'newValue': 'En curso'},
            ],
          },
        ],
      });

      expect(
        text,
        startsWith('Ticket #42 — Issue-Prueba\nProyecto: Proyecto-prueba'),
      );
      expect(text, contains('\nEstado: To Do\nCerrado: No'));
      expect(
        text,
        contains('\n\nCampos personalizados:\n- Validación: Pendiente'),
      );
      expect(
        text,
        contains(
          '\n\nHistorial del ticket:\n- Martín\n  Se revisó el requisito.',
        ),
      );
      expect(text, contains('\n  Estado: Nuevo → En curso'));
    },
  );
}
