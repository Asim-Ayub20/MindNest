import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/input_validators.dart';

// Reset flow states
enum ResetState { email, otp, newPassword, tokenReset }

class PasswordResetScreen extends StatefulWidget {
  final bool isFromDeepLink;
  final Session? resetSession;

  const PasswordResetScreen({
    super.key,
    this.isFromDeepLink = false,
    this.resetSession,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? passwordError;

  ResetState currentState = ResetState.email;

  String userEmail = '';
  String maskedEmail = '';

  @override
  void initState() {
    super.initState();
    // If opened from deep link, go directly to token reset
    if (widget.isFromDeepLink && widget.resetSession != null) {
      currentState = ResetState.tokenReset;
      userEmail = widget.resetSession!.user.email ?? '';
    }
  }

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

  void _validatePassword() {
    setState(() {
      passwordError = InputValidators.validatePassword(
        newPasswordController.text,
      );
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
      // Check if user exists first
      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('email')
          .eq('email', emailController.text.trim())
          .limit(1);

      if (existingUser.isEmpty) {
        setState(() {
          isLoading = false;
        });
        _showMessage('No account found with this email address');
        return;
      }

      // Use resetPasswordForEmail - this will send an email with reset link/code
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );

      setState(() {
        userEmail = emailController.text.trim();
        maskedEmail = maskEmail(userEmail);
        currentState = ResetState.otp;
        isLoading = false;
      });

      _showMessage(
        'Password reset instructions sent to your email. Please check your email for a reset code.',
        isError: false,
      );
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

  Future<void> verifyOTPAndResetPassword() async {
    if (otpController.text.isEmpty) {
      _showMessage('Please enter the verification code');
      return;
    }

    if (newPasswordController.text.isEmpty) {
      _showMessage('Please enter a new password');
      return;
    }

    if (newPasswordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters long');
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Verify the OTP for password recovery
      final AuthResponse response = await Supabase.instance.client.auth
          .verifyOTP(
            token: otpController.text.trim(),
            type: OtpType.recovery,
            email: userEmail,
          );

      if (response.user != null) {
        // Now update the password
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPasswordController.text),
        );

        setState(() {
          isLoading = false;
        });

        _showMessage('Password updated successfully!', isError: false);

        // Navigate back to login after successful password reset
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } on AuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('Failed to reset password: ${error.message}');
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> resetPasswordWithToken() async {
    if (newPasswordController.text.isEmpty) {
      _showMessage('Please enter a new password');
      return;
    }

    if (newPasswordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters long');
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Update the password using the session from the deep link
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPasswordController.text),
      );

      setState(() {
        isLoading = false;
      });

      _showMessage('Password updated successfully!', isError: false);

      // Sign out the user and navigate to login
      await Supabase.instance.client.auth.signOut();

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    } on AuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      _showMessage('Failed to reset password: ${error.message}');
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
      ),
    );
  }

  Widget buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Enter your email address and we\'ll send you a verification code to reset your password.',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
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
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF9CA3AF)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Send Reset Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            children: [
              TextSpan(text: 'We\'ve sent a verification code to '),
              TextSpan(
                text: maskedEmail,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              TextSpan(text: '. Enter the code below to continue.'),
            ],
          ),
        ),
        SizedBox(height: 40),

        // OTP field
        Text(
          'Verification Code',
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
            controller: otpController,
            decoration: InputDecoration(
              hintText: 'Enter 6-digit code',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.pin_outlined, color: Color(0xFF9CA3AF)),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
          ),
        ),
        SizedBox(height: 24),

        // New password field
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
            onChanged: (_) => _validatePassword(),
            decoration: InputDecoration(
              hintText: 'Enter new password',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
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

        // Password requirements visual feedback
        if (newPasswordController.text.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: passwordError == null
                  ? Color(0xFFF0FDF4)
                  : Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: passwordError == null
                    ? Color(0xFFD1FAE5)
                    : Color(0xFFFECACA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 8),
                _buildRequirementItem(
                  'At least 8 characters',
                  newPasswordController.text.length >= 8,
                ),
                _buildRequirementItem(
                  'Contains uppercase letter',
                  RegExp(r'[A-Z]').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains lowercase letter',
                  RegExp(r'[a-z]').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains number',
                  RegExp(r'\d').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains special character',
                  RegExp(
                    r'[!@#$%^&*(),.?":{}|<>]',
                  ).hasMatch(newPasswordController.text),
                ),
              ],
            ),
          ),

        SizedBox(height: 16),

        // Confirm password field
        Text(
          'Confirm New Password',
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
              hintText: 'Confirm new password',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
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
        SizedBox(height: 32),

        // Reset password button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : verifyOTPAndResetPassword,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        SizedBox(height: 20),

        // Resend code button
        Center(
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      currentState = ResetState.email;
                      otpController.clear();
                      newPasswordController.clear();
                      confirmPasswordController.clear();
                    });
                  },
            child: Text(
              'Didn\'t receive the code? Try again',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTokenResetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Enter your new password below. Make sure it\'s at least 8 characters long.',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
        ),
        SizedBox(height: 40),

        // New password field
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
            onChanged: (_) => _validatePassword(),
            decoration: InputDecoration(
              hintText: 'Enter new password (8+ characters)',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
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

        // Password requirements visual feedback
        if (newPasswordController.text.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: passwordError == null
                  ? Color(0xFFF0FDF4)
                  : Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: passwordError == null
                    ? Color(0xFFD1FAE5)
                    : Color(0xFFFECACA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 8),
                _buildRequirementItem(
                  'At least 8 characters',
                  newPasswordController.text.length >= 8,
                ),
                _buildRequirementItem(
                  'Contains uppercase letter',
                  RegExp(r'[A-Z]').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains lowercase letter',
                  RegExp(r'[a-z]').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains number',
                  RegExp(r'\d').hasMatch(newPasswordController.text),
                ),
                _buildRequirementItem(
                  'Contains special character',
                  RegExp(
                    r'[!@#$%^&*(),.?":{}|<>]',
                  ).hasMatch(newPasswordController.text),
                ),
              ],
            ),
          ),

        SizedBox(height: 16),

        // Confirm password field
        Text(
          'Confirm New Password',
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
              hintText: 'Confirm new password',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
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
        SizedBox(height: 32),

        // Update password button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : resetPasswordWithToken,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Update Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        SizedBox(height: 20),

        // Security notice
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0369A1), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'After updating your password, you\'ll be signed out and redirected to the login screen.',
                  style: TextStyle(color: Color(0xFF0369A1), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator (hide for token reset flow)
              if (currentState != ResetState.tokenReset)
                Container(
                  margin: EdgeInsets.only(bottom: 40),
                  child: Row(
                    children: [
                      // Step 1
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentState == ResetState.otp
                                ? Color(0xFF10B981)
                                : Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      // Step 2
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: currentState == ResetState.otp
                              ? Color(0xFF10B981)
                              : Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.lock_reset_outlined,
                          color: currentState == ResetState.otp
                              ? Colors.white
                              : Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Current step content
              if (currentState == ResetState.email)
                buildEmailStep()
              else if (currentState == ResetState.otp)
                buildOTPStep()
              else if (currentState == ResetState.tokenReset)
                buildTokenResetStep()
              else
                buildEmailStep(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
