import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'patient_dashboard_screen.dart';
import 'patient_details_screen.dart';
import 'therapist_details_screen.dart';
import '../utils/page_transitions.dart';
import '../utils/logo_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _textController;
  late AnimationController _fadeController;

  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartPulseAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for splash screen
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF047857),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Heart animation controller
    _heartController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    // Fade controller for overall screen
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Heart scale animation (grows from 0 to 1)
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    // Heart pulse animation (subtle pulsing effect)
    _heartPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // Text fade animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Text slide animation
    _textSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Background fade animation
    _backgroundFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Start heart animation
    await _heartController.forward();

    // Start text animation after a brief delay
    await Future.delayed(Duration(milliseconds: 200));
    await _textController.forward();

    // Start pulsing heart
    _heartController.repeat(reverse: true);

    // Wait for a total of 3 seconds, then navigate
    await Future.delayed(Duration(milliseconds: 1300));

    // Stop pulsing and fade out
    _heartController.stop();
    await _fadeController.forward();

    // Navigate to appropriate screen
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (mounted) {
        if (session != null) {
          // Get user and check if they need to complete profile details
          final user = session.user;
          final userRole = user.userMetadata?['role'] ?? 'patient';

          // Check if user has completed their profile details
          if (userRole == 'patient') {
            final patientDetails = await Supabase.instance.client
                .from('patients')
                .select('id')
                .eq('id', user.id)
                .maybeSingle();

            if (patientDetails == null) {
              // Patient hasn't completed profile details
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  PatientDetailsScreen(),
                ),
              );
              return;
            }
          } else if (userRole == 'therapist') {
            final therapistDetails = await Supabase.instance.client
                .from('therapists')
                .select('id')
                .eq('id', user.id)
                .maybeSingle();

            if (therapistDetails == null) {
              // Therapist hasn't completed profile details
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  TherapistDetailsScreen(),
                ),
              );
              return;
            }
          }

          // User has completed profile, navigate to appropriate dashboard
          if (userRole == 'patient') {
            Navigator.of(context).pushReplacement(
              CustomPageTransitions.fadeTransition<void>(
                PatientDashboardScreen(),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              CustomPageTransitions.fadeTransition<void>(HomeScreen()),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            CustomPageTransitions.slideFromRight<void>(LoginScreen()),
          );
        }
      }
    } catch (e) {
      // If there's an error, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageTransitions.fadeTransition<void>(LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF047857),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(
          0xFF047857,
        ), // Set scaffold background to match gradient
        body: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _backgroundFadeAnimation.value,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(flex: 2),

                        // Animated heart icon
                        AnimatedBuilder(
                          animation: _heartController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  _heartScaleAnimation.value *
                                  (_heartController.status ==
                                              AnimationStatus.completed ||
                                          _heartController.isAnimating
                                      ? _heartPulseAnimation.value
                                      : 1.0),
                              child: LogoWidget(
                                size: 120,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: 30,
                                assetPath: 'assets/images/logo_large.png',
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 40),

                        // Animated app name and tagline
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _textSlideAnimation,
                              child: FadeTransition(
                                opacity: _textFadeAnimation,
                                child: Column(
                                  children: [
                                    Text(
                                      'MindNest',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Your Mental Wellness Journey',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        Spacer(flex: 2),

                        // Loading indicator
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _textFadeAnimation,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withValues(alpha: 0.8),
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Preparing your sanctuary...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
