import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Supabase-based authentication service
/// Uses cloud backend for user management and authentication
class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _storage = FlutterSecureStorage();
  static const String _rememberMeKey = 'remember_me';

  /// Register a new user
  static Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Sign up with Supabase Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Registration failed. Please try again.',
        );
      }

      print('✅ User registered in auth: $email (ID: ${response.user!.id})');

      // Wait for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify profile was created, if not create it manually
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
        
        print('✅ Profile verified: ${profile['full_name']}');
      } catch (e) {
        // Trigger didn't work, create profile manually
        print('⚠️ Trigger failed, creating profile manually...');
        
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
        });
        
        print('✅ Profile created manually');
      }

      return AuthResult(
        success: true,
        message: 'Registration successful!',
        user: UserData(
          id: response.user!.id,
          email: email,
          fullName: fullName,
        ),
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.message),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: $e',
      );
    }
  }

  /// Login existing user
  static Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Login failed. Please check your credentials.',
        );
      }

      // Check if email is confirmed (if confirmation is enabled)
      if (response.user!.emailConfirmedAt == null) {
        return AuthResult(
          success: false,
          message: 'Please verify your email before logging in. Check your inbox.',
        );
      }

      // Save remember me preference
      await _storage.write(key: _rememberMeKey, value: rememberMe.toString());

      // Get user profile
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        print('✅ User logged in: $email');

        return AuthResult(
          success: true,
          message: 'Login successful!',
          user: UserData(
            id: response.user!.id,
            email: email,
            fullName: profile['full_name'],
          ),
        );
      } catch (e) {
        // Profile doesn't exist, create it now
        print('⚠️ Profile not found, creating one...');
        
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': response.user!.userMetadata?['full_name'] ?? 'User',
        });

        return AuthResult(
          success: true,
          message: 'Login successful!',
          user: UserData(
            id: response.user!.id,
            email: email,
            fullName: response.user!.userMetadata?['full_name'] ?? 'User',
          ),
        );
      }
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.message),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: $e',
      );
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: _rememberMeKey);
    print('✅ User logged out');
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Get current user data
  static Future<UserData?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserData(
        id: user.id,
        email: user.email!,
        fullName: profile['full_name'],
      );
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  /// Reset password via email
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent. Check your inbox.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.message),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send reset email: $e',
      );
    }
  }

  /// Update user profile
  static Future<AuthResult> updateProfile({
    required String fullName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return AuthResult(
        success: false,
        message: 'Not logged in',
      );
    }

    try {
      await _supabase.from('profiles').update({
        'full_name': fullName,
      }).eq('id', user.id);

      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update profile: $e',
      );
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  // Helper method to format error messages
  static String _getErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('User already registered')) {
      return 'Email already registered. Please login instead.';
    } else if (message.contains('Email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    return message;
  }
}

/// Authentication result model
class AuthResult {
  final bool success;
  final String message;
  final UserData? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// User data model
class UserData {
  final String id;
  final String email;
  final String fullName;

  UserData({
    required this.id,
    required this.email,
    required this.fullName,
  });
}