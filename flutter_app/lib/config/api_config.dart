class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fjnbnbtjsuxumtmhcidh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqbmJuYnRqc3V4dW10bWhjaWRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjgzNTMsImV4cCI6MjA5NzIwNDM1M30.Ggqrad3PqQ_szto9zgT_alJveag97IgOh_LRB5czC3c',
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