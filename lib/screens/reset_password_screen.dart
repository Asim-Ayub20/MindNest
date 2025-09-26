import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;

  const ResetPasswordScreen({super.key, this.accessToken, this.refreshToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _setupSession();
  }

  Future<void> _setupSession() async {
    if (widget.accessToken != null && widget.refreshToken != null) {
      try {
        // For password recovery, we should get the session from the current auth state
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          throw Exception('No active session for password reset');
        }
        debugPrint('Session ready for password reset');
      } catch (e) {
        debugPrint('Error with session: $e');
        _showMessage(
          'Invalid or expired reset link. Please request a new one.',
        );
        _navigateToLogin();
      }
    }
  }

  Future<void> _resetPassword() async {
    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    if (newPasswordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPasswordController.text),
      );

      if (response.user != null) {
        // Log the password reset completion
        try {
          await Supabase.instance.client.rpc(
            'log_password_reset',
            params: {
              'user_uuid': response.user!.id,
              'user_email': response.user!.email,
              'reset_type': 'complete',
              'success_status': true,
            },
          );
        } catch (e) {
          debugPrint('Failed to log password reset: $e');
        }

        _showMessage(
          'Password updated successfully! You can now sign in with your new password.',
          isError: false,
        );

        // Sign out and redirect to login
        await Supabase.instance.client.auth.signOut();

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _navigateToLogin();
          }
        });
      }
    } on AuthException catch (error) {
      _showMessage('Failed to update password: ${error.message}');
    } catch (error) {
      _showMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      CustomPageTransitions.slideFromRight<void>(LoginScreen()),
      (route) => false,
    );
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
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF374151)),
          onPressed: _navigateToLogin,
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
        child: SingleChildScrollView(
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
                    color: Color(0xFF8B7CF6),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(Icons.lock_reset, color: Colors.white, size: 40),
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Create New Password',
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
                'Your new password must be different from previously used passwords.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // New Password field
              Text(
                'New Password',
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
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Enter your new password',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
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
                    hintText: 'Confirm your new password',
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
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Password requirements
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• At least 8 characters long\n• Must be different from previous passwords',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Reset password button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B7CF6),
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
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Color(0xFF8B7CF6),
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
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
