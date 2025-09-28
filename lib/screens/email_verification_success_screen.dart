import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import 'patient_onboarding_screen.dart';
import 'patient_details_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'therapist_details_screen.dart';
import 'home_screen.dart';
import 'patient_dashboard_screen.dart';

class EmailVerificationSuccessScreen extends StatefulWidget {
  final String email;
  final String userType;

  const EmailVerificationSuccessScreen({
    super.key,
    required this.email,
    required this.userType,
  });

  @override
  State<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends State<EmailVerificationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _iconAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });

    // Auto-navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user profile and onboarding status
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, status')
          .eq('id', user.id)
          .single();

      final userRole = profile['role'] as String?;

      final onboarding = await Supabase.instance.client
          .from('user_onboarding')
          .select('progress_percentage')
          .eq('user_id', user.id)
          .maybeSingle();

      final progressPercentage =
          onboarding?['progress_percentage'] as int? ?? 0;

      if (!mounted) return;

      if (progressPercentage < 100) {
        // Navigate to appropriate onboarding screen
        if (userRole == 'patient') {
          Navigator.of(context).pushReplacement(
            CustomPageTransitions.slideFromRight<void>(
              PatientOnboardingScreen(),
            ),
          );
        } else if (userRole == 'therapist') {
          Navigator.of(context).pushReplacement(
            CustomPageTransitions.slideFromRight<void>(
              TherapistOnboardingScreen(),
            ),
          );
        }
      } else {
        // Check if user needs to complete profile details
        if (userRole == 'patient') {
          final patientDetails = await Supabase.instance.client
              .from('patients')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (patientDetails == null) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  PatientDetailsScreen(),
                ),
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
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  TherapistDetailsScreen(),
                ),
              );
            }
            return;
          }
        }

        // Navigate to appropriate home screen based on user role
        if (context.mounted) {
          if (widget.userType == 'patient') {
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
        }
      }
    } catch (e) {
      debugPrint('Error navigating after email verification: $e');
      // Default to appropriate home screen based on user type
      if (mounted) {
        if (widget.userType == 'patient') {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated success icon
                    ScaleTransition(
                      scale: _iconAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Animated content
                    FadeTransition(
                      opacity: _contentAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_contentAnimation),
                        child: Column(
                          children: [
                            // Success title
                            const Text(
                              'Email Verified!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Success message
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Welcome to MindNest! Your email ',
                                  ),
                                  TextSpan(
                                    text: widget.email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ' has been successfully verified.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        'Let\'s continue setting up your ${widget.userType} profile.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Loading indicator
                            const Column(
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Preparing your experience...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue button (optional - user can tap to skip waiting)
              FadeTransition(
                opacity: _contentAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigateToNextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
