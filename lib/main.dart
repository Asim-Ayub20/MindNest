import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_type_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/patient_onboarding_screen.dart';
import 'screens/patient_details_screen.dart';
import 'screens/therapist_dashboard_screen.dart';
import 'screens/therapist_onboarding_screen.dart';
import 'screens/therapist_details_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/email_verification_success_screen.dart';
import 'utils/page_transitions.dart';
import 'utils/app_theme.dart';

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

  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: 'https://yqhgsmrtxgfjuljazoie.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxaGdzbXJ0eGdmanVsamF6b2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NTE2ODEsImV4cCI6MjA3NDEyNzY4MX0.Iny6UH4vjesqQyh4sDMcmV58XKgUXDeERImhlKJNcUk',
      debug: false, // Set to false for release builds
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    // App will still launch but with limited functionality
  }

  runApp(MindNestApp());
}

class MindNestApp extends StatefulWidget {
  const MindNestApp({super.key});

  @override
  State<MindNestApp> createState() => _MindNestAppState();
}

class _MindNestAppState extends State<MindNestApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep links when app is already running
    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('Deep link received while app running: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );

    // Handle deep links when app is launched from link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('App launched from deep link: $uri');
        // Delay handling to ensure app is fully initialized
        Future.delayed(Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');

    if (uri.scheme == 'io.supabase.mindnest') {
      if (uri.host == 'login-callback') {
        // This is handled automatically by Supabase
        debugPrint('Email verification link detected');
      } else if (uri.host == 'reset-password') {
        // This is handled by the auth listener
        debugPrint('Password reset link detected');
      }
    }
  }

  void _setupAuthListener() {
    // Listen for authentication state changes and handle navigation
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
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
      },
      onError: (error) {
        debugPrint('Auth state change error: $error');
        // Handle auth errors, particularly expired verification links
        if (error is AuthException) {
          if (error.statusCode == 'otp_expired' ||
              error.message.contains('expired')) {
            debugPrint(
              'Verification link expired - user should request new link',
            );
            // The user will need to request a new verification email
            // from the EmailVerificationScreen
          }
        }
      },
    );
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

      final userRole = profile['role'] as String? ?? 'patient';
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

      // Get current route to determine the navigation context
      final currentRoute = context.mounted
          ? ModalRoute.of(context)?.settings.name
          : null;

      // Check if this is a new user who just verified their email
      // This should only happen when:
      // 1. User has 0% onboarding progress (completely new)
      // 2. User is coming from a deep link (email verification)
      // 3. The current route is null or '/' (not from login screen)
      final isNewUserFromEmailVerification =
          progressPercentage == 0 &&
          (currentRoute == null || currentRoute == '/') &&
          user.emailConfirmedAt != null;

      // Only show email verification success for truly new users from email verification
      // Not for existing users logging in from the login screen
      if (isNewUserFromEmailVerification) {
        // Double-check this is really a new user by checking if they have any profile data
        try {
          final hasPatientData = userRole == 'patient'
              ? await Supabase.instance.client
                    .from('patients')
                    .select('id')
                    .eq('id', user.id)
                    .maybeSingle()
              : null;

          final hasTherapistData = userRole == 'therapist'
              ? await Supabase.instance.client
                    .from('therapists')
                    .select('id')
                    .eq('id', user.id)
                    .maybeSingle()
              : null;

          // If user has no profile data and no onboarding progress, they're truly new
          if (hasPatientData == null && hasTherapistData == null) {
            debugPrint(
              'New user from email verification - showing success screen',
            );
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                CustomPageTransitions.slideFromRight<void>(
                  EmailVerificationSuccessScreen(
                    email: user.email ?? '',
                    userType: userRole,
                  ),
                ),
                (route) => false,
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('Error checking user profile data: $e');
        }
      }

      // Check if context is still mounted before navigation
      if (!context.mounted) return;

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
        // Check if patient needs to complete profile details
        if (userRole == 'patient') {
          final patientDetails = await Supabase.instance.client
              .from('patients')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (patientDetails == null) {
            // Patient hasn't completed profile details, redirect to PatientDetailsScreen
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                CustomPageTransitions.slideFromRight<void>(
                  PatientDetailsScreen(),
                ),
                (route) => false,
              );
            }
            return;
          }
        } else if (userRole == 'therapist') {
          final therapistDetails = await Supabase.instance.client
              .from('therapists')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (therapistDetails == null) {
            // Therapist hasn't completed profile details, redirect to TherapistDetailsScreen
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                CustomPageTransitions.slideFromRight<void>(
                  TherapistDetailsScreen(),
                ),
                (route) => false,
              );
            }
            return;
          }
        }

        // Navigate to appropriate home screen based on user role
        if (context.mounted) {
          if (userRole == 'patient') {
            Navigator.of(context).pushAndRemoveUntil(
              CustomPageTransitions.fadeTransition<void>(
                PatientDashboardScreen(),
              ),
              (route) => false,
            );
          } else if (userRole == 'therapist') {
            // For therapists, use the TherapistDashboardScreen
            Navigator.of(context).pushAndRemoveUntil(
              CustomPageTransitions.fadeTransition<void>(
                TherapistDashboardScreen(),
              ),
              (route) => false,
            );
          } else {
            // For admins and other roles, use the existing HomeScreen
            Navigator.of(context).pushAndRemoveUntil(
              CustomPageTransitions.fadeTransition<void>(HomeScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling signed in user: $e');
      // Default to appropriate screen based on user role if available
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Try to get user role from current session
        final user = Supabase.instance.client.auth.currentUser;
        final userRole = user?.userMetadata?['role'] ?? 'patient';

        if (userRole == 'patient') {
          Navigator.of(context).pushAndRemoveUntil(
            CustomPageTransitions.fadeTransition<void>(
              PatientDashboardScreen(),
            ),
            (route) => false,
          );
        } else if (userRole == 'therapist') {
          Navigator.of(context).pushAndRemoveUntil(
            CustomPageTransitions.fadeTransition<void>(
              TherapistDashboardScreen(),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            CustomPageTransitions.fadeTransition<void>(HomeScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindNest',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => UserTypeSelectionScreen(),
        '/home': (context) => HomeScreen(),
        '/patient-dashboard': (context) => PatientDashboardScreen(),
        '/splash': (context) => SplashScreen(),
        '/reset-password': (context) => PasswordResetScreen(),
      },
    );
  }
}
