class ApiConfig {
  ApiConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static String get baseUrl {
    if (_rawBaseUrl.endsWith('/api/v1')) return _rawBaseUrl;
    if (_rawBaseUrl.endsWith('/')) return '${_rawBaseUrl}api/v1';
    return '$_rawBaseUrl/api/v1';
  }

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fjnbnbtjsuxumtmhcidh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqbmJuYnRqc3V4dW10bWhjaWRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjgzNTMsImV4cCI6MjA5NzIwNDM1M30.Ggqrad3PqQ_szto9zgT_alJveag97IgOh_LRB5czC3c',
  );

  // NOTE: auth (register/login/logout/me) goes through Supabase directly via
  // AuthService, not through this backend, so no /auth/* getters live here.
  // If a backend health-check endpoint is ever added, point healthUrl at the
  // root ("/") since that's the only health route the backend exposes today.
  static String get drugsSearchUrl => '$baseUrl/drugs/search';
  static String get requestsUrl => '$baseUrl/requests';
  static String get transactionsUrl => '$baseUrl/transactions';
}