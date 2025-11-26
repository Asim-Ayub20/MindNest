import 'package:flutter/material.dart';
import '../utils/input_validators.dart';
import '../utils/app_theme.dart';

/// A comprehensive shared password input widget with validation and visual feedback
/// Used across signup and password reset screens for complete consistency
class SharedPasswordInput extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onConfirmPasswordVisibilityToggle;
  final String? passwordError;
  final Function(String) onPasswordChanged;
  final Function(String) onConfirmPasswordChanged;
  final String passwordHint;
  final String confirmPasswordHint;
  final bool showConfirmPassword;

  const SharedPasswordInput({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.onPasswordVisibilityToggle,
    required this.onConfirmPasswordVisibilityToggle,
    required this.passwordError,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    this.passwordHint = 'Create a strong password',
    this.confirmPasswordHint = 'Confirm your password',
    this.showConfirmPassword = true,
  });

  @override
  State<SharedPasswordInput> createState() => _SharedPasswordInputState();
}

class _SharedPasswordInputState extends State<SharedPasswordInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password field
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightText.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: widget.passwordController,
            obscureText: !widget.isPasswordVisible,
            onChanged: widget.onPasswordChanged,
            decoration: InputDecoration(
              hintText: widget.passwordHint,
              hintStyle: const TextStyle(color: AppTheme.lightText),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppTheme.lightText,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  widget.isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppTheme.lightText,
                ),
                onPressed: widget.onPasswordVisibilityToggle,
              ),
            ),
          ),
        ),

        // Password requirements visual feedback
        SharedPasswordRequirements(
          password: widget.passwordController.text,
          passwordError: widget.passwordError,
        ),

        if (widget.showConfirmPassword) ...[
          const SizedBox(height: 16),
          // Confirm Password field
          const Text(
            'Confirm Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightText.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: widget.confirmPasswordController,
              obscureText: !widget.isConfirmPasswordVisible,
              onChanged: widget.onConfirmPasswordChanged,
              decoration: InputDecoration(
                hintText: widget.confirmPasswordHint,
                hintStyle: const TextStyle(color: AppTheme.lightText),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.lightText,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    widget.isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppTheme.lightText,
                  ),
                  onPressed: widget.onConfirmPasswordVisibilityToggle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared password requirements widget with consistent styling
class SharedPasswordRequirements extends StatelessWidget {
  final String password;
  final String? passwordError;

  const SharedPasswordRequirements({
    super.key,
    required this.password,
    required this.passwordError,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: passwordError == null && password.isNotEmpty
            ? const Color(0xFFF0FDF4) // Green background when valid
            : const Color(0xFFF0F9FF), // Blue background by default
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passwordError == null && password.isNotEmpty
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : AppTheme.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passwordError == null && password.isNotEmpty
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                color: passwordError == null && password.isNotEmpty
                    ? AppTheme.primaryGreen
                    : AppTheme.accentBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SharedPasswordRequirementItem(
            requirement: 'At least 8 characters',
            isMet: password.length >= 8,
          ),
          _SharedPasswordRequirementItem(
            requirement: 'Contains letters (A-Z or a-z)',
            isMet: RegExp(r'[a-zA-Z]').hasMatch(password),
          ),
          _SharedPasswordRequirementItem(
            requirement: 'Contains numbers (0-9)',
            isMet: RegExp(r'[0-9]').hasMatch(password),
          ),
          _SharedPasswordRequirementItem(
            requirement: 'Contains special characters (!@#\$%^&*)',
            isMet: RegExp(
              r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]',
            ).hasMatch(password),
          ),
        ],
      ),
    );
  }
}

/// Internal shared widget for password requirement items
class _SharedPasswordRequirementItem extends StatelessWidget {
  final String requirement;
  final bool isMet;

  const _SharedPasswordRequirementItem({
    required this.requirement,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? AppTheme.primaryGreen : AppTheme.lightText,
            size: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: isMet ? AppTheme.darkGreen : AppTheme.secondaryText,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared password validation logic for use across all screens
class SharedPasswordValidator {
  /// Validates password and returns error message if invalid
  static String? validatePassword(String password) {
    return InputValidators.validatePassword(password);
  }

  /// Validates password confirmation matching
  static String? validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Combined validation for both password and confirmation
  static String? validatePasswordComplete(
    String password,
    String confirmPassword,
  ) {
    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;

    return validatePasswordConfirmation(password, confirmPassword);
  }
}

/// Mixin for shared password functionality in stateful widgets
mixin SharedPasswordMixin<T extends StatefulWidget> on State<T> {
  String? passwordError;

  /// Standard password validation method
  void validatePassword(String password) {
    setState(() {
      passwordError = SharedPasswordValidator.validatePassword(password);
    });
  }

  /// Method to handle password changes with validation
  void onPasswordChanged(String password) {
    validatePassword(password);
  }
}
