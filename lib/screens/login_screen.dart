import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import 'password_reset_screen.dart';
import 'email_verification_flow_screen.dart';
import '../utils/input_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool isLoading = false;
  bool isPasswordVisible = false;
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

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    // Validate email format
    final emailValidation = InputValidators.validateEmail(emailController.text);
    if (emailValidation != null) {
      _showMessage(emailValidation);
      return;
    }

    // Basic password validation for login (less strict for existing users)
    if (passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }

    // Warn users with weak passwords to update them
    final passwordValidation = InputValidators.validatePassword(
      passwordController.text,
    );
    if (passwordValidation != null) {
      // Don't block login, but show a warning about password strength
      debugPrint(
        'Password does not meet new security requirements: $passwordValidation',
      );
    }

    setState(() {
      isLoading = true;
    });

    try {
      // First check if login is allowed using database function
      try {
        final loginCheck = await Supabase.instance.client.rpc(
          'app_auth_check',
          params: {
            'user_email': emailController.text.trim(),
            'check_type': 'login',
          },
        );

        debugPrint('Login check result: $loginCheck'); // Debug log

        if (loginCheck['allowed'] == false) {
          final reason = loginCheck['reason'] as String;

          if (reason == 'User not found') {
            _showMessage(
              'No account found with this email. Please sign up first.',
            );
            return;
          } else if (reason == 'Email not verified') {
            final role = loginCheck['role'] as String? ?? 'patient';
            _showMessage(
              'Please verify your email before logging in.',
              isError: false,
            );

            if (mounted) {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  EmailVerificationFlowScreen(
                    email: emailController.text.trim(),
                    userType: role,
                  ),
                ),
              );
            }
            return;
          } else if (reason == 'Account not active') {
            _showMessage('Your account is not active. Please contact support.');
            return;
          }
        }
      } catch (e) {
        debugPrint('Database login check failed: $e');
        // Continue with login attempt even if check fails
      }

      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      if (response.user != null) {
        // Double-check email verification status
        if (response.user!.emailConfirmedAt == null) {
          _showMessage(
            'Please verify your email before logging in.',
            isError: false,
          );
          // Sign out the user since they haven't verified
          await Supabase.instance.client.auth.signOut();

          // Get user role from profile to navigate to verification screen
          try {
            final profile = await Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('email', emailController.text.trim())
                .single();

            if (mounted) {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  EmailVerificationFlowScreen(
                    email: emailController.text.trim(),
                    userType: profile['role'] ?? 'patient',
                  ),
                ),
              );
            }
          } catch (e) {
            // If we can't get the profile, still show verification screen
            if (mounted) {
              Navigator.of(context).pushReplacement(
                CustomPageTransitions.slideFromRight<void>(
                  EmailVerificationFlowScreen(
                    email: emailController.text.trim(),
                    userType: 'patient', // Default fallback
                  ),
                ),
              );
            }
          }
          return;
        }

        // Log successful login
        try {
          await Supabase.instance.client.rpc(
            'log_user_login',
            params: {
              'user_uuid': response.user!.id,
              'login_success': true,
              'ip_addr': null,
              'user_agent_string': null,
              'device_metadata': {},
            },
          );
        } catch (e) {
          // Continue even if logging fails
          debugPrint('Login logging failed: $e');
        }

        // Don't navigate here - let the auth listener handle it
        debugPrint('Login successful, auth listener will handle navigation');
      }
    } on AuthException catch (error) {
      _showMessage('Login failed: ${error.message}');
    } on PostgrestException catch (error) {
      debugPrint('Database error during login: ${error.message}');
      _showMessage(
        'Database connection error. Please check your internet connection and try again.',
      );
    } catch (error) {
      debugPrint('Unexpected error during login: $error');

      String errorMessage = 'An unexpected error occurred. Please try again.';

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
                          SizedBox(height: size.height * 0.03),

                          // Logo and branding
                          _buildLogo(),
                          const SizedBox(height: 12),

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
                              fontSize: 14,
                              color: _warmGray,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Welcome message
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
                              '🌿  Welcome back',
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

                          // Password field
                          _buildTextField(
                            controller: passwordController,
                            focusNode: _passwordFocus,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 6),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  CustomPageTransitions.slideFromRight<void>(
                                    PasswordResetScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: _deepGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign In Button
                          _buildSignInButton(),
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
                                  'new here?',
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

                          // Create account button
                          _buildCreateAccountButton(),
                          const SizedBox(height: 20),

                          // Crisis support
                          _buildCrisisSupport(),
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
        // Subtle leaf pattern overlay
        Positioned(
          top: size.height * 0.15,
          left: 20,
          child: Transform.rotate(
            angle: -0.3,
            child: Icon(
              Icons.eco_outlined,
              size: 24,
              color: _primaryGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          right: 30,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.spa_outlined,
              size: 20,
              color: _primaryGreen.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 70,
      height: 70,
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
          // Inner glow effect
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Logo image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 36,
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
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
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
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _warmGray.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
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

  Widget _buildSignInButton() {
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
          onTap: isLoading ? null : handleLogin,
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
                        'Sign In',
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

  Widget _buildCreateAccountButton() {
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
            Navigator.of(context).pushReplacementNamed('/signup');
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Create an account',
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

  Widget _buildCrisisSupport() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4C9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F6B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              color: Color(0xFFE86C4F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need support now?',
                  style: TextStyle(
                    color: const Color(0xFFB85C3F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We\'re here to help',
                  style: TextStyle(
                    color: const Color(0xFFB85C3F).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE86C4F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Get Help',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
