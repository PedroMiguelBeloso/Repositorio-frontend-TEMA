import '../../services/model/service_models.dart';

enum VerificationScope {
  process('PROCESS', 'Proceso completo'),
  macroActivity('MACRO_ACTIVITY', 'Una macroactividad'),
  unknown('UNKNOWN', 'Alcance no reconocido');

  const VerificationScope(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static VerificationScope fromApi(String? value) {
    return VerificationScope.values.firstWhere(
      (scope) => scope.apiValue == value,
      orElse: () => VerificationScope.unknown,
    );
  }
}

class VerifiableProcess {
  const VerifiableProcess({
    required this.id,
    required this.name,
    required this.officialVersion,
    required this.macroActivities,
  });

  final String id;
  final String name;
  final String officialVersion;
  final List<VerifiableMacroActivity> macroActivities;
}

class VerifiableMacroActivity {
  const VerifiableMacroActivity({required this.id, required this.name});
  final String id;
  final String name;
}

class PreviewExpectation {
  const PreviewExpectation({
    required this.id,
    required this.displayName,
    required this.location,
    required this.evidenceType,
    required this.applicability,
    required this.cardinality,
    this.ticketSelectionGroupId,
  });
  final String id;
  final String displayName;
  final String location;
  final String evidenceType;
  final String applicability;
  final String cardinality;
  final String? ticketSelectionGroupId;
}

class TicketSelectionGroup {
  const TicketSelectionGroup({
    required this.id,
    required this.label,
    required this.cardinality,
    required this.required,
    required this.relatedExpectationIds,
  });
  final String id;
  final String label;
  final String cardinality;
  final bool required;
  final List<String> relatedExpectationIds;
  bool get isSingle => cardinality == 'ONE';
}

class VerificationPreview {
  const VerificationPreview({
    required this.serviceId,
    required this.serviceRevision,
    required this.processVersionId,
    required this.scope,
    this.macroActivityId,
    required this.expectations,
    required this.ticketSelectionGroups,
  });
  final String serviceId;
  final int serviceRevision;
  final String processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final List<PreviewExpectation> expectations;
  final List<TicketSelectionGroup> ticketSelectionGroups;
}

class TicketSummary {
  const TicketSummary({
    required this.id,
    required this.subject,
    required this.status,
    this.assignedTo,
  });
  final String id;
  final String subject;
  final String status;
  final String? assignedTo;
}

class TicketPage {
  const TicketPage({required this.items, required this.page});
  final List<TicketSummary> items;
  final PageInfo page;
}

class VerificationTarget {
  const VerificationTarget({
    required this.serviceId,
    required this.processVersionId,
    required this.scope,
    this.macroActivityId,
    this.note,
  });
  final String serviceId;
  final String processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final String? note;
}
