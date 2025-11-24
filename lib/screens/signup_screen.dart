import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import 'patient_onboarding_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'email_verification_flow_screen.dart';
import '../utils/logo_widget.dart';
import '../widgets/shared_password_input.dart';
import '../utils/input_validators.dart';

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
                    widget.userType == 'patient'
                        ? 'Join MindNest'
                        : 'Become a Provider',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.userType == 'patient'
                        ? 'Begin your mental wellness journey'
                        : 'Help others on their wellness journey',
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
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                    passwordError: passwordError,
                    onPasswordChanged: onPasswordChanged,
                    onConfirmPasswordChanged: (_) {},
                    passwordHint: 'Create a strong password',
                    confirmPasswordHint: 'Confirm your password',
                    showConfirmPassword: true,
                  ),
                  SizedBox(height: 24),

                  // Create Account Button
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
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Create Account',
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

                  // Already have account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign In',
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
    confirmPasswordController.dispose();
    super.dispose();
  }
}
