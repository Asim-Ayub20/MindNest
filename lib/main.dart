import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_type_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patient_onboarding_screen.dart';
import 'screens/therapist_onboarding_screen.dart';
import 'screens/password_reset_screen.dart';
import 'utils/page_transitions.dart';

// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimizations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://yqhgsmrtxgfjuljazoie.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxaGdzbXJ0eGdmanVsamF6b2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NTE2ODEsImV4cCI6MjA3NDEyNzY4MX0.Iny6UH4vjesqQyh4sDMcmV58XKgUXDeERImhlKJNcUk',
  );

  runApp(MindNestApp());
}

class MindNestApp extends StatefulWidget {
  const MindNestApp({super.key});

  @override
  State<MindNestApp> createState() => _MindNestAppState();
}

class _MindNestAppState extends State<MindNestApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen for authentication state changes and handle navigation
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      debugPrint('Auth event: $event');

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            debugPrint('User signed in: ${session.user.email}');
            debugPrint(
              'Email confirmed: ${session.user.emailConfirmedAt != null}',
            );

            // Handle email verification and onboarding navigation
            await _handleSignedInUser(session);
          }
          break;
        case AuthChangeEvent.signedOut:
          debugPrint('User signed out');
          break;
        case AuthChangeEvent.passwordRecovery:
          debugPrint(
            'Password recovery link clicked - user will be redirected to reset form',
          );
          await _handlePasswordRecovery(session);
          break;
        case AuthChangeEvent.tokenRefreshed:
          debugPrint('Token refreshed');
          break;
        default:
          debugPrint('Other auth event: $event');
      }
    });
  }

  Future<void> _handlePasswordRecovery(Session? session) async {
    if (session == null) {
      debugPrint('No session for password recovery');
      return;
    }

    // Get current context
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // Navigate to password reset screen
    Navigator.of(context).pushAndRemoveUntil(
      CustomPageTransitions.slideFromRight<void>(
        PasswordResetScreen(isFromDeepLink: true, resetSession: session),
      ),
      (route) => false,
    );
  }

  Future<void> _handleSignedInUser(Session session) async {
    final user = session.user;

    // Check if email is verified
    if (user.emailConfirmedAt == null) {
      debugPrint('Email not verified, staying on current screen');
      return;
    }

    try {
      // Get user profile to determine role and onboarding status
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, status')
          .eq('id', user.id)
          .single();

      final userRole = profile['role'] as String?;
      final userStatus = profile['status'] as String?;

      debugPrint('User profile: role=$userRole, status=$userStatus');

      // Get current context
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      // Check onboarding status
      final onboarding = await Supabase.instance.client
          .from('user_onboarding')
          .select('progress_percentage')
          .eq('user_id', user.id)
          .maybeSingle();

      final progressPercentage =
          onboarding?['progress_percentage'] as int? ?? 0;

      if (progressPercentage < 100) {
        // Navigate to appropriate onboarding screen
        if (userRole == 'patient') {
          Navigator.of(context).pushAndRemoveUntil(
            CustomPageTransitions.slideFromRight<void>(
              PatientOnboardingScreen(),
            ),
            (route) => false,
          );
        } else if (userRole == 'therapist') {
          Navigator.of(context).pushAndRemoveUntil(
            CustomPageTransitions.slideFromRight<void>(
              TherapistOnboardingScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        // Navigate to home screen
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.fadeTransition<void>(HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error handling signed in user: $e');
      // Default to home screen if there's an error
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.fadeTransition<void>(HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindNest',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // Performance optimizations
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => UserTypeSelectionScreen(),
        '/home': (context) => HomeScreen(),
        '/splash': (context) => SplashScreen(),
        '/reset-password': (context) => PasswordResetScreen(),
      },
    );
  }
}
