import '../model/process_models.dart';
import '../model/registry_definition.dart';

abstract interface class RegistryRepository {
  Future<RegistryPage> search({String query = '', int page = 0, int size = 20});

  Future<RegistryDefinition> create({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  });
}
