import 'package:flutter/material.dart';
import 'welcome_page/splash.dart';
import 'welcome_page/welcome_page.dart';
import 'screens/main_layout.dart';
import 'screens/welcome_home_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/diagnosis_mode_screen.dart';
import 'reg/login.dart';
import 'reg/register.dart';
import 'services/chat_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  print('✅ Supabase initialized successfully');
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/welcome': (_) =>
            const LoginScreen(), // Welcome page with login/register buttons
        '/loginform': (_) => const LoginForm(), // Login form
        '/register': (_) => const RegisterScreen(), // Register form
        '/welcome-home': (_) => const WelcomeHomeScreen(), // Welcome home with "Get Started" button that goes to chat
        '/questionnaire': (_) => const QuestionnaireScreen(), // Legacy questionnaire (not used in main flow)
        '/home': (_) => const MainLayout(), // Main app with chat screen
        '/settings': (_) => const SettingsScreen(), // Settings/Profile page
        '/diagnosis': (_) => const DiagnosisModeScreen(), // Diagnosis mode - Ada Health style symptom checker
        '/splash': (_) => const SplashScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context).pushReplacementNamed('/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: SplashVisual()), // use imported widget
    );
  }
}

// LoginScreen is now imported from welcome_page/welcome_page.dart

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title: const Text('Login', style: TextStyle(color: Color(0xFF323142))),
        iconTheme: const IconThemeData(color: Color(0xFF323142)),
      ),
      body: const YourLoginWidget(), // Use the functional login widget
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title:
            const Text('Register', style: TextStyle(color: Color(0xFF323142))),
        iconTheme: const IconThemeData(color: Color(0xFF323142)),
      ),
      body: const SignUpWidget(), // Use the functional signup widget
    );
  }
}


// IMPROVED: Replaced static Figma UI in LoginForm and RegisterScreen with functional widgets (YourLoginWidget and SignUpWidget from reg/ folder)
// IMPROVED: Refactored to use Main Scaffold Pattern - MainLayout manages bottom navigation with reusable CustomBottomNav widget, content pages are separated (HomeContent, SearchContent, ProfileContent), single source of truth for navigation state
// IMPROVED: Streamlined login flow - now goes: Splash → Login → Welcome Home → Chat Screen (diagnosis mode accessible via button in chat, skipping the old questionnaire page)
