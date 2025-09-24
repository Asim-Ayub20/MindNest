import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import 'home_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isOtpMode = false;
  String maskedEmail = '';

  // Utility function to mask email
  String maskEmail(String email) {
    if (email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${username.substring(0, 1)}***@$domain';
    } else {
      return '${username.substring(0, 3)}***@$domain';
    }
  }

  Future<void> handleOtpLogin() async {
    if (!isOtpMode) {
      // Switch to OTP mode and send OTP
      await _sendOTP();
    } else {
      // Verify OTP and login
      await _verifyOTP();
    }
  }

  Future<void> _sendOTP() async {
    if (emailController.text.isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text)) {
      _showMessage('Please enter a valid email address');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();

      // Use signInWithOtp with shouldCreateUser: false to only allow existing users
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'mindnest://login',
        shouldCreateUser: false, // This prevents auto-signup
      );

      setState(() {
        maskedEmail = maskEmail(email);
        isOtpMode = true;
        isLoading = false;
      });

      _showMessage('Verification code sent to your email', isError: false);
    } on AuthException catch (error) {
      setState(() {
        isLoading = false;
      });

      if (error.message.contains('Signup not allowed') ||
          error.message.contains('User not found') ||
          error.message.contains('Invalid login credentials')) {
        _showMessage(
          'No account found with this email address. Please sign up first.',
        );
      } else {
        _showMessage('Failed to send verification code: ${error.message}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _verifyOTP() async {
    if (otpController.text.isEmpty) {
      _showMessage('Please enter the verification code');
      return;
    }

    if (otpController.text.length != 6) {
      _showMessage('Verification code must be 6 digits');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .verifyOTP(
            token: otpController.text.trim(),
            type: OtpType.email,
            email: emailController.text.trim(),
          );

      if (response.user != null) {
        setState(() {
          isLoading = false;
        });

        _showMessage('Login successful!', isError: false);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            CustomPageTransitions.fadeTransition<void>(HomeScreen()),
          );
        }
      }
    } on AuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('Invalid verification code: ${error.message}');
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          _showMessage('Please verify your email before logging in');
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            CustomPageTransitions.fadeTransition<void>(HomeScreen()),
          );
        }
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
                // Heart Icon with purple background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B7CF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.favorite, color: Colors.white, size: 40),
                ),
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

                      // Dynamic password/OTP field
                      Text(
                        isOtpMode ? 'Verification Code' : 'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (isOtpMode && maskedEmail.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: 'Code sent to '),
                                TextSpan(
                                  text: maskedEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B7CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: isOtpMode
                              ? otpController
                              : passwordController,
                          obscureText: isOtpMode ? false : !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: isOtpMode
                                ? 'Enter 6-digit code'
                                : 'Enter your password',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: isOtpMode
                                ? null
                                : IconButton(
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
                          keyboardType: isOtpMode
                              ? TextInputType.number
                              : TextInputType.text,
                          maxLength: isOtpMode ? 6 : null,
                          buildCounter: isOtpMode
                              ? (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Dynamic button options based on mode
                      if (isOtpMode)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      await _sendOTP();
                                    },
                              child: Text(
                                'Resend code',
                                style: TextStyle(
                                  color: Color(0xFF8B7CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        isOtpMode = false;
                                        otpController.clear();
                                        maskedEmail = '';
                                      });
                                    },
                              child: Text(
                                'Use password instead',
                                style: TextStyle(
                                  color: Color(0xFF8B7CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  CustomPageTransitions.slideFromRight<void>(
                                    PasswordResetScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Color(0xFF8B7CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      await handleOtpLogin();
                                    },
                              child: Text(
                                'Use OTP instead',
                                style: TextStyle(
                                  color: Color(0xFF8B7CF6),
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
                            colors: [Color(0xFF8B7CF6), Color(0xFF7C3AED)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : (isOtpMode ? _verifyOTP : handleLogin),
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
                          color: Color(0xFF8B7CF6),
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
    otpController.dispose();
    super.dispose();
  }
}
