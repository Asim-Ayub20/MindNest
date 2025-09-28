import 'package:flutter/material.dart';

/// A reusable widget that displays password requirements with visual feedback
/// Used across signup and password reset screens for consistency
class PasswordRequirementsWidget extends StatelessWidget {
  final String password;
  final String? passwordError;

  const PasswordRequirementsWidget({
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passwordError == null && password.isNotEmpty
              ? const Color(0xFFBBF7D0) // Green border when valid
              : const Color(0xFFBFDBFE), // Blue border by default
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
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: passwordError == null && password.isNotEmpty
                        ? const Color(0xFF059669)
                        : const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
            requirement: 'At least 8 characters',
            isMet: password.length >= 8,
          ),
          _PasswordRequirementItem(
            requirement: 'Contains letters (A-Z or a-z)',
            isMet: RegExp(r'[a-zA-Z]').hasMatch(password),
          ),
          _PasswordRequirementItem(
            requirement: 'Contains numbers (0-9)',
            isMet: RegExp(r'[0-9]').hasMatch(password),
          ),
          _PasswordRequirementItem(
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

/// A simplified version for password reset screens with basic styling
class SimplePasswordRequirementsWidget extends StatelessWidget {
  final String password;
  final String? passwordError;

  const SimplePasswordRequirementsWidget({
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
        color: passwordError == null
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passwordError == null
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
            requirement: 'At least 8 characters',
            isMet: password.length >= 8,
          ),
          _PasswordRequirementItem(
            requirement: 'Contains uppercase letter',
            isMet: RegExp(r'[A-Z]').hasMatch(password),
          ),
          _PasswordRequirementItem(
            requirement: 'Contains lowercase letter',
            isMet: RegExp(r'[a-z]').hasMatch(password),
          ),
          _PasswordRequirementItem(
            requirement: 'Contains number',
            isMet: RegExp(r'\d').hasMatch(password),
          ),
          _PasswordRequirementItem(
            requirement: 'Contains special character',
            isMet: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
          ),
        ],
      ),
    );
  }
}

/// Internal widget for individual password requirement items
/// Consolidated to eliminate duplicate code across screens
class _PasswordRequirementItem extends StatelessWidget {
  final String requirement;
  final bool isMet;

  const _PasswordRequirementItem({
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
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
            size: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: isMet
                    ? const Color(0xFF059669)
                    : const Color(0xFF6B7280),
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
