import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_helpers.dart';
import '../widgets/shared_password_input.dart';
import '../utils/input_validators.dart';

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
    with SharedPasswordMixin, SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool isLoading = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  ResetState currentState = ResetState.email;

  String userEmail = '';
  String maskedEmail = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mental wellness color palette
  static const Color _primaryGreen = Color(0xFF7CB69D);
  static const Color _deepGreen = Color(0xFF5A9A7F);
  static const Color _softCream = Color(0xFFFAF9F6);
  static const Color _warmGray = Color(0xFF6B7280);
  static const Color _darkText = Color(0xFF2D3436);
  static const Color _lightGray = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();

    // If opened from deep link, go directly to token reset
    if (widget.isFromDeepLink && widget.resetSession != null) {
      currentState = ResetState.tokenReset;
      userEmail = widget.resetSession!.user.email ?? '';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _softCream,
      body: Stack(
        children: [
          // Background decorative elements
          _buildBackgroundDecoration(size),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.02),

                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildBackButton(),
                          ),
                          SizedBox(height: size.height * 0.03),

                          // Progress indicator (hide for token reset flow)
                          if (currentState != ResetState.tokenReset)
                            _buildProgressIndicator(),

                          // Current step content
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _buildCurrentStep(),
                          ),

                          SizedBox(height: size.height * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(Size size) {
    return Stack(
      children: [
        // Top right soft circle
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryGreen.withValues(alpha: 0.15),
                  _primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom left soft circle
        Positioned(
          bottom: -size.width * 0.4,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _deepGreen.withValues(alpha: 0.08),
                  _deepGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Subtle icons
        Positioned(
          top: size.height * 0.15,
          left: 20,
          child: Transform.rotate(
            angle: -0.3,
            child: Icon(
              Icons.lock_outline_rounded,
              size: 24,
              color: _primaryGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          right: 30,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.key_rounded,
              size: 20,
              color: _primaryGreen.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _darkText.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Icon(Icons.arrow_back_rounded, color: _darkText, size: 20),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          // Step 1 - Email
          _buildProgressStep(
            icon: Icons.email_outlined,
            isActive: true,
            isCompleted: currentState == ResetState.emailSent,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentState == ResetState.emailSent
                      ? [_primaryGreen, _deepGreen]
                      : [_lightGray, _lightGray],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Step 2 - Sent
          _buildProgressStep(
            icon: Icons.mark_email_read_outlined,
            isActive: currentState == ResetState.emailSent,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isActive || isCompleted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _deepGreen],
              )
            : null,
        color: isActive || isCompleted ? null : _lightGray,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive || isCompleted
            ? [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isActive || isCompleted ? Colors.white : _warmGray,
        size: 18,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentState) {
      case ResetState.email:
        return _buildEmailStep();
      case ResetState.emailSent:
        return _buildEmailSentStep();
      case ResetState.tokenReset:
        return _buildTokenResetStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        _buildStepIcon(Icons.lock_reset_rounded),
        const SizedBox(height: 16),

        // Title
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: _darkText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🔐  Secure recovery',
            style: TextStyle(
              fontSize: 13,
              color: _deepGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Description
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: TextStyle(fontSize: 14, color: _warmGray, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Email field
        _buildTextField(
          controller: emailController,
          focusNode: _emailFocus,
          hintText: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Send button
        _buildPrimaryButton(
          text: 'Send Reset Link',
          onPressed: sendPasswordReset,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),

        // Back to login
        _buildSecondaryButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildEmailSentStep() {
    return Column(
      key: const ValueKey('emailSent'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        _buildStepIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 16),

        // Title
        Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: _darkText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '📧  Link sent successfully',
            style: TextStyle(
              fontSize: 13,
              color: _deepGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Email info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _lightGray, width: 1),
            boxShadow: [
              BoxShadow(
                color: _darkText.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: _warmGray, height: 1.5),
                  children: [
                    const TextSpan(text: 'We\'ve sent a reset link to\n'),
                    TextSpan(
                      text: maskedEmail,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _deepGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tip card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryGreen.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: _primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Link expires in 1 hour. Check spam folder if not found.',
                  style: TextStyle(fontSize: 13, color: _warmGray, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Back to login
        _buildPrimaryButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.of(context).pop(),
          isLoading: false,
        ),
        const SizedBox(height: 12),

        // Try again
        TextButton(
          onPressed: () {
            setState(() {
              currentState = ResetState.email;
            });
          },
          child: Text(
            'Wrong email? Try again',
            style: TextStyle(
              color: _deepGreen,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenResetStep() {
    return Column(
      key: const ValueKey('tokenReset'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        _buildStepIcon(Icons.password_rounded),
        const SizedBox(height: 16),

        // Title
        Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: _darkText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🔑  Almost there',
            style: TextStyle(
              fontSize: 13,
              color: _deepGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Description
        Text(
          'Enter your new password below. Make sure it\'s strong and secure.',
          style: TextStyle(fontSize: 14, color: _warmGray, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Password fields section
        _buildPasswordSection(),
        const SizedBox(height: 20),

        // Update button
        _buildPrimaryButton(
          text: 'Update Password',
          onPressed: resetPasswordWithToken,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),

        // Info card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'After updating, you\'ll be redirected to sign in.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIcon(IconData icon) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Icon(icon, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _darkText.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        keyboardType: keyboardType,
        style: TextStyle(
          color: _darkText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: _warmGray.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: _primaryGreen, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ?? false
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _warmGray,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New password field
        _buildTextField(
          controller: newPasswordController,
          focusNode: _passwordFocus,
          hintText: 'Enter new password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: isNewPasswordVisible,
          onToggleVisibility: () {
            setState(() => isNewPasswordVisible = !isNewPasswordVisible);
          },
        ),
        const SizedBox(height: 8),

        // Password strength indicators
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: 12),

        // Confirm password field
        _buildTextField(
          controller: confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          hintText: 'Confirm new password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: isConfirmPasswordVisible,
          onToggleVisibility: () {
            setState(
              () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = newPasswordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildRequirementChip('8+ chars', hasMinLength),
              _buildRequirementChip('A-Z', hasUppercase),
              _buildRequirementChip('a-z', hasLowercase),
              _buildRequirementChip('0-9', hasNumber),
              _buildRequirementChip('!@#\$', hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementChip(String label, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet
            ? _primaryGreen.withValues(alpha: 0.15)
            : _warmGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMet
              ? _primaryGreen.withValues(alpha: 0.3)
              : _warmGray.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: isMet ? _deepGreen : _warmGray,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isMet ? _deepGreen : _warmGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLoading
              ? [_lightGray, _lightGray]
              : [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_warmGray),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, color: _deepGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: _deepGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
