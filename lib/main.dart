import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'config/supabase_config.dart';
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
import 'screens/email_verification_flow_screen.dart';
import 'utils/page_transitions.dart';
import 'utils/app_theme.dart';

// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Parallel initialization for faster startup
  await Future.wait([
    // Performance optimizations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),

    // Initialize Supabase
    _initializeSupabase(),
  ]);

  // Set system UI overlay style (non-async, can be done separately)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MindNestApp());
}

Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: SupabaseConfig.debugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }
}

class MindNestApp extends StatefulWidget {
  const MindNestApp({super.key});

  @override
  State<MindNestApp> createState() => _MindNestAppState();
}

class _MindNestAppState extends State<MindNestApp> {
  late AppLinks _appLinks;
  Widget? _initialScreen;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isHandlingEmailVerification =
      false; // Flag to prevent duplicate navigation

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _initDeepLinks();
    _determineInitialScreen();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _determineInitialScreen() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // Get user and check if they need to complete profile details
        final user = session.user;
        final userRole = user.userMetadata?['role'] ?? 'patient';

        // Parallel database queries for faster loading
        final Future<Map<String, dynamic>?> patientFuture =
            userRole == 'patient'
            ? Supabase.instance.client
                  .from('patients')
                  .select('id')
                  .eq('id', user.id)
                  .maybeSingle()
            : Future.value(null);

        final Future<Map<String, dynamic>?> therapistFuture =
            userRole == 'therapist'
            ? Supabase.instance.client
                  .from('therapists')
                  .select('id')
                  .eq('id', user.id)
                  .maybeSingle()
            : Future.value(null);

        // Wait for data queries to complete
        await Future.wait([
          if (userRole == 'patient') patientFuture,
          if (userRole == 'therapist') therapistFuture,
        ]);

        if (!mounted) return;

        // Check results
        if (userRole == 'patient') {
          final patientDetails = await patientFuture;
          if (patientDetails == null) {
            // Patient hasn't completed profile details
            setState(() {
              _initialScreen = PatientDetailsScreen();
            });
          } else {
            setState(() {
              _initialScreen = PatientDashboardScreen();
            });
          }
        } else if (userRole == 'therapist') {
          final therapistDetails = await therapistFuture;
          if (therapistDetails == null) {
            // Therapist hasn't completed profile details
            setState(() {
              _initialScreen = TherapistDetailsScreen();
            });
          } else {
            setState(() {
              _initialScreen = TherapistDashboardScreen();
            });
          }
        } else {
          setState(() {
            _initialScreen = HomeScreen();
          });
        }
      } else {
        setState(() {
          _initialScreen = LoginScreen();
        });
      }
    } catch (e) {
      debugPrint('Error determining initial screen: $e');
      setState(() {
        _initialScreen = LoginScreen();
      });
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
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

    if (uri.scheme == SupabaseConfig.deepLinkScheme) {
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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
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

    // Prevent duplicate navigation if we're already handling email verification
    if (_isHandlingEmailVerification) {
      debugPrint(
        'Already handling email verification, skipping duplicate navigation',
      );
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
      // 2. User is NOT currently on the EmailVerificationFlowScreen (to avoid duplicate navigation)
      // 3. The current route is null or '/' (not from login screen)
      //
      // NOTE: If user is already on EmailVerificationFlowScreen waiting for verification,
      // we should NOT navigate here - let that screen handle the success transition
      final isNewUserFromEmailVerification =
          progressPercentage == 0 &&
          (currentRoute == null || currentRoute == '/') &&
          user.emailConfirmedAt != null &&
          !EmailVerificationFlowScreen
              .isActive; // Don't navigate if screen is already active

      // Only show email verification success for truly new users from email verification
      // This should realistically only trigger for users who verify from another device
      // or browser and aren't currently on the verification waiting screen
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
              '[MainApp] New user from email verification - showing success screen',
            );

            // Set flag to prevent duplicate handling within a short time window
            _isHandlingEmailVerification = true;

            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                CustomPageTransitions.slideFromRight<void>(
                  EmailVerificationFlowScreen(
                    email: user.email ?? '',
                    userType: userRole,
                  ),
                ),
                (route) => false,
              );
            }

            // Reset flag after screen transition completes
            Future.delayed(const Duration(seconds: 5), () {
              _isHandlingEmailVerification = false;
            });

            return;
          } else {
            debugPrint(
              '[MainApp] User has existing profile data, skipping email verification screen',
            );
          }
        } catch (e) {
          debugPrint('[MainApp] Error checking user profile data: $e');
        }
      }

      // If EmailVerificationFlowScreen is currently active, don't auto-navigate
      // Let the user manually click "Continue" from the success screen
      if (EmailVerificationFlowScreen.isActive) {
        debugPrint(
          '[MainApp] EmailVerificationFlowScreen is active - skipping auto-navigation to let user manually proceed',
        );
        return;
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
    // If initial screen is not determined yet, show a placeholder (native splash is still visible)
    if (_initialScreen == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Color(0xFF047857)),
      );
    }

    return MaterialApp(
      title: 'MindNest',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _initialScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => UserTypeSelectionScreen(),
        '/home': (context) => HomeScreen(),
        '/patient-dashboard': (context) => PatientDashboardScreen(),
        '/reset-password': (context) => PasswordResetScreen(),
      },
    );
  }
}
