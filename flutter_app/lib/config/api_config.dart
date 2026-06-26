class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get healthUrl => '$baseUrl/health';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get logoutUrl => '$baseUrl/auth/logout';
  static String get meUrl => '$baseUrl/auth/me';
  static String get drugsSearchUrl => '$baseUrl/drugs/search';
  static String get requestsUrl => '$baseUrl/requests';
  static String get transactionsUrl => '$baseUrl/transactions';
}