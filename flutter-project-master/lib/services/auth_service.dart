import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple authentication service using local storage
/// For production, replace with actual backend API calls
class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';
  static const String _rememberMeKey = 'remember_me';

  /// Register a new user
  static Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final users = await _getUsers();
      
      // Check if email already exists
      if (users.any((user) => user['email'] == email)) {
        return AuthResult(
          success: false,
          message: 'Email already registered. Please login instead.',
        );
      }
      
      // Create new user
      final newUser = {
        'fullName': fullName,
        'email': email,
        'password': password, // In production, hash this!
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      users.add(newUser);
      
      // Save updated users list
      await prefs.setString(_usersKey, jsonEncode(users));
      
      // Auto-login after registration
      await _saveCurrentUser(email, fullName);
      
      return AuthResult(
        success: true,
        message: 'Registration successful!',
        user: UserData(
          email: email,
          fullName: fullName,
        ),
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
      final users = await _getUsers();
      
      // Find user with matching email
      final user = users.firstWhere(
        (u) => u['email'] == email,
        orElse: () => {},
      );
      
      if (user.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Email not found. Please register first.',
        );
      }
      
      // Check password
      if (user['password'] != password) {
        return AuthResult(
          success: false,
          message: 'Incorrect password. Please try again.',
        );
      }
      
      // Save current user
      await _saveCurrentUser(email, user['fullName']);
      
      // Save remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      
      return AuthResult(
        success: true,
        message: 'Login successful!',
        user: UserData(
          email: email,
          fullName: user['fullName'],
        ),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_rememberMeKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentUserKey);
  }

  /// Get current user data
  static Future<UserData?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    
    if (userJson == null) return null;
    
    final user = jsonDecode(userJson);
    return UserData(
      email: user['email'],
      fullName: user['fullName'],
    );
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Private helper methods
  
  static Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(usersJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> _saveCurrentUser(String email, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'email': email,
      'fullName': fullName,
      'loginAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_currentUserKey, jsonEncode(userData));
  }

  /// Clear all auth data (for testing/debugging)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_currentUserKey);
    await prefs.remove(_rememberMeKey);
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
  final String email;
  final String fullName;

  UserData({
    required this.email,
    required this.fullName,
  });
}