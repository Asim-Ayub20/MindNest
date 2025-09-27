import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimplePasswordResetScreen extends StatefulWidget {
  const SimplePasswordResetScreen({super.key});

  @override
  State<SimplePasswordResetScreen> createState() =>
      _SimplePasswordResetScreenState();
}

class _SimplePasswordResetScreenState extends State<SimplePasswordResetScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendPasswordReset() async {
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
      // Check if password reset is allowed using database function
      try {
        final resetCheck = await Supabase.instance.client.rpc(
          'app_auth_check',
          params: {
            'user_email': emailController.text.trim(),
            'check_type': 'password_reset',
          },
        );

        debugPrint('Password reset check result: $resetCheck'); // Debug log

        if (resetCheck['allowed'] == false) {
          setState(() {
            isLoading = false;
          });

          final reason = resetCheck['reason'] as String;
          if (reason == 'User not found') {
            _showMessage('No account found with this email address');
          } else if (reason == 'Email not verified') {
            _showMessage(
              'Please verify your email address first before resetting password',
            );
          } else {
            _showMessage('Unable to reset password: $reason');
          }
          return;
        }
      } catch (e) {
        debugPrint('Database reset check failed: $e');
        // Continue with reset attempt even if check fails
      }

      // Send password reset email
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
        redirectTo: 'io.supabase.mindnest://reset-password',
      );

      // Log the password reset request
      try {
        await Supabase.instance.client.rpc(
          'request_password_reset',
          params: {
            'user_email': emailController.text.trim(),
            'user_ip': null,
            'user_agent_string': null,
          },
        );
      } catch (e) {
        debugPrint('Failed to log password reset request: $e');
        // Continue anyway
      }

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Password reset email sent! Please check your inbox and follow the instructions.',
        isError: false,
      );

      // Navigate back after showing message
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } on AuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('Failed to send reset email: ${error.message}');
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('An unexpected error occurred. Please try again.');
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
        duration: Duration(seconds: isError ? 4 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF374151)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(Icons.lock_reset, color: Colors.white, size: 40),
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Forgot your password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Enter your email address and we\'ll send you instructions to reset your password.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Email field
              Text(
                'Email Address',
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
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: 32),

              // Send reset button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendPasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Color(0xFFE5E7EB),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Send Reset Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              Spacer(),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
