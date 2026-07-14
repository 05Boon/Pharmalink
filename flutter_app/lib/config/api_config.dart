class ApiConfig {
  ApiConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://pharmalink-kvrt.onrender.com/api/v1',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static String get baseUrl {
    if (_rawBaseUrl.endsWith('/api/v1')) return _rawBaseUrl;
    if (_rawBaseUrl.endsWith('/')) return '${_rawBaseUrl}api/v1';
    return '$_rawBaseUrl/api/v1';
  }

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lqnmeegpjhzffjslxxek.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxxbm1lZWdwamh6ZmZqc2x4eGVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NjAyNjAsImV4cCI6MjA5OTUzNjI2MH0.2-TwKQyVcu7lk3AymxsGXD2Tq1xH2tuAjnDLdAIxPfs',
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
