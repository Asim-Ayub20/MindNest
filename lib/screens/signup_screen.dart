import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import 'patient_onboarding_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'email_verification_flow_screen.dart';
import '../utils/logo_widget.dart';
import '../widgets/shared_password_input.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, this.userType = 'patient'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SharedPasswordMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> handleSignup() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                // Logo with green background
                LogoWidget(size: 80),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Welcome text
                Text(
                  widget.userType == 'patient'
                      ? 'Join MindNest'
                      : 'Become a Provider',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  widget.userType == 'patient'
                      ? 'Begin your mental wellness journey today'
                      : 'Help others on their mental wellness journey',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Sign Up Card
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
                        widget.userType == 'patient'
                            ? 'Create Your Account'
                            : 'Create Provider Account',
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

                      // Password Input with Requirements
                      SharedPasswordInput(
                        passwordController: passwordController,
                        confirmPasswordController: confirmPasswordController,
                        isPasswordVisible: isPasswordVisible,
                        isConfirmPasswordVisible: isConfirmPasswordVisible,
                        onPasswordVisibilityToggle: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        onConfirmPasswordVisibilityToggle: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                        passwordError: passwordError,
                        onPasswordChanged: onPasswordChanged,
                        onConfirmPasswordChanged: (_) {},
                        passwordHint: 'Create a strong password',
                        confirmPasswordHint: 'Confirm your password',
                        showConfirmPassword: true,
                      ),
                      const SizedBox(height: 24),

                      // Create Account Button
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
                          onPressed: isLoading ? null : handleSignup,
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
                              : Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                // Already have account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
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
    confirmPasswordController.dispose();
    super.dispose();
  }
}
