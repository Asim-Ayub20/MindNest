import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import 'patient_onboarding_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'email_verification_flow_screen.dart';
import '../widgets/shared_password_input.dart';
import '../utils/input_validators.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, this.userType = 'patient'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin, SharedPasswordMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  Future<void> handleSignup() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    // Validate email format
    final emailValidation = InputValidators.validateEmail(emailController.text);
    if (emailValidation != null) {
      _showMessage(emailValidation);
      return;
    }

    // Use shared password validation
    final passwordValidation = SharedPasswordValidator.validatePasswordComplete(
      passwordController.text,
      confirmPasswordController.text,
    );
    if (passwordValidation != null) {
      _showMessage(passwordValidation);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if email already exists in profiles table with role information
      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('id, email, role')
          .eq('email', emailController.text.trim().toLowerCase())
          .maybeSingle();

      if (existingUser != null) {
        final existingRole = existingUser['role'] as String;
        final currentRole = widget.userType;

        if (existingRole == currentRole) {
          _showMessage(
            'This email is already registered as a $existingRole account. Please sign in instead.',
          );
        } else {
          _showMessage(
            'This email is already registered as a $existingRole account. Please use a different email or sign in to your existing $existingRole account.',
          );
        }

        setState(() {
          isLoading = false;
        });
        return;
      }

      debugPrint('Starting signup process for new email');

      final AuthResponse response = await Supabase.instance.client.auth
          .signUp(
            email: emailController.text.trim(),
            password: passwordController.text,
            data: {
              'full_name': emailController.text.split('@')[0],
              'role': widget.userType,
            },
            emailRedirectTo: 'io.supabase.mindnest://login-callback/',
          )
          .timeout(Duration(seconds: 15)); // Add timeout

      debugPrint('Signup response received: ${response.user?.email}');

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          _showMessage(
            'Account created! Please check your email to verify your account.',
            isError: false,
          );
          // Navigate to email verification screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              CustomPageTransitions.slideFromRight<void>(
                EmailVerificationFlowScreen(
                  email: emailController.text.trim(),
                  userType: widget.userType,
                ),
              ),
            );
          }
        } else {
          _showMessage('Account created! Welcome to MindNest!', isError: false);
          if (mounted) {
            // Navigate to appropriate onboarding based on user type
            if (widget.userType == 'patient') {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  PatientOnboardingScreen(),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  TherapistOnboardingScreen(),
                ),
              );
            }
          }
        }
      }
    } on AuthException catch (error) {
      debugPrint('AuthException during signup: ${error.message}');
      // Note: Email conflicts should be caught before this point
      // This handles other auth errors like weak passwords, etc.
      _showMessage('Signup failed: ${error.message}');
    } on PostgrestException catch (error) {
      debugPrint('Database error during signup: ${error.message}');
      _showMessage(
        'Database connection error. Please check your internet connection and try again.',
      );
    } catch (error) {
      debugPrint('Unexpected error during signup: $error');

      String errorMessage =
          'Network error. Please check your connection and try again.';

      // Provide more specific error messages
      if (error.toString().contains('SocketException') ||
          error.toString().contains('Network is unreachable') ||
          error.toString().contains('No route to host')) {
        errorMessage =
            'No internet connection. Please check your network settings and try again.';
      } else if (error.toString().contains('TimeoutException') ||
          error.toString().contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection and try again.';
      } else if (error.toString().contains('HandshakeException') ||
          error.toString().contains('certificate')) {
        errorMessage =
            'SSL connection error. Please check your network settings.';
      }

      _showMessage(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPatient = widget.userType == 'patient';

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
                child: SingleChildScrollView(
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
                          SizedBox(height: size.height * 0.02),

                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildBackButton(),
                          ),
                          const SizedBox(height: 12),

                          // Logo and branding
                          _buildLogo(),
                          const SizedBox(height: 10),

                          // App name
                          Text(
                            'MindNest',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: _darkText,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Your sanctuary for mental wellness',
                            style: TextStyle(
                              fontSize: 13,
                              color: _warmGray,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Welcome message based on user type
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              isPatient
                                  ? '🌱  Begin your journey'
                                  : '💚  Help others heal',
                              style: TextStyle(
                                fontSize: 13,
                                color: _deepGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          _buildTextField(
                            controller: emailController,
                            focusNode: _emailFocus,
                            hintText: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          // Password fields with custom styling
                          _buildPasswordSection(),
                          const SizedBox(height: 20),

                          // Create Account Button
                          _buildCreateAccountButton(),
                          const SizedBox(height: 20),

                          // Divider with text
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _warmGray.withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'already a member?',
                                  style: TextStyle(
                                    color: _warmGray.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _warmGray.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sign in button
                          _buildSignInButton(),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
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
              Icons.spa_outlined,
              size: 24,
              color: _primaryGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.22,
          right: 30,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.local_florist_outlined,
              size: 20,
              color: _primaryGreen.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _darkText.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(14),
          child: Icon(Icons.arrow_back_rounded, color: _deepGreen, size: 22),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 32,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _darkText.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword
            ? (isConfirmPassword
                  ? !isConfirmPasswordVisible
                  : !isPasswordVisible)
            : false,
        keyboardType: keyboardType,
        onChanged: isPassword && !isConfirmPassword ? onPasswordChanged : null,
        style: TextStyle(
          color: _darkText,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: _warmGray.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: _primaryGreen, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      (isConfirmPassword
                              ? isConfirmPasswordVisible
                              : isPasswordVisible)
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _warmGray.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        } else {
                          isPasswordVisible = !isPasswordVisible;
                        }
                      });
                    },
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _lightGray, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password field
        _buildTextField(
          controller: passwordController,
          focusNode: _passwordFocus,
          hintText: 'Create a password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 8),

        // Password strength indicators
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: 12),

        // Confirm password field
        _buildTextField(
          controller: confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          hintText: 'Confirm your password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isConfirmPassword: true,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lightGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRequirementChip('8+ chars', hasMinLength),
              _buildRequirementChip('Uppercase', hasUppercase),
              _buildRequirementChip('Lowercase', hasLowercase),
              _buildRequirementChip('Number', hasNumber),
              _buildRequirementChip('Special', hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementChip(String label, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet
            ? _primaryGreen.withValues(alpha: 0.1)
            : _warmGray.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMet
              ? _primaryGreen.withValues(alpha: 0.3)
              : _warmGray.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: isMet ? _deepGreen : _warmGray.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isMet ? _deepGreen : _warmGray.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
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
          onTap: isLoading ? null : handleSignup,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
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
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 46,
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
            Navigator.of(context).pushReplacementNamed('/login');
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Sign in instead',
              style: TextStyle(
                color: _deepGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
