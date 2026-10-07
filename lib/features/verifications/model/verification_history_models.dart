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
  const RunProgress._({required this.total, required this.processed});

  factory RunProgress.fromValues({required int total, required int processed}) {
    if (total < 0 || processed < 0 || processed > total) {
      throw const FormatException('El progreso de la ejecución no es válido.');
    }
    return RunProgress._(total: total, processed: processed);
  }

  final int total;
  final int processed;

  double get fraction => total == 0 ? 0 : processed / total;
  String get fractionLabel => '$processed de $total';
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
  });

  final String id;
  final String serviceId;
  final String processVersionId;
  final VerificationScope scope;
  final VerificationRunStatus status;
  final RunProgress progress;
  final DateTime startedAt;
  final String? macroActivityId;

  bool get isTerminal => status.isTerminal;
}
