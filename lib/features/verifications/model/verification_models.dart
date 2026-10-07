import '../../../core/errors/app_failure.dart';

enum VerificationScope {
  process('PROCESS'),
  macroActivity('MACRO_ACTIVITY');

  const VerificationScope(this.apiValue);

  final String apiValue;

  static VerificationScope fromApi(String? value) {
    return VerificationScope.values.firstWhere(
      (scope) => scope.apiValue == value,
      orElse: () => VerificationScope.process,
    );
  }
}

enum Cardinality {
  one('ONE'),
  multiple('MULTIPLE'),
  unknown('UNKNOWN');

  const Cardinality(this.apiValue);

  final String apiValue;

  static Cardinality fromApi(String? value) {
    return Cardinality.values.firstWhere(
      (cardinality) => cardinality.apiValue == value,
      orElse: () => Cardinality.unknown,
    );
  }

  bool get isSingle => this == Cardinality.one;
  bool get isMultiple => this == Cardinality.multiple;
}

enum EvidenceType {
  ticket('TICKET'),
  document('DOCUMENT'),
  folder('FOLDER'),
  registry('REGISTRY'),
  unknown('UNKNOWN');

  const EvidenceType(this.apiValue);

  final String apiValue;

  static EvidenceType fromApi(String? value) {
    return EvidenceType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => EvidenceType.unknown,
    );
  }
}

enum ApplicabilityMode {
  required('REQUIRED'),
  optional('OPTIONAL'),
  caseDependent('CASE_DEPENDENT'),
  unknown('UNKNOWN');

  const ApplicabilityMode(this.apiValue);

  final String apiValue;

  static ApplicabilityMode fromApi(String? value) {
    return ApplicabilityMode.values.firstWhere(
      (mode) => mode.apiValue == value,
      orElse: () => ApplicabilityMode.unknown,
    );
  }
}

class PreviewExpectation {
  const PreviewExpectation({
    required this.id,
    required this.macroActivityId,
    this.activityId,
    required this.location,
    required this.displayName,
    this.evidenceType = EvidenceType.unknown,
    this.applicability = ApplicabilityMode.unknown,
    this.cardinality = Cardinality.unknown,
    this.ticketSelectionGroupId,
  });

  final String id;
  final String macroActivityId;
  final String? activityId;
  final String location;
  final String displayName;
  final EvidenceType evidenceType;
  final ApplicabilityMode applicability;
  final Cardinality cardinality;
  final String? ticketSelectionGroupId;

  factory PreviewExpectation.fromJson(Map<String, dynamic> json) {
    return PreviewExpectation(
      id: json['id'] as String? ?? '',
      macroActivityId: json['macroActivityId'] as String? ?? '',
      activityId: json['activityId'] as String?,
      location: json['location']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? '',
      evidenceType: EvidenceType.fromApi(json['evidenceType'] as String?),
      applicability: ApplicabilityMode.fromApi(
        json['applicability'] as String?,
      ),
      cardinality: Cardinality.fromApi(json['cardinality'] as String?),
      ticketSelectionGroupId: json['ticketSelectionGroupId'] as String?,
    );
  }
}

class TicketSummary {
  const TicketSummary({
    required this.id,
    required this.subject,
    required this.status,
    required this.projectId,
    this.assignedTo,
    this.updatedAt,
  });

  final String id;
  final String subject;
  final String status;
  final String projectId;
  final String? assignedTo;
  final DateTime? updatedAt;

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    final updatedAtValue = json['updatedAt'];
    return TicketSummary(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      assignedTo: json['assignedTo'] as String?,
      updatedAt: updatedAtValue == null || updatedAtValue is! String
          ? null
          : DateTime.tryParse(updatedAtValue),
    );
  }
}

class TicketSelectionGroup {
  const TicketSelectionGroup({
    required this.id,
    required this.macroActivityId,
    required this.label,
    required this.cardinality,
    this.inputExpectationIds = const [],
    this.relatedExpectationIds = const [],
    this.required = true,
  });

  final String id;
  final String macroActivityId;
  final String label;
  final Cardinality cardinality;
  final List<String> inputExpectationIds;
  final List<String> relatedExpectationIds;
  final bool required;

  factory TicketSelectionGroup.fromJson(Map<String, dynamic> json) {
    return TicketSelectionGroup(
      id: json['id'] as String? ?? '',
      macroActivityId: json['macroActivityId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      cardinality: Cardinality.fromApi(json['cardinality'] as String?),
      inputExpectationIds: (json['inputExpectationIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      relatedExpectationIds: (json['relatedExpectationIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      required: json['required'] as bool? ?? true,
    );
  }

  bool get isSingle => cardinality.isSingle;
  bool get isMultiple => cardinality.isMultiple;

  @override
  bool operator ==(Object other) {
    return other is TicketSelectionGroup &&
        other.id == id &&
        other.macroActivityId == macroActivityId &&
        other.label == label &&
        other.cardinality == cardinality &&
        other.required == required &&
        other.inputExpectationIds.equals(inputExpectationIds) &&
        other.relatedExpectationIds.equals(relatedExpectationIds);
  }

  @override
  int get hashCode => Object.hash(
    id,
    macroActivityId,
    label,
    cardinality,
    required,
    inputExpectationIds.length,
    relatedExpectationIds.length,
  );
}

class VerificationPreview {
  const VerificationPreview({
    required this.serviceId,
    required this.serviceRevision,
    required this.processVersionId,
    required this.scope,
    this.macroActivityId,
    this.expectations = const [],
    this.ticketSelectionGroups = const [],
  });

  final String serviceId;
  final int serviceRevision;
  final String processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final List<PreviewExpectation> expectations;
  final List<TicketSelectionGroup> ticketSelectionGroups;

  factory VerificationPreview.fromJson(Map<String, dynamic> json) {
    return VerificationPreview(
      serviceId: json['serviceId'] as String? ?? '',
      serviceRevision: (json['serviceRevision'] as num?)?.toInt() ?? 0,
      processVersionId: json['processVersionId'] as String? ?? '',
      scope: VerificationScope.fromApi(json['scope'] as String?),
      macroActivityId: json['macroActivityId'] as String?,
      expectations: (json['expectations'] as List<dynamic>? ?? const [])
          .map((item) => PreviewExpectation.fromJson(item as Map<String, dynamic>))
          .toList(),
      ticketSelectionGroups: (json['ticketSelectionGroups'] as List<dynamic>? ?? const [])
          .map((item) => TicketSelectionGroup.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TicketSelection {
  const TicketSelection({
    required this.groupId,
    required this.ticketIds,
  });

  final String groupId;
  final List<String> ticketIds;

  factory TicketSelection.fromJson(Map<String, dynamic> json) {
    return TicketSelection(
      groupId: json['groupId'] as String? ?? '',
      ticketIds: (json['ticketIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'ticketIds': ticketIds,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TicketSelection &&
        other.groupId == groupId &&
        other.ticketIds.equals(ticketIds);
  }

  @override
  int get hashCode => Object.hash(groupId, ticketIds.length);
}

class StartVerificationRequest {
  const StartVerificationRequest({
    required this.serviceId,
    required this.serviceRevision,
    required this.processVersionId,
    required this.scope,
    this.macroActivityId,
    this.note,
    this.ticketSelections = const [],
  });

  final String serviceId;
  final int serviceRevision;
  final String processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final String? note;
  final List<TicketSelection> ticketSelections;

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceRevision': serviceRevision,
      'processVersionId': processVersionId,
      'scope': scope.apiValue,
      if (macroActivityId != null && macroActivityId!.isNotEmpty)
        'macroActivityId': macroActivityId,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
      'ticketSelections': ticketSelections.map((item) => item.toJson()).toList(),
    };
  }
}

class VerificationRun {
  const VerificationRun({
    required this.id,
    required this.serviceId,
    required this.serviceRevision,
    required this.processVersionId,
    required this.scope,
    required this.status,
    this.ticketSelections = const [],
  });

  final String id;
  final String serviceId;
  final int serviceRevision;
  final String processVersionId;
  final VerificationScope scope;
  final String status;
  final List<TicketSelection> ticketSelections;

  factory VerificationRun.fromJson(Map<String, dynamic> json) {
    return VerificationRun(
      id: json['id'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      serviceRevision: (json['serviceRevision'] as num?)?.toInt() ?? 0,
      processVersionId: json['processVersionId'] as String? ?? '',
      scope: VerificationScope.fromApi(json['scope'] as String?),
      status: json['status'] as String? ?? '',
      ticketSelections: (json['ticketSelections'] as List<dynamic>? ?? const [])
          .map((item) => TicketSelection.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PageInfo {
  const PageInfo({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasNext => page + 1 < totalPages;
  bool get hasPrevious => page > 0;
}

class TicketSearchState {
  const TicketSearchState({
    this.items = const [],
    this.page = const PageInfo(page: 0, size: 10, totalElements: 0, totalPages: 0),
    this.query = '',
    this.isLoading = false,
    this.failure,
  });

  final List<TicketSummary> items;
  final PageInfo page;
  final String query;
  final bool isLoading;
  final AppFailure? failure;

  TicketSearchState copyWith({
    List<TicketSummary>? items,
    PageInfo? page,
    String? query,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
  }) => TicketSearchState(
    items: items ?? this.items,
    page: page ?? this.page,
    query: query ?? this.query,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class NewVerificationState {
  NewVerificationState({
    this.preview,
    this.serviceId,
    this.processVersionId,
    this.scope = VerificationScope.macroActivity,
    this.macroActivityId,
    this.previewFailure,
    this.isLoadingPreview = false,
    this.isStarting = false,
    Map<String, TicketSearchState>? ticketSearchStates,
    Map<String, Set<String>>? selections,
  }) : ticketSearchStates = ticketSearchStates ?? const {},
       selections = selections ?? const {};

  final VerificationPreview? preview;
  final String? serviceId;
  final String? processVersionId;
  final VerificationScope scope;
  final String? macroActivityId;
  final AppFailure? previewFailure;
  final bool isLoadingPreview;
  final bool isStarting;
  Map<String, TicketSearchState> ticketSearchStates;
  Map<String, Set<String>> selections;

  bool get hasTicketGroups => (preview?.ticketSelectionGroups ?? const []).isNotEmpty;

  bool get canStart {
    if (!hasTicketGroups) {
      return true;
    }
    return !hasRequiredMissing;
  }

  bool get hasRequiredMissing {
    final groups = preview?.ticketSelectionGroups ?? const <TicketSelectionGroup>[];
    for (final group in groups) {
      if (!group.required) continue;
      final selectedIds = selections[group.id] ?? const <String>{};
      if (group.isSingle) {
        if (selectedIds.length != 1) return true;
      } else if (group.isMultiple) {
        if (selectedIds.isEmpty) return true;
      }
    }
    return false;
  }

  bool get isSelectionEmpty => selections.values.every((ids) => ids.isEmpty);

  NewVerificationState copyWith({
    VerificationPreview? preview,
    String? serviceId,
    String? processVersionId,
    VerificationScope? scope,
    String? macroActivityId,
    AppFailure? previewFailure,
    bool clearPreviewFailure = false,
    bool? isLoadingPreview,
    bool? isStarting,
    Map<String, TicketSearchState>? ticketSearchStates,
    Map<String, Set<String>>? selections,
  }) {
    return NewVerificationState(
      preview: preview ?? this.preview,
      serviceId: serviceId ?? this.serviceId,
      processVersionId: processVersionId ?? this.processVersionId,
      scope: scope ?? this.scope,
      macroActivityId: macroActivityId ?? this.macroActivityId,
      previewFailure:
          clearPreviewFailure ? null : previewFailure ?? this.previewFailure,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isStarting: isStarting ?? this.isStarting,
      ticketSearchStates: ticketSearchStates ?? this.ticketSearchStates,
      selections: selections ?? this.selections,
    );
  }

  void selectTicket({required String groupId, required String ticketId}) {
    final group = preview?.ticketSelectionGroups.firstWhere(
      (item) => item.id == groupId,
      orElse: () => const TicketSelectionGroup(
        id: '',
        macroActivityId: '',
        label: '',
        cardinality: Cardinality.unknown,
      ),
    );

    final next = {...selections};
    final current = next[groupId] ?? <String>{};
    if (group?.isSingle == true) {
      next[groupId] = {ticketId};
    } else {
      final updated = {...current};
      if (updated.contains(ticketId)) {
        updated.remove(ticketId);
      } else {
        updated.add(ticketId);
      }
      if (updated.isEmpty) {
        next.remove(groupId);
      } else {
        next[groupId] = updated;
      }
    }
    selections = next;
  }

  void removeTicket({required String groupId, required String ticketId}) {
    final next = {...selections};
    final current = next[groupId] ?? <String>{};
    if (current.contains(ticketId)) {
      final updated = {...current}..remove(ticketId);
      if (updated.isEmpty) {
        next.remove(groupId);
      } else {
        next[groupId] = updated;
      }
    }
    selections = next;
  }

  void clearSelections() {
    selections = {};
  }

  bool isTicketSelected(String groupId, String ticketId) =>
      (selections[groupId] ?? const <String>{}).contains(ticketId);

  List<TicketSelection> buildTicketSelections() {
    final groups = preview?.ticketSelectionGroups ?? const <TicketSelectionGroup>[];
    final result = <TicketSelection>[];
    for (final group in groups) {
      final selectedIds = (selections[group.id] ?? const <String>{}).toList()
        ..sort();
      if (selectedIds.isEmpty) continue;
      result.add(TicketSelection(groupId: group.id, ticketIds: selectedIds));
    }
    return result;
  }

}

extension _ListEquals<T> on List<T> {
  bool equals(List<T> other) {
    if (identical(this, other)) return true;
    if (length != other.length) return false;
    for (var index = 0; index < length; index++) {
      if (this[index] != other[index]) return false;
    }
    return true;
  }
}
