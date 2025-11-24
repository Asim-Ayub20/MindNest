import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import 'simple_password_reset_screen.dart';
import 'email_verification_flow_screen.dart';
import '../utils/logo_widget.dart';
import '../utils/input_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
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
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(child: LogoWidget(size: 64)),
                  SizedBox(height: 32),

                  // Welcome text
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign in to continue your journey',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),

                  // Email field
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'your.email@example.com',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),

                  // Password field
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          CustomPageTransitions.slideFromRight<void>(
                            SimplePasswordResetScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Sign In Button
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Create account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/signup');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Crisis support - compact version
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFFECACA), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.crisis_alert,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Need immediate help?',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle crisis resources
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: Color(0xFFDC2626),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Get Help',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
