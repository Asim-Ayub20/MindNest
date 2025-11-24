import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_helpers.dart';
import '../widgets/shared_password_input.dart';
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

class _PasswordResetScreenState extends State<PasswordResetScreen>
    with SharedPasswordMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

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

  Future<void> sendPasswordReset() async {
    // Validate email format
    final emailValidation = InputValidators.validateEmail(emailController.text);
    if (emailValidation != null) {
      _showMessage(emailValidation);
      return;
    }

    await _handleAsyncOperation(() async {
      // Check if user exists first
      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('email')
          .eq('email', emailController.text.trim())
          .limit(1);

      if (existingUser.isEmpty) {
        _showMessage('No account found with this email address');
        return;
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );

      setState(() {
        userEmail = emailController.text.trim();
        maskedEmail = maskEmail(userEmail);
        currentState = ResetState.otp;
      });

      _showMessage(
        'Password reset instructions sent to your email. Please check your email for a reset code.',
        isError: false,
      );
    });
  }

  Future<void> verifyOTPAndResetPassword() async {
    if (otpController.text.isEmpty) {
      _showMessage('Please enter the verification code');
      return;
    }

    final passwordValidationError =
        SharedPasswordValidator.validatePasswordComplete(
          newPasswordController.text,
          confirmPasswordController.text,
        );

    if (passwordValidationError != null) {
      _showMessage(passwordValidationError);
      return;
    }

    await _handleAsyncOperation(() async {
      final AuthResponse response = await Supabase.instance.client.auth
          .verifyOTP(
            token: otpController.text.trim(),
            type: OtpType.recovery,
            email: userEmail,
          );

      if (response.user != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPasswordController.text),
        );

        _showMessage('Password updated successfully!', isError: false);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  Future<void> resetPasswordWithToken() async {
    final passwordValidationError =
        SharedPasswordValidator.validatePasswordComplete(
          newPasswordController.text,
          confirmPasswordController.text,
        );

    if (passwordValidationError != null) {
      _showMessage(passwordValidationError);
      return;
    }

    await _handleAsyncOperation(() async {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPasswordController.text),
      );

      _showMessage('Password updated successfully!', isError: false);

      await Supabase.instance.client.auth.signOut();

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    });
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }

  // Reusable UI helper methods
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(prefixIcon, color: Color(0xFF9CA3AF)),
        ),
        keyboardType: keyboardType,
        maxLength: maxLength,
        buildCounter: maxLength != null
            ? (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null
            : null,
      ),
    );
  }

  Widget _buildStyledButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
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
                text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildSectionDescription(String description) {
    return Text(
      description,
      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
    );
  }

  Future<void> _handleAsyncOperation(Future<void> Function() operation) async {
    setState(() => isLoading = true);
    try {
      await operation();
    } on AuthException catch (error) {
      if (mounted) _showMessage('Failed: ${error.message}');
    } catch (error) {
      if (mounted) {
        _showMessage('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Reset Password'),
        SizedBox(height: 12),
        _buildSectionDescription(
          'Enter your email address and we\'ll send you a verification code to reset your password.',
        ),
        SizedBox(height: 40),
        _buildFieldLabel('Email Address'),
        SizedBox(height: 8),
        _buildStyledTextField(
          controller: emailController,
          hintText: 'Enter your email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 32),
        _buildStyledButton(
          text: 'Send Reset Code',
          onPressed: sendPasswordReset,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Verify Code'),
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
        _buildFieldLabel('Verification Code'),
        SizedBox(height: 8),
        _buildStyledTextField(
          controller: otpController,
          hintText: 'Enter 6-digit code',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        SizedBox(height: 24),
        SharedPasswordInput(
          passwordController: newPasswordController,
          confirmPasswordController: confirmPasswordController,
          isPasswordVisible: isNewPasswordVisible,
          isConfirmPasswordVisible: isConfirmPasswordVisible,
          onPasswordVisibilityToggle: () =>
              setState(() => isNewPasswordVisible = !isNewPasswordVisible),
          onConfirmPasswordVisibilityToggle: () => setState(
            () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
          ),
          passwordError: passwordError,
          onPasswordChanged: (value) => validatePassword(value),
          onConfirmPasswordChanged: (value) => setState(() {}),
          passwordHint: 'Enter new password',
          confirmPasswordHint: 'Confirm new password',
        ),
        SizedBox(height: 32),
        _buildStyledButton(
          text: 'Reset Password',
          onPressed: verifyOTPAndResetPassword,
          isLoading: isLoading,
        ),
        SizedBox(height: 20),
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
        _buildSectionTitle('Reset Your Password'),
        SizedBox(height: 12),
        _buildSectionDescription(
          'Enter your new password below. Make sure it\'s at least 8 characters long.',
        ),
        SizedBox(height: 40),
        SharedPasswordInput(
          passwordController: newPasswordController,
          confirmPasswordController: confirmPasswordController,
          isPasswordVisible: isNewPasswordVisible,
          isConfirmPasswordVisible: isConfirmPasswordVisible,
          onPasswordVisibilityToggle: () =>
              setState(() => isNewPasswordVisible = !isNewPasswordVisible),
          onConfirmPasswordVisibilityToggle: () => setState(
            () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
          ),
          passwordError: passwordError,
          onPasswordChanged: (value) => validatePassword(value),
          onConfirmPasswordChanged: (value) => setState(() {}),
          passwordHint: 'Enter new password (8+ characters)',
          confirmPasswordHint: 'Confirm new password',
        ),
        SizedBox(height: 32),
        _buildStyledButton(
          text: 'Update Password',
          onPressed: resetPasswordWithToken,
          isLoading: isLoading,
        ),
        SizedBox(height: 20),
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
