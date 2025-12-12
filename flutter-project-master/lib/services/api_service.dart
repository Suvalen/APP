import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// API Service for Medical Chatbot + Symptom Checker
///
/// Now with cookie/session support for conversation memory!
/// - Chat: /get, /clear (maintains session)
/// - Symptom Checker: /start_assessment, /submit_answer, /get_diagnosis
class ApiService {
  // ⚠️ CHANGE THIS TO YOUR IP/URL
  // For Android Emulator: 'http://10.0.2.2:8080'
  // For iOS Simulator: 'http://localhost:8080'
  // For Chrome/Web: 'http://localhost:8080'
  // For Real Device: 'http://YOUR_COMPUTER_IP:8080'
  static const String baseUrl = 'https://defrayable-disingenuously-annalisa.ngrok-free.dev';

  // Singleton Dio instance with cookie jar
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status! < 500, // Don't throw on 4xx errors
    ));

    // Add cookie manager for session persistence
    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));

    // Add logging interceptor (optional - for debugging)
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[Dio] $obj'),
    ));

    return dio;
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  /// Test connection to Flask backend
  static Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // ============================================================================
  // CHAT (Option 1) - WITH SESSION MEMORY
  // ============================================================================

  /// Send a chat message and get AI response
  /// Now maintains conversation context via cookies!
  static Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/get',
        data: FormData.fromMap({'msg': message}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        try {
          // Try to parse as JSON
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          return data['answer'] ?? response.data.toString();
        } catch (e) {
          // Response is plain text
          return response.data.toString();
        }
      } else if (response.statusCode == 429) {
        return 'Rate limit exceeded. Please wait a moment and try again.';
      } else {
        return 'Error: Server returned ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Error: Connection timeout. Check your network.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return 'Error: Server took too long to respond.';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'Error: Could not connect to server. Is Flask running?';
      }
      print('Chat error: $e');
      return 'Error: Could not connect to server. Is Flask running?';
    } catch (e) {
      print('Chat error: $e');
      return 'Error: Unexpected error occurred.';
    }
  }

  /// Clear chat conversation history
  /// Also clears the session on backend
  static Future<bool> clearConversation() async {
    try {
      final response = await _dio.post(
        '/clear',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Clear conversation error: $e');
      return false;
    }
  }

  // ============================================================================
  // SYMPTOM CHECKER (Option 3) - WITH SESSION
  // ============================================================================

  /// Start a new symptom assessment
  static Future<Map<String, dynamic>> startAssessment() async {
    try {
      final response = await _dio.post(
        '/start_assessment',
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
      } else {
        return {
          'status': 'error',
          'message': 'Failed to start assessment: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Start assessment error: $e');
      return {'status': 'error', 'message': 'Could not connect to server'};
    }
  }

  /// Submit an answer to a question
  static Future<Map<String, dynamic>> submitAnswer(
    String questionId,
    dynamic answer,
  ) async {
    try {
      final response = await _dio.post(
        '/submit_answer',
        data: jsonEncode({
          'question_id': questionId,
          'answer': answer,
        }),
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
      } else {
        return {
          'status': 'error',
          'message': 'Failed to submit answer: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Submit answer error: $e');
      return {'status': 'error', 'message': 'Could not connect to server'};
    }
  }

  /// Get diagnosis based on submitted answers
  /// Now sends answers directly in request body
  static Future<Map<String, dynamic>> getDiagnosis(
      Map<String, dynamic> answers) async {
    try {
      final response = await _dio.post(
        '/get_diagnosis',
        data: jsonEncode({'answers': answers}),
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
      } else {
        return {
          'status': 'error',
          'message': 'Failed to get diagnosis: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Get diagnosis error: $e');
      return {'status': 'error', 'message': 'Could not connect to server'};
    }
  }

  /// Get all assessment questions (optional - for dynamic loading)
  static Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final response = await _dio.get(
        '/get_questions',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return List<Map<String, dynamic>>.from(data['questions']);
      } else {
        return [];
      }
    } catch (e) {
      print('Get questions error: $e');
      return [];
    }
  }

  // ============================================================================
  // API CHAT (Alternative JSON endpoint) - WITH SESSION
  // ============================================================================

  /// Send chat message via API endpoint (JSON request)
  static Future<Map<String, dynamic>> apiChat(String message) async {
    try {
      final response = await _dio.post(
        '/api/chat',
        data: jsonEncode({'message': message}),
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
      } else {
        return {'error': 'Server returned ${response.statusCode}'};
      }
    } catch (e) {
      print('API chat error: $e');
      return {'error': 'Could not connect to server'};
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear all cookies and reset session
  static Future<void> clearSession() async {
    try {
      final cookieJar = (_dio.interceptors.firstWhere((i) => i is CookieManager)
              as CookieManager)
          .cookieJar;
      await cookieJar.deleteAll();
      print('Session cleared');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Get current base URL
  static String getBaseUrl() => baseUrl;
}
