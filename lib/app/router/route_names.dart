abstract final class RouteNames {
  static const loginName = 'login';
  static const loginPath = '/login';

  static const homeName = 'home';
  static const homePath = '/';

  static const processesName = 'processes';
  static const processesPath = '/processes';
  static const processDetailsName = 'process-details';
  static const processDetailsPath = '/processes/:id';
  static const processHistoryName = 'process-history';
  static const processHistoryPath = '/processes/:id/history';

  static const servicesName = 'services';
  static const servicesPath = '/services';

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
  };

  static bool isAdminOnly(String location) => adminOnlyPaths.contains(location);

  static String processDetails(String id) => '/processes/$id';
  static String processHistory(String id) => '/processes/$id/history';
  static String verificationDetails(String runId) => '/verifications/$runId';
  static String verificationResults(String runId) =>
      '/verifications/$runId/results';
}
