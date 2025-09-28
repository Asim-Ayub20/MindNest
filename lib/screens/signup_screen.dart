import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import 'patient_onboarding_screen.dart';
import 'therapist_onboarding_screen.dart';
import 'email_verification_screen.dart';
import '../utils/logo_widget.dart';
import '../utils/input_validators.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, this.userType = 'patient'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? passwordError;

  Future<void> handleSignup() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    // Validate password complexity
    final passwordValidation = InputValidators.validatePassword(
      passwordController.text,
    );
    if (passwordValidation != null) {
      _showMessage(passwordValidation);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Skip complex validation and go straight to signup for better performance
      // Let Supabase handle duplicate email validation
      debugPrint('Starting optimized signup process');

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
                EmailVerificationScreen(
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
      if (error.message.contains('already registered')) {
        _showMessage(
          'This email is already registered. Please sign in instead.',
        );
      } else {
        _showMessage('Signup failed: ${error.message}');
      }
    } catch (error) {
      debugPrint('Unexpected error during signup: $error');
      _showMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _validatePassword() {
    setState(() {
      passwordError = InputValidators.validatePassword(passwordController.text);
    });
  }

  Widget _buildRequirementItem(String requirement, bool isMet) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Color(0xFF10B981) : Color(0xFF9CA3AF),
            size: 12,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: isMet ? Color(0xFF059669) : Color(0xFF6B7280),
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
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
                          onChanged: (value) => _validatePassword(),
                          decoration: InputDecoration(
                            hintText: 'Create a strong password',
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
                        ),
                      ),
                      SizedBox(height: 20),

                      // Confirm Password field
                      Text(
                        'Confirm Password',
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
                          controller: confirmPasswordController,
                          obscureText: !isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                setState(() {
                                  isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Password requirements and validation
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              passwordError == null &&
                                  passwordController.text.isNotEmpty
                              ? Color(0xFFF0FDF4) // Green background when valid
                              : Color(0xFFF0F9FF), // Blue background by default
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                passwordError == null &&
                                    passwordController.text.isNotEmpty
                                ? Color(0xFFBBF7D0) // Green border when valid
                                : Color(0xFFBFDBFE), // Blue border by default
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  passwordError == null &&
                                          passwordController.text.isNotEmpty
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline,
                                  color:
                                      passwordError == null &&
                                          passwordController.text.isNotEmpty
                                      ? Color(0xFF10B981)
                                      : Color(0xFF3B82F6),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          passwordError == null &&
                                              passwordController.text.isNotEmpty
                                          ? Color(0xFF059669)
                                          : Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildRequirementItem(
                              'At least 8 characters',
                              passwordController.text.length >= 8,
                            ),
                            _buildRequirementItem(
                              'Contains letters (A-Z or a-z)',
                              RegExp(
                                r'[a-zA-Z]',
                              ).hasMatch(passwordController.text),
                            ),
                            _buildRequirementItem(
                              'Contains numbers (0-9)',
                              RegExp(
                                r'[0-9]',
                              ).hasMatch(passwordController.text),
                            ),
                            _buildRequirementItem(
                              'Contains special characters (!@#\$%^&*)',
                              RegExp(
                                r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]',
                              ).hasMatch(passwordController.text),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

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
