import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Gets the Supabase client instance initialized in main.dart
  // Use this anywhere you need to talk to Supabase
  static final supabase = Supabase.instance.client;

  // Calls Supabase Auth sign up
  // Also inserts pharmacy details into your pharmacies table
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Creates the user in Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // stored in user_metadata
      );

      final user = response.user;

      if (user == null) {
        return {
          'ok': false,
          'error': {
            'code': 'REGISTER_FAILED',
            'message': 'Could not create account'
          }
        };
      }

      // Insert pharmacy details into your pharmacies table
      await supabase.from('pharmacies').insert({
        'id': user.id,
        'name': name,
        'email': email,
        // WKT format for PostGIS geography column
        'location': 'POINT($longitude $latitude)',
      });

      return {
        'ok': true,
        'message': 'Account created',
        'data': {
          'id': user.id,
          'name': name,
          'email': email,
        }
      };
    } on AuthException catch (e) {
      // Supabase throws AuthException for auth-specific errors
      // e.g. email already exists, weak password
      return {
        'ok': false,
        'error': {'code': 'AUTH_ERROR', 'message': e.message}
      };
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'REGISTER_FAILED', 'message': e.toString()}
      };
    }
  }

  // Signs in with email and password
  // Supabase automatically stores the session token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return {
          'ok': false,
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Wrong email or password'
          }
        };
      }

      return {
        'ok': true,
        'message': 'Login successful',
        'data': {
          'pharmacy': {
            'id': user.id,
            // user_metadata is where you stored the name on register
            'name': user.userMetadata?['name'],
            'email': user.email,
          }
        }
      };
    } on AuthException catch (e) {
      return {
        'ok': false,
        'error': {'code': 'INVALID_CREDENTIALS', 'message': e.message}
      };
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'LOGIN_FAILED', 'message': e.toString()}
      };
    }
  }

  // Signs out and clears the local session
  static Future<Map<String, dynamic>> logout() async {
    try {
      await supabase.auth.signOut();
      return {'ok': true, 'message': 'Logged out'};
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'LOGOUT_FAILED', 'message': e.toString()}
      };
    }
  }

  // Returns the currently logged in user
  // Returns null if no one is logged in
  static Map<String, dynamic>? getMe() {
    // currentUser is stored locally by supabase_flutter
    // No network call needed — it reads from local storage
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    return {
      'id': user.id,
      'name': user.userMetadata?['name'],
      'email': user.email,
    };
  }

  // Returns true if a user is currently logged in
  // Use this to protect routes
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
}