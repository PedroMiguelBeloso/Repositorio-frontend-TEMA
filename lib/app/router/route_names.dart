abstract final class RouteNames {
  static const loginName = 'login';
  static const loginPath = '/login';

  static const homeName = 'home';
  static const homePath = '/';

  static const processesName = 'processes';
  static const processesPath = '/processes';
  static const registryName = 'registry';
  static const registryPath = '/settings/registry';
  static const processDetailsName = 'process-details';
  static const processDetailsPath = '/processes/:id';
  static const processHistoryName = 'process-history';
  static const processHistoryPath = '/processes/:id/history';
  static const processStructureName = 'process-structure';
  static const processStructurePath =
      '/processes/:processId/versions/:versionId/structure';
  static const processVersionName = 'process-version';
  static const processVersionPath = '/processes/:id/versions/:versionId';

  static const servicesName = 'services';
  static const servicesPath = '/services';
  static const servicesNewName = 'service-new';
  static const servicesNewPath = '/services/new';
  static const serviceDetailsName = 'service-details';
  static const serviceDetailsPath = '/services/:id';
  static const serviceEditName = 'service-edit';
  static const serviceEditPath = '/services/:id/edit';

  static const verificationsName = 'verifications';
  static const verificationsPath = '/verifications';
  static const newVerificationName = 'new-verification';
  static const newVerificationPath = '/verifications/new';
  static const verificationDetailsName = 'verification-details';
  static const verificationDetailsPath = '/verifications/:runId';
  static const verificationResultsName = 'verification-results';
  static const verificationResultsPath = '/verifications/:runId/results';

  static const integrationsName = 'integrations';
  static const integrationsPath = '/settings/integrations';

  static const usersName = 'users';
  static const usersPath = '/users';
  static const createReaderName = 'create-reader';
  static const createReaderPath = '/users/new';
  static const changePasswordName = 'change-password';
  static const changePasswordPath = '/settings/password';

  static const adminOnlyPaths = <String>{
    integrationsPath,
    newVerificationPath,
    usersPath,
    createReaderPath,
    servicesNewPath,
  };

  static bool isAdminOnly(String location) =>
      adminOnlyPaths.contains(location) ||
      location == servicesNewPath ||
      RegExp(r'^/services/[^/]+/edit$').hasMatch(location);

  static String serviceDetails(String id) => '/services/$id';
  static String serviceEdit(String id) => '/services/$id/edit';

  static String processDetails(String id) => '/processes/$id';
  static String processHistory(String id) => '/processes/$id/history';
  static String processStructure(String processId, String versionId) =>
      '/processes/$processId/versions/$versionId/structure';
  static String processVersion(String id, String versionId) =>
      '/processes/$id/versions/$versionId';
  static String verificationDetails(String runId) => '/verifications/$runId';
  static String verificationResults(String runId) =>
      '/verifications/$runId/results';
}
