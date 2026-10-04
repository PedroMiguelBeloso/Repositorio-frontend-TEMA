import 'process_models.dart';

class RegistryDefinition {
  const RegistryDefinition({
    required this.id,
    required this.key,
    required this.canonicalName,
    required this.evidenceType,
    required this.preloaded,
    this.officialNomenclature,
  });

  final String id;
  final String key;
  final String canonicalName;
  final EvidenceType evidenceType;
  final bool preloaded;
  final String? officialNomenclature;

  factory RegistryDefinition.fromJson(Map<String, dynamic> json) =>
      RegistryDefinition(
        id: json['id'] as String,
        key: json['key'] as String? ?? '',
        canonicalName: json['canonicalName'] as String,
        evidenceType: EvidenceType.fromApi(json['evidenceType'] as String?),
        preloaded: json['preloaded'] as bool? ?? false,
        officialNomenclature: json['officialNomenclature'] as String?,
      );
}

class RegistryPage {
  const RegistryPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<RegistryDefinition> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
}
