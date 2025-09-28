import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password Reset Screen Tests', () {
    test('Email masking function works correctly', () {
      // Test the email masking logic directly
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

      // Test various email formats
      expect(maskEmail('example@gmail.com'), equals('exa***@gmail.com'));
      expect(maskEmail('test@domain.com'), equals('tes***@domain.com'));
      expect(maskEmail('a@test.com'), equals('a***@test.com'));
      expect(maskEmail('ab@test.com'), equals('a***@test.com'));
      expect(maskEmail('abc@test.com'), equals('a***@test.com'));
      expect(maskEmail('abcd@test.com'), equals('abc***@test.com'));
      expect(maskEmail(''), equals(''));
      expect(maskEmail('invalid-email'), equals('invalid-email'));
    });

    test('Email validation regex works correctly', () {
      // Test the email validation logic
      bool isValidEmail(String email) {
        return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
      }

      // Valid emails
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.org'), isTrue);
      expect(isValidEmail('username@example.co'), isTrue);

      // Invalid emails
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('invalid'), isFalse);
      expect(isValidEmail('test@'), isFalse);
      expect(isValidEmail('@domain.com'), isFalse);
      expect(isValidEmail('test@domain'), isFalse);
    });

    test('Password validation works correctly', () {
      // Test password requirements: 8+ chars, letters, numbers, special chars
      bool isValidPassword(String password) {
        if (password.length < 8) return false;
        if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
        if (!RegExp(r'[0-9]').hasMatch(password)) return false;
        if (!RegExp(
          r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]',
        ).hasMatch(password)) {
          return false;
        }
        return true;
      }

      // Valid passwords
      expect(isValidPassword('Password123!'), isTrue);
      expect(isValidPassword('Secure@2024'), isTrue);
      expect(isValidPassword('MyPass1#'), isTrue);
      expect(
        isValidPassword('password123!'),
        isTrue,
      ); // Lowercase letters are valid
      expect(
        isValidPassword('PASSWORD123!'),
        isTrue,
      ); // Uppercase letters are valid

      // Invalid passwords
      expect(isValidPassword('12345'), isFalse); // Too short
      expect(isValidPassword(''), isFalse); // Empty
      expect(
        isValidPassword('password'),
        isFalse,
      ); // No numbers or special chars
      expect(
        isValidPassword('Password'),
        isFalse,
      ); // No numbers or special chars
      expect(isValidPassword('Password123'), isFalse); // No special chars
      expect(isValidPassword('1234567!'), isFalse); // No letters
    });

    test('Password matching validation works correctly', () {
      // Test password confirmation matching
      bool passwordsMatch(String password, String confirmPassword) {
        return password == confirmPassword;
      }

      expect(passwordsMatch('password123', 'password123'), isTrue);
      expect(passwordsMatch('password123', 'different'), isFalse);
      expect(passwordsMatch('', ''), isTrue);
    });
  });
}
