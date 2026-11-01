import 'package:intl/intl.dart';

import '../model/verification_result_models.dart';

/// Presentation only: API and audit payloads keep their original identifiers.
String humanizeVerificationText(String value) => value
    .replaceAll('EvidenceType.TICKET', 'evidencia de tipo ticket')
    .replaceAll('TOOL_RECORD', 'registro de herramienta')
    .replaceAll('IMPUTATIONS', 'imputaciones')
    .replaceAll(
      'SOURCE_PERMISSION_DENIED',
      'sin permiso para consultar la fuente',
    )
    .replaceAll('SOURCE_UNAVAILABLE', 'fuente no disponible')
    .replaceAll('TICKET_OUTSIDE_PROJECT', 'ticket ajeno al proyecto')
    .replaceAll('UNAUTHORIZED', 'autenticación rechazada')
    .replaceAll('FORBIDDEN', 'acceso denegado');

/// The API retains the original rationale for audit. Split its structured AI
/// suffix for display so an opaque provider ID does not read like a conclusion.
class TicketAiRationale {
  const TicketAiRationale({
    required this.explanation,
    required this.citedFields,
    required this.model,
    required this.responseId,
  });

  final String explanation;
  final List<String> citedFields;
  final String? model;
  final String? responseId;

  static TicketAiRationale? parse(String rationale) {
    final prefix = [
      'Propuesta IA: ',
      'Nueva propuesta de Gemini: ',
    ].where(rationale.startsWith).firstOrNull;
    if (prefix == null) return null;
    final value = rationale.substring(prefix.length);
    final marker = value.lastIndexOf(' Campos citados: ');
    if (marker < 0) {
      return TicketAiRationale(
        explanation: value,
        citedFields: const [],
        model: null,
        responseId: null,
      );
    }
    final metadata = RegExp(
      r'^\[([^\]]*)\]\.(?: Modelo: (.+?)(?:; respuesta: ([^.]+))?\.)?$',
    ).firstMatch(value.substring(marker + ' Campos citados: '.length));
    if (metadata == null) {
      return TicketAiRationale(
        explanation: value,
        citedFields: const [],
        model: null,
        responseId: null,
      );
    }
    return TicketAiRationale(
      explanation: value.substring(0, marker),
      citedFields: metadata
          .group(1)!
          .split(',')
          .map((field) => field.trim())
          .where((field) => field.isNotEmpty)
          .toList(),
      model: metadata.group(2),
      responseId: metadata.group(3),
    );
  }
}

String applicabilityMethodLabel(VerificationResult result) =>
    switch (result.applicability.origin) {
      DecisionOrigin.aiApplicability => 'Aplicabilidad: Gemini',
      DecisionOrigin.deterministic => 'Aplicabilidad: regla programada',
      DecisionOrigin.human => 'Aplicabilidad: decisión humana',
      DecisionOrigin.notEvaluated => 'Aplicabilidad: no evaluada',
      DecisionOrigin.unknown => 'Aplicabilidad: origen desconocido',
    };

String resultMethodLabel(VerificationResult result) {
  if (result.applicability.decision != ApplicabilityDecision.applies) {
    return 'Cumplimiento: no evaluado';
  }
  if (TicketAiRationale.parse(result.rationale) != null) {
    return 'Cumplimiento: IA + reglas';
  }
  if (result.reviewReason == ReviewReasonCode.unsupportedSource) {
    return 'Cumplimiento: sin lector automático';
  }
  if (result.searchStatus == EvidenceSearchStatus.notAttempted) {
    return 'Cumplimiento: fuente no consultada';
  }
  return 'Cumplimiento: regla programada';
}

/// Plain text intended for the clipboard. Keep section boundaries explicit;
/// Flutter's selection across separate widgets does not preserve this layout.
String formatHumanDecisionForCopy(HumanDecisionEvent event) {
  final decision =
      event.applicabilityDecision?.label ?? event.finalStatus?.label ?? '—';
  final date = DateFormat('dd/MM/yyyy HH:mm').format(event.decidedAt.toLocal());
  return [
    'Decisión humana: ${event.decisionType.label}',
    'Fecha: $date',
    'Decisión: $decision',
    '',
    'Fundamento escrito por el administrador:',
    event.rationale,
  ].join('\n');
}

String formatVerificationResultForCopy(VerificationResult result) {
  final lines = <String>[
    'Evidencia: ${result.displayName}',
    'Estado vigente: ${result.effectiveStatus.label}',
    'Evaluación automática del sistema: ${result.proposedStatus.label}',
    'Aplicabilidad: ${result.applicability.decision.label}',
    if (result.subjectTicketId != null)
      'Ticket seleccionado: #${result.subjectTicketId}',
    '',
    'Fundamento de la evaluación:',
    humanizeVerificationText(result.rationale),
  ];
  if (result.limitations.isNotEmpty) {
    lines.addAll([
      '',
      'Limitaciones:',
      for (final limitation in result.limitations)
        '- ${humanizeVerificationText(limitation)}',
    ]);
  }
  if (result.evidence.isNotEmpty) {
    lines.addAll([
      '',
      'Referencias:',
      for (final reference in result.evidence)
        '- ${reference.displayName} · ${reference.source.label} · ${reference.externalId}',
    ]);
  }
  if (result.humanDecisions.isNotEmpty) {
    lines.addAll(['', 'Decisiones humanas:']);
    for (final decision in result.humanDecisions) {
      lines.addAll(['', formatHumanDecisionForCopy(decision)]);
    }
  }
  return lines.join('\n');
}

String formatTicketSnapshotForCopy(Map<String, dynamic> ticket) {
  final id = _value(ticket['id']);
  final subject = _value(ticket['subject'], fallback: 'Sin asunto');
  final lines = <String>[
    'Ticket #$id — $subject',
    'Proyecto: ${_value(ticket['projectName'] ?? ticket['projectId'])}',
    'Estado: ${_value(ticket['statusName'] ?? ticket['status'])}',
    'Cerrado: ${ticket['closed'] == true
        ? 'Sí'
        : ticket['closed'] == false
        ? 'No'
        : '—'}',
  ];
  final updatedAt = formatTicketTimestamp(ticket['updatedAt']);
  if (updatedAt != '—') lines.add('Actualizado: $updatedAt');

  final description = ticket['description']?.toString().trim();
  if (description != null && description.isNotEmpty) {
    lines.addAll(['', 'Descripción:', description]);
  }

  final fields = ticket['customFields'];
  if (fields is List && fields.isNotEmpty) {
    lines.addAll(['', 'Campos personalizados:']);
    for (final field in fields.whereType<Map>()) {
      lines.add(
        '- ${_value(field['name'], fallback: 'Campo')}: ${_value(field['value'])}',
      );
    }
  }

  final journals = ticket['journals'];
  if (journals is List && journals.isNotEmpty) {
    lines.addAll(['', 'Historial del ticket:']);
    for (final journal in journals.whereType<Map>()) {
      final author = _value(journal['user'] ?? journal['author']);
      final date = formatTicketTimestamp(journal['createdAt']);
      lines.add('- ${[date, author].where((part) => part != '—').join(' · ')}');
      final notes = journal['notes']?.toString().trim();
      if (notes != null && notes.isNotEmpty) lines.add('  $notes');
      final changes = journal['changes'];
      if (changes is List) {
        for (final change in changes.whereType<Map>()) {
          final field = _value(change['field'], fallback: 'Cambio');
          lines.add(
            '  $field: ${_value(change['oldValue'])} → ${_value(change['newValue'])}',
          );
        }
      }
    }
  }

  return lines.join('\n');
}

String formatTicketTimestamp(Object? value) {
  DateTime? date;
  if (value is num) {
    date = DateTime.fromMillisecondsSinceEpoch(
      (value * 1000).round(),
      isUtc: true,
    );
  } else if (value is String) {
    date = DateTime.tryParse(value);
  }
  return date == null
      ? '—'
      : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
}

String _value(Object? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
