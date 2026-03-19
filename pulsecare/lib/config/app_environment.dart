class AppEnvironment {
  AppEnvironment._();

  static const String mode = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static bool get isProduction => mode.toLowerCase() != 'dev';

  static bool get useLocalSeedData => !isProduction;
}
