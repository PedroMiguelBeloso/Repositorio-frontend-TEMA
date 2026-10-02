import '../../../core/errors/app_failure.dart';
import '../model/integration_source.dart';
import '../model/integration_state.dart';
import '../model/integration_status.dart';

class IntegrationStatusDto {
  const IntegrationStatusDto({
    required this.source,
    required this.state,
    required this.checkedAt,
    this.message,
  });

  final IntegrationSource source;
  final IntegrationState state;
  final DateTime checkedAt;
  final String? message;

  static IntegrationStatusDto? tryFromJson(Map<String, dynamic> json) {
    final source = IntegrationSource.tryParse(json['source']);
    if (source == null) return null;

    final rawCheckedAt = json['checkedAt'];
    if (rawCheckedAt is! String) {
      throw const UnexpectedFailure(
        'La respuesta de integraciones no tiene un formato válido.',
      );
    }

    final DateTime checkedAt;
    try {
      checkedAt = DateTime.parse(rawCheckedAt);
    } on FormatException {
      throw const UnexpectedFailure(
        'La respuesta de integraciones no tiene un formato válido.',
      );
    }

    return IntegrationStatusDto(
      source: source,
      state: IntegrationState.fromApi(json['status']),
      checkedAt: checkedAt,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  IntegrationStatus toModel() => IntegrationStatus(
    source: source,
    state: state,
    checkedAt: checkedAt,
    message: message,
  );
}