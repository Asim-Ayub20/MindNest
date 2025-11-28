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
  late AnimationController _animationController;
  late AnimationController _successAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;
  StreamSubscription<AuthState>? _authSubscription;

  // Mental wellness color palette
  static const Color _primaryGreen = Color(0xFF7CB69D);
  static const Color _deepGreen = Color(0xFF5A9A7F);
  static const Color _softCream = Color(0xFFFAF9F6);
  static const Color _warmGray = Color(0xFF6B7280);
  static const Color _darkText = Color(0xFF2D3436);
  static const Color _lightGray = Color(0xFFF3F4F6);

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
    // Main entrance animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();

    // Success animation
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
    _animationController.dispose();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _softCream,
      body: Stack(
        children: [
          // Background decorative elements
          _buildBackgroundDecoration(size),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isVerified
                      ? _buildSuccessView()
                      : _buildVerificationView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(Size size) {
    return Stack(
      children: [
        // Top right soft circle
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryGreen.withValues(alpha: 0.15),
                  _primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom left soft circle
        Positioned(
          bottom: -size.width * 0.4,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _deepGreen.withValues(alpha: 0.08),
                  _deepGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Subtle nature icons
        Positioned(
          top: size.height * 0.12,
          left: 20,
          child: Transform.rotate(
            angle: -0.3,
            child: Icon(
              Icons.mail_outline_rounded,
              size: 24,
              color: _primaryGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.2,
          right: 30,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 20,
              color: _primaryGreen.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.25,
          left: 40,
          child: Transform.rotate(
            angle: 0.2,
            child: Icon(
              Icons.spa_outlined,
              size: 18,
              color: _deepGreen.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationView() {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      key: const ValueKey('verification'),
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.06),
              _buildEmailIcon(),
              const SizedBox(height: 20),
              _buildVerificationTitle(),
              const SizedBox(height: 12),
              _buildVerificationMessage(),
              const SizedBox(height: 24),
              _buildResendButton(),
              const SizedBox(height: 12),
              _buildHelpText(),
              const SizedBox(height: 24),
              _buildBackToLoginButton(),
              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final size = MediaQuery.of(context).size;

    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: 24),
                _buildSuccessContent(),
              ],
            ),
          ),
          _buildContinueButton(),
          SizedBox(height: size.height * 0.04),
        ],
      ),
    );
  }

  Widget _buildEmailIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 36),
        ],
      ),
    );
  }

  Widget _buildVerificationTitle() {
    return Column(
      children: [
        Text(
          'Check your email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: _darkText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '📧  Verification link sent',
            style: TextStyle(
              fontSize: 13,
              color: _deepGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: _darkText.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: _warmGray, height: 1.5),
              children: [
                const TextSpan(text: 'We sent a verification link to\n'),
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _deepGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.userType == 'patient'
                      ? Icons.person_outline_rounded
                      : Icons.psychology_outlined,
                  size: 16,
                  color: _warmGray,
                ),
                const SizedBox(width: 6),
                Text(
                  'Registering as ${widget.userType}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _warmGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isResending
              ? [_lightGray, _lightGray]
              : [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isResending
            ? null
            : [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isResending ? null : _resendVerificationEmail,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isResending
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_warmGray),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Resend verification email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: _primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Check your spam folder if you don\'t see the email.',
              style: TextStyle(fontSize: 13, color: _warmGray, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, color: _deepGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: _deepGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _successScaleAnimation,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryGreen, _deepGreen],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return FadeTransition(
      opacity: _successFadeAnimation,
      child: Column(
        children: [
          Text(
            'Email Verified!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: _darkText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✨  Welcome to MindNest',
              style: TextStyle(
                fontSize: 13,
                color: _deepGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightGray, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _darkText.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  widget.userType == 'patient'
                      ? Icons.spa_outlined
                      : Icons.psychology_outlined,
                  size: 32,
                  color: _primaryGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.userType == 'patient'
                      ? 'Your journey to wellness begins now'
                      : 'Ready to make a difference',
                  style: TextStyle(
                    fontSize: 15,
                    color: _darkText,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up your ${widget.userType} profile.',
                  style: TextStyle(fontSize: 13, color: _warmGray),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return FadeTransition(
      opacity: _successFadeAnimation,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryGreen, _deepGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToNextScreen,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
