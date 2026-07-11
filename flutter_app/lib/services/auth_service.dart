import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import 'app_dio.dart';
import 'realtime_alert_service.dart';

class AuthService {
  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get accessToken => Supabase.instance.client.auth.currentSession?.accessToken;

  static bool get isAdmin {
    final user = Supabase.instance.client.auth.currentUser;
    final email = _currentUser?['email'] as String? ?? user?.email;
    final role = _currentUser?['role'] as String? ?? 
                 user?.appMetadata['role'] as String? ?? 
                 user?.userMetadata?['role'] as String?;
    return (email != null && email.contains('admin')) || role == 'admin';
  }

  static Map<String, dynamic> _failure({
    required String code,
    required String message,
  }) {
    return {
      'ok': false,
      'error': {'code': code, 'message': message}
    };
  }

  /// Registers a new pharmacy by executing Phase 1 (Supabase signUp) 
  /// followed by Phase 2 (FastAPI profile sync).
  /// If Phase 2 fails, it rolls back Phase 1 by logging the user out.
  static Future<Map<String, dynamic>> registerPharmacy({
    required String businessName,
    required String email,
    required String password,
    required String licenseNumber,
    required String phoneNumber,
    required double latitude,
    required double longitude,
  }) async {
    final supabase = Supabase.instance.client;
    
    // Helper closure to perform profile synchronization
    Future<Map<String, dynamic>> syncProfile(String token) async {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      try {
        final response = await AppDio.instance.post(
          '${ApiConfig.baseUrl}/pharmacies/sync-profile',
          data: {
            'business_name': businessName,
            'license_number': licenseNumber,
            'email': email,
            'phone_number': phoneNumber,
            'latitude': latitude,
            'longitude': longitude,
          },
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 201) {
          final detail = response.data is Map && response.data.containsKey('detail')
              ? response.data['detail']
              : 'Profile synchronization failed with status code ${response.statusCode}.';
              
          return _failure(
            code: 'SYNC_FAILED',
            message: detail.toString(),
          );
        }

        final responseData = response.data as Map<String, dynamic>;
        _currentUser = responseData;
        
        return {
          'ok': true,
          'data': responseData,
          'message': 'Registration and profile sync completed successfully.',
        };
      } catch (e) {
        return _failure(
          code: 'SYNC_FAILED',
          message: 'Profile synchronization failed: ${e.toString()}',
        );
      }
    }

    try {
      // 1. Phase 1 - Supabase Auth Registration
      AuthResponse authResponse;
      try {
        authResponse = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'business_name': businessName},
        );
      } catch (signupError) {
        final errorStr = signupError.toString().toLowerCase();
        // Self-heal orphaned Supabase account by silently signing in
        if (errorStr.contains('already registered') || errorStr.contains('already exists')) {
          try {
            final signInResult = await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
            final token = signInResult.session?.accessToken ??
                supabase.auth.currentSession?.accessToken;
            if (token != null && token.isNotEmpty) {
              final syncResult = await syncProfile(token);
              if (syncResult['ok'] == true) {
                return syncResult;
              } else {
                await supabase.auth.signOut();
                return _failure(
                  code: 'ORPHANED_SYNC_FAILED',
                  message: 'Account exists but profile sync failed. Please try again to retry: ${syncResult['error']['message']}',
                );
              }
            }
          } catch (signinError) {
            return _failure(
              code: 'REGISTER_FAILED',
              message: 'Account already exists. Incorrect password or credentials: ${signinError.toString()}',
            );
          }
        }
        
        return _failure(
          code: 'REGISTER_FAILED',
          message: 'Auth registration failed: ${signupError.toString()}',
        );
      }

      final user = authResponse.user;
      final session = authResponse.session;
      if (user == null) {
        return _failure(
          code: 'REGISTER_FAILED',
          message: 'User registration failed on auth provider.',
        );
      }

      String? token = session?.accessToken ??
          supabase.auth.currentSession?.accessToken;
          
      if (token == null || token.isEmpty) {
        try {
          final signInResult = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          token = signInResult.session?.accessToken ??
              supabase.auth.currentSession?.accessToken;
        } catch (_) {
          return _failure(
            code: 'EMAIL_CONFIRMATION_REQUIRED',
            message: 'Account created. Please confirm your email, then login to complete profile setup.',
          );
        }
      }

      if (token == null || token.isEmpty) {
        return _failure(
          code: 'EMAIL_CONFIRMATION_REQUIRED',
          message: 'Account created. Please confirm your email, then login to complete profile setup.',
        );
      }

      // 2. Phase 2 - FastAPI Profile Synchronization
      final syncResult = await syncProfile(token);
      if (syncResult['ok'] == true) {
        return syncResult;
      } else {
        await supabase.auth.signOut();
        return _failure(
          code: 'ORPHANED_SYNC_FAILED',
          message: 'Supabase signup succeeded, but profile sync failed. Please click register again to retry: ${syncResult['error']['message']}',
        );
      }
    } catch (e) {
      return _failure(
        code: 'REGISTER_FAILED',
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Authenticates a pharmacy owner via Supabase Auth
  static Future<Map<String, dynamic>> loginPharmacy({
    required String email,
    required String password,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      final session = authResponse.session;
      if (user == null || session == null) {
        return _failure(
          code: 'LOGIN_FAILED',
          message: 'Invalid email or password.',
        );
      }

      // Store minimal local representation of user
      _currentUser = {
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? '',
        'role': user.appMetadata['role'] ?? user.userMetadata?['role'] ?? '',
      };

      try {
        final profileResponse = await AppDio.instance.get(
          '${ApiConfig.baseUrl}/pharmacies/me',
          options: Options(
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          ),
        );
        if (profileResponse.statusCode == 200 && profileResponse.data is Map) {
          _currentUser!['account_status'] = profileResponse.data['account_status'];
        }
      } catch (_) {}

      return {
        'ok': true,
        'data': {
          'access_token': session.accessToken,
          'user': _currentUser,
        },
        'message': 'Login successful.',
      };
    } catch (e) {
      return _failure(
        code: 'LOGIN_FAILED',
        message: e.toString(),
      );
    }
  }

  /// Signs the current user out of Supabase Auth
  static Future<Map<String, dynamic>> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await RealtimeAlertService.instance.disconnect();
      _currentUser = null;
      return {'ok': true, 'message': 'Logged out successfully.'};
    } catch (e) {
      _currentUser = null;
      return _failure(
        code: 'LOGOUT_FAILED',
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  /// Returns the cached profile details of the logged-in pharmacy node
  static Map<String, dynamic>? getMe() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return _currentUser ?? {
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['name'] ?? '',
    };
  }

  /// Checks if a session is currently active
  static bool isLoggedIn() {
    return Supabase.instance.client.auth.currentSession != null;
  }

  // --- Backwards Compatibility Wrappers ---
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String licenseNumber,
    required String phoneNumber,
    required double latitude,
    required double longitude,
  }) => registerPharmacy(
    businessName: name,
    email: email,
    password: password,
    licenseNumber: licenseNumber,
    phoneNumber: phoneNumber,
    latitude: latitude,
    longitude: longitude,
  );

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => loginPharmacy(
    email: email,
    password: password,
  );
}