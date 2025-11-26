import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_helpers.dart';
import '../widgets/shared_password_input.dart';
import '../utils/input_validators.dart';
import '../utils/app_theme.dart';

// Reset flow states
enum ResetState { email, emailSent, tokenReset }

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
        redirectTo: 'io.supabase.mindnest://reset-password',
      );

      setState(() {
        userEmail = emailController.text.trim();
        maskedEmail = maskEmail(userEmail);
        currentState = ResetState.emailSent;
      });

      _showMessage(
        'Password reset link sent to your email. Please check your inbox.',
        isError: false,
      );
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
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightText.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.lightText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: AppTheme.lightText),
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
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppTheme.lightText.withValues(alpha: 0.3),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        color: AppTheme.primaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.lightTheme.textTheme.displayMedium);
  }

  Widget _buildSectionDescription(String description) {
    return Text(
      description,
      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
        color: AppTheme.secondaryText,
        height: 1.5,
      ),
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
          text: 'Send Reset Link',
          onPressed: sendPasswordReset,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget buildEmailSentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Check Your Email'),
        SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            children: [
              TextSpan(text: 'We\'ve sent a password reset link to '),
              TextSpan(
                text: maskedEmail,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              TextSpan(
                text:
                    '. Please click the link in the email to reset your password.',
              ),
            ],
          ),
        ),
        SizedBox(height: 40),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: AppTheme.darkGreen,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'The link will expire in 1 hour. If you don\'t see it, check your spam folder.',
                  style: TextStyle(color: AppTheme.darkGreen, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        _buildStyledButton(
          text: 'Back to Login',
          onPressed: () => Navigator.of(context).pop(),
          isLoading: false,
        ),
        SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                currentState = ResetState.email;
              });
            },
            child: Text(
              'Wrong email? Try again',
              style: TextStyle(
                color: AppTheme.primaryGreen,
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
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.darkBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'After updating your password, you\'ll be signed out and redirected to the login screen.',
                  style: TextStyle(color: AppTheme.darkBlue, fontSize: 14),
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
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryText),
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
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
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
                            color: currentState == ResetState.emailSent
                                ? AppTheme.primaryGreen
                                : AppTheme.lightText.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),

                      // Step 2
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: currentState == ResetState.emailSent
                              ? AppTheme.primaryGreen
                              : AppTheme.lightText.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          color: currentState == ResetState.emailSent
                              ? Colors.white
                              : AppTheme.lightText,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Current step content
              if (currentState == ResetState.email)
                buildEmailStep()
              else if (currentState == ResetState.emailSent)
                buildEmailSentStep()
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

    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
