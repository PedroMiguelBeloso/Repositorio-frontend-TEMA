import 'new_verification_models.dart';

enum VerificationRunStatus {
  queued('QUEUED', 'En espera'),
  running('RUNNING', 'En curso'),
  completed('COMPLETED', 'Finalizada'),
  failed('FAILED', 'Fallida'),
  unknown('UNKNOWN', 'Estado no reconocido');

  const VerificationRunStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static VerificationRunStatus fromApi(String? value) {
    return VerificationRunStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => VerificationRunStatus.unknown,
    );
  }

  bool get isTerminal =>
      this == VerificationRunStatus.completed ||
      this == VerificationRunStatus.failed;
}

class RunProgress {
  const RunProgress._({
    required this.total,
    required this.processed,
    required this.reviewRequired,
  });

  factory RunProgress.fromValues({
    required int total,
    required int processed,
    int reviewRequired = 0,
  }) {
    if (total < 0 || processed < 0 || reviewRequired < 0) {
      throw const FormatException('El progreso de la ejecución no es válido.');
    }
    return RunProgress._(
      total: total,
      processed: processed,
      reviewRequired: reviewRequired,
    );
  }

  final int total;
  final int processed;
  final int reviewRequired;

  double get fraction => total == 0 ? 0 : processed / total;
  String get fractionLabel => '$processed de $total';
}

class VerificationRun {
  const VerificationRun({
    required this.id,
    required this.serviceId,
    required this.processVersionId,
    required this.scope,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.macroActivityId,
    this.note,
    this.finishedAt,
    this.failureMessage,
    this.serviceNameSnapshot,
    this.processNameSnapshot,
    this.processOfficialVersionSnapshot,
    this.macroActivityNameSnapshot,
  });

  final String id;
  final String serviceId;
  final String processVersionId;
  final VerificationScope scope;
  final VerificationRunStatus status;
  final RunProgress progress;
  final DateTime startedAt;
  final String? macroActivityId;
  final String? note;
  final DateTime? finishedAt;
  final String? failureMessage;
  final String? serviceNameSnapshot;
  final String? processNameSnapshot;
  final String? processOfficialVersionSnapshot;
  final String? macroActivityNameSnapshot;

  bool get isTerminal => status.isTerminal;
  bool get isPollable =>
      status == VerificationRunStatus.queued ||
      status == VerificationRunStatus.running;
}

class VerificationRunSummary {
  const VerificationRunSummary({
    required this.id,
    required this.serviceId,
    required this.processVersionId,
    required this.scope,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.macroActivityId,
    this.serviceNameSnapshot,
    this.processNameSnapshot,
    this.processOfficialVersionSnapshot,
    this.macroActivityNameSnapshot,
  });

  final String id;
  final String serviceId;
  final String processVersionId;
  final VerificationScope scope;
  final VerificationRunStatus status;
  final RunProgress progress;
  final DateTime startedAt;
  final String? macroActivityId;
  final String? serviceNameSnapshot;
  final String? processNameSnapshot;
  final String? processOfficialVersionSnapshot;
  final String? macroActivityNameSnapshot;

  bool get isTerminal => status.isTerminal;
}
