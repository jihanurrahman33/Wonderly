/// Route paths. Keep them here so screens never hard-code strings.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const profileSetup = '/profile-setup';

  static const home = '/home';
  static const learn = '/learn';
  static const rewards = '/rewards';
  static const me = '/me';

  static const progress = '/me/progress';
  static const settings = '/settings';
  static const parentGate = '/parent-gate';
  static const grownUps = '/grown-ups';
  static const smartBuddy = '/smart-buddy';

  /// Pages that need the parent gate, and where the gate may send you.
  static const parentOnly = {grownUps, smartBuddy};
  static const results = '/results';

  static const subjectParam = 'subject';
  static const setParam = 'setId';
  static const badgeParam = 'badge';

  static String subject(String name) => '/learn/$name';
  static String quiz(String setId) => '/quiz/$setId';
  static String badge(String name) => '/badge/$name';

  static const subjectPattern = '/learn/:$subjectParam';
  static const quizPattern = '/quiz/:$setParam';
  static const badgePattern = '/badge/:$badgeParam';

  /// Locations a child without a profile may visit.
  static const publicLocations = {splash, onboarding, profileSetup};
}
