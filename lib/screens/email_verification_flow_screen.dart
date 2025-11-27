import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_helpers.dart';
import '../utils/page_transitions.dart';
import 'patient_onboarding_screen.dart';
import 'patient_details_screen.dart';
import 'patient_dashboard_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'therapist_details_screen.dart';
import 'home_screen.dart';

/// A unified email verification screen that handles both the verification waiting state
/// and the success state with navigation to the appropriate next screen.
class EmailVerificationFlowScreen extends StatefulWidget {
  final String email;
  final String userType; // 'patient' or 'therapist'

  // Static flag to track if an instance is currently active
  static bool _isCurrentlyActive = false;

  const EmailVerificationFlowScreen({
    super.key,
    required this.email,
    required this.userType,
  });

  // Static method to check if screen is currently displayed
  static bool get isActive => _isCurrentlyActive;

  @override
  State<EmailVerificationFlowScreen> createState() =>
      _EmailVerificationFlowScreenState();
}

class _EmailVerificationFlowScreenState
    extends State<EmailVerificationFlowScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  bool _isVerified = false;
  late AnimationController _successAnimationController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Mark this screen as active
    EmailVerificationFlowScreen._isCurrentlyActive = true;
    debugPrint('[EmailVerificationFlowScreen] Screen is now active');

    _initializeAnimations();
    _listenForVerification();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successScaleAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    );

    _successFadeAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // Mark this screen as inactive when disposed
    EmailVerificationFlowScreen._isCurrentlyActive = false;
    debugPrint('[EmailVerificationFlowScreen] Screen is now inactive');

    _authSubscription?.cancel();
    _successAnimationController.dispose();
    super.dispose();
  }

  void _listenForVerification() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      // Only handle signedIn events with confirmed email
      if (data.event == AuthChangeEvent.signedIn &&
          data.session?.user.emailConfirmedAt != null) {
        debugPrint(
          '[EmailVerificationFlowScreen] Email verified successfully!',
        );
        _handleSuccessfulVerification();
      }
    });
  }

  Future<void> _handleSuccessfulVerification() async {
    // Prevent duplicate handling
    if (!mounted || _isVerified) {
      debugPrint(
        '[EmailVerificationFlowScreen] Already verified or not mounted, skipping',
      );
      return;
    }

    debugPrint(
      '[EmailVerificationFlowScreen] Handling successful verification',
    );

    setState(() {
      _isVerified = true;
    });

    // Start success animation
    _successAnimationController.forward();

    // User must manually click the "Continue" button to proceed
    // No automatic navigation
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || !mounted) return;

      // Fetch user profile and onboarding status
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

      // Navigate based on onboarding progress
      if (progressPercentage < 100) {
        _navigateToOnboarding(userRole);
      } else {
        await _navigateToDetailsOrDashboard(user.id, userRole);
      }
    } catch (e) {
      debugPrint('Error navigating after email verification: $e');
      if (mounted) {
        _navigateToDefaultScreen();
      }
    }
  }

  void _navigateToOnboarding(String? userRole) {
    final Widget targetScreen = userRole == 'patient'
        ? PatientOnboardingScreen()
        : TherapistOnboardingScreen();

    Navigator.of(
      context,
    ).pushReplacement(CustomPageTransitions.slideFromRight<void>(targetScreen));
  }

  Future<void> _navigateToDetailsOrDashboard(
    String userId,
    String? userRole,
  ) async {
    if (userRole == 'patient') {
      final patientDetails = await Supabase.instance.client
          .from('patients')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (patientDetails == null && mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageTransitions.slideFromRight<void>(PatientDetailsScreen()),
        );
        return;
      }
    } else if (userRole == 'therapist') {
      final therapistDetails = await Supabase.instance.client
          .from('therapists')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (therapistDetails == null && mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageTransitions.slideFromRight<void>(TherapistDetailsScreen()),
        );
        return;
      }
    }

    // Navigate to dashboard
    if (mounted) {
      _navigateToDefaultScreen();
    }
  }

  void _navigateToDefaultScreen() {
    final Widget targetScreen = widget.userType == 'patient'
        ? PatientDashboardScreen()
        : HomeScreen();

    Navigator.of(
      context,
    ).pushReplacement(CustomPageTransitions.fadeTransition<void>(targetScreen));
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      await Supabase.instance.client.auth
          .resend(
            type: OtpType.signup,
            email: widget.email,
            emailRedirectTo: 'io.supabase.mindnest://login-callback/',
          )
          .timeout(const Duration(seconds: 10));

      _showMessage(
        'Verification email sent! Please check your inbox and spam folder.',
        isError: false,
      );
    } on AuthException catch (error) {
      debugPrint('Resend error: ${error.message}');
      _showMessage('Failed to resend email: ${error.message}');
    } catch (error) {
      debugPrint('Resend timeout/error: $error');
      _showMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isVerified ? _buildSuccessView() : _buildVerificationView(),
        ),
      ),
    );
  }

  Widget _buildVerificationView() {
    return SingleChildScrollView(
      key: const ValueKey('verification'),
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewPadding.top -
              MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              _buildEmailIcon(),
              const SizedBox(height: 32),
              _buildVerificationTitle(),
              const SizedBox(height: 16),
              _buildVerificationMessage(),
              const SizedBox(height: 40),
              _buildResendButton(),
              const SizedBox(height: 16),
              _buildHelpText(),
              const SizedBox(height: 60),
              _buildBackToLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: 40),
                _buildSuccessContent(),
              ],
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildEmailIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(Icons.email_outlined, color: Colors.white, size: 50),
    );
  }

  Widget _buildVerificationTitle() {
    return const Text(
      'Check your email',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVerificationMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'We sent a verification link to\n'),
            TextSpan(
              text: widget.email,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
            const TextSpan(
              text:
                  '\n\nClick the link in your email to verify your account and continue with your ',
            ),
            TextSpan(
              text: widget.userType,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' registration.'),
          ],
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isResending ? null : _resendVerificationEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFFE5E7EB),
        ),
        child: _isResending
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Resend verification email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildHelpText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        'Didn\'t receive the email? Check your spam folder or try resending.',
        style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Back to Sign In',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _successScaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return FadeTransition(
      opacity: _successFadeAnimation,
      child: Column(
        children: [
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
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Welcome to MindNest! Your email '),
                TextSpan(
                  text: widget.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const TextSpan(text: ' has been successfully verified.\n\n'),
                TextSpan(
                  text:
                      'Let\'s continue setting up your ${widget.userType} profile.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return FadeTransition(
      opacity: _successFadeAnimation,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
