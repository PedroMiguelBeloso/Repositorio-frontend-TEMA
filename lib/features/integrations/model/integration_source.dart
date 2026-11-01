enum IntegrationSource {
  drive('DRIVE', 'Google Drive'),
  redmine('REDMINE', 'Redmine'),
  gemini('GEMINI', 'Gemini');

  const IntegrationSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static IntegrationSource? tryParse(Object? value) {
    for (final source in values) {
      if (source.apiValue == value) return source;
    }
    return null;
  }
}
