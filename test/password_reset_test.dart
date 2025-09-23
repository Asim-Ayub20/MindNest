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
      // Test password requirements
      bool isValidPassword(String password) {
        return password.length >= 6;
      }

      expect(isValidPassword('123456'), isTrue);
      expect(isValidPassword('password123'), isTrue);
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword(''), isFalse);
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
