class AppEnvironment {
  AppEnvironment._();

  // Keep mock mode enabled by default so existing UX flows continue to work.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
}
