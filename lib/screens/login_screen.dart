import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import 'simple_password_reset_screen.dart';
import 'email_verification_screen.dart';
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
                  EmailVerificationScreen(
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
                  EmailVerificationScreen(
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
                  EmailVerificationScreen(
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
    } catch (error) {
      _showMessage('An unexpected error occurred');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewPadding.top -
                  MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                // Logo with green background
                LogoWidget(size: 80),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Welcome text
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Continue your mental wellness journey',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Sign In Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Email field
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Password field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Forgot password button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                CustomPageTransitions.slideFromRight<void>(
                                  SimplePasswordResetScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Sign In Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                                    strokeWidth: 2,
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
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Create account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to MindNest? ',
                      style: TextStyle(color: Color(0xFF6B7280)),
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
                        'Create account',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),

                // Crisis support section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFFECACA)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'In Crisis?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get immediate support',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Handle crisis resources
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFDC2626),
                          elevation: 0,
                          side: BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Crisis Resources',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
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
