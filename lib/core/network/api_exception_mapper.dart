import 'dart:convert';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';

class ApiExceptionMapper {
  const ApiExceptionMapper();

  static final RegExp _technicalMessagePattern = RegExp(
    r'\b(?:DioException|SocketException|HandshakeException|Exception|StackTrace|Stack\s+trace|Traceback|Unhandled|Caused\s+by)\b|'
    r'\b(?:dart:|package:|file:|https?://)|'
    r'^\s*#\d+\b|\bat\s+\S+\(\)',
    caseSensitive: false,
    multiLine: true,
  );

  AppFailure map(DioException exception) {
    final problem = _readProblem(exception.response?.data);
    final status = _readStatus(problem) ?? exception.response?.statusCode;

    if (exception.response == null) {
      return const NetworkFailure(
        'No se pudo conectar. Verificá tu conexión e intentá nuevamente.',
      );
    }
    if (status != null && status >= 500) {
      return ServiceFailure(
        _message(problem, 'El servicio no está disponible. Intentá más tarde.'),
      );
    }

    return switch (status) {
      401 => UnauthenticatedFailure(
        _message(problem, 'La sesión no es válida. Iniciá sesión nuevamente.'),
      ),
      403 => PermissionFailure(
        _message(problem, 'No tenés permiso para realizar esta acción.'),
      ),
      400 || 422 => ValidationFailure(
        _message(problem, 'Revisá los datos ingresados.'),
        fieldErrors: _fieldErrors(problem?['details']),
      ),
      409 => ConflictFailure(
        _message(
          problem,
          'La solicitud entra en conflicto con el estado actual.',
        ),
      ),
      _ => UnexpectedFailure(
        _message(problem, 'Ocurrió un error inesperado. Intentá nuevamente.'),
      ),
    };
  }

  AppFailure mapError(Object error, {required String fallbackMessage}) {
    if (error is DioException) return map(error);
    if (error is AppFailure) return error;
    return UnexpectedFailure(fallbackMessage);
  }

  Map<String, dynamic>? _readProblem(Object? data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    }
    if (data is! String) return null;

    try {
      final decoded = jsonDecode(data);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  int? _readStatus(Map<String, dynamic>? problem) {
    final status = problem?['status'];
    if (status is int) return status;
    if (status is String) return int.tryParse(status);
    return null;
  }

  String _message(Map<String, dynamic>? problem, String fallback) {
    for (final key in ['detail', 'title']) {
      final value = problem?[key];
      if (value is String && _isSafeMessage(value)) return value.trim();
    }
    return fallback;
  }


  Map<String, String> _fieldErrors(Object? details) {
    if (details is! List) return const {};

    final errors = <String, String>{};
    for (final item in details) {
      if (item is! Map) continue;
      final field = item['field'];
      final message = item['message'];
      if (field is String && field.trim().isNotEmpty &&
          message is String && message.trim().isNotEmpty) {
        errors[field.trim()] = message.trim();
      }
    }
    return errors;
  }

  bool _isSafeMessage(String value) {
    final message = value.trim();
    return message.isNotEmpty &&
        message.length <= 240 &&
        !_technicalMessagePattern.hasMatch(message);
  }
}
