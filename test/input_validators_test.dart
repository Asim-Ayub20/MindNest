import 'package:flutter_test/flutter_test.dart';
import 'package:mindnest_app/utils/input_validators.dart';

void main() {
  group('InputValidators Password Tests', () {
    test('validatePassword returns null for valid passwords', () {
      expect(InputValidators.validatePassword('Password123!'), isNull);
      expect(InputValidators.validatePassword('MySecure@Pass1'), isNull);
      expect(InputValidators.validatePassword('Test#123'), isNull);
      expect(InputValidators.validatePassword('password123!'), isNull);
      expect(InputValidators.validatePassword('PASSWORD123!'), isNull);
    });

    test('validatePassword returns error for invalid passwords', () {
      expect(InputValidators.validatePassword(''), isNotNull);
      expect(InputValidators.validatePassword(null), isNotNull);
      expect(InputValidators.validatePassword('12345'), isNotNull); // Too short
      expect(
        InputValidators.validatePassword('password'),
        isNotNull,
      ); // No numbers or special chars
      expect(
        InputValidators.validatePassword('Password'),
        isNotNull,
      ); // No numbers or special chars
      expect(
        InputValidators.validatePassword('Password123'),
        isNotNull,
      ); // No special chars
      expect(
        InputValidators.validatePassword('123456789!'),
        isNotNull,
      ); // No letters
      expect(
        InputValidators.validatePassword('abcdefgh'),
        isNotNull,
      ); // No numbers or special chars
    });

    test('validatePassword returns specific error messages', () {
      expect(InputValidators.validatePassword(''), contains('required'));
      expect(
        InputValidators.validatePassword('12345'),
        contains('at least 8 characters'),
      );
      expect(
        InputValidators.validatePassword('12345678'),
        contains('at least one letter'),
      );
      expect(
        InputValidators.validatePassword('password'),
        contains('at least one number'),
      );
      expect(
        InputValidators.validatePassword('password123'),
        contains('at least one special character'),
      );
    });

    test('getPasswordStrength returns correct strength levels', () {
      expect(InputValidators.getPasswordStrength(''), equals(0));
      expect(
        InputValidators.getPasswordStrength('12345'),
        equals(1),
      ); // Length only
      expect(
        InputValidators.getPasswordStrength('password'),
        equals(2),
      ); // Length + lowercase
      expect(
        InputValidators.getPasswordStrength('Password'),
        equals(3),
      ); // Length + lowercase + uppercase
      expect(
        InputValidators.getPasswordStrength('Password1'),
        equals(4),
      ); // Length + lowercase + uppercase + number
      expect(
        InputValidators.getPasswordStrength('Password123!'),
        equals(4),
      ); // All requirements met
    });

    test('getPasswordStrengthDescription returns correct descriptions', () {
      expect(
        InputValidators.getPasswordStrengthDescription(0),
        equals('Very Weak'),
      );
      expect(
        InputValidators.getPasswordStrengthDescription(1),
        equals('Very Weak'),
      );
      expect(InputValidators.getPasswordStrengthDescription(2), equals('Weak'));
      expect(InputValidators.getPasswordStrengthDescription(3), equals('Fair'));
      expect(
        InputValidators.getPasswordStrengthDescription(4),
        equals('Strong'),
      );
    });
  });

  group('InputValidators Email Tests', () {
    test('validateEmail returns null for valid emails', () {
      expect(InputValidators.validateEmail('test@example.com'), isNull);
      expect(InputValidators.validateEmail('user@domain.co.uk'), isNull);
      expect(InputValidators.validateEmail('name.surname@company.com'), isNull);
      expect(InputValidators.validateEmail('user+tag@email.com'), isNull);
      expect(InputValidators.validateEmail('test123@test123.com'), isNull);
      expect(
        InputValidators.validateEmail('ab@cd.co'),
        isNull,
      ); // Changed from 'a@b.co'
    });

    test('validateEmail returns error for empty or null emails', () {
      expect(InputValidators.validateEmail(''), isNotNull);
      expect(InputValidators.validateEmail(null), isNotNull);
      expect(InputValidators.validateEmail('   '), isNotNull);
    });

    test('validateEmail returns error for emails with spaces', () {
      expect(
        InputValidators.validateEmail('test @example.com'),
        contains('cannot contain spaces'),
      );
      expect(
        InputValidators.validateEmail('test@ example.com'),
        contains('cannot contain spaces'),
      );
      expect(
        InputValidators.validateEmail('test @example .com'),
        contains('cannot contain spaces'),
      );
    });

    test('validateEmail returns error for emails that are too short', () {
      expect(InputValidators.validateEmail('a@b'), contains('too short'));
      expect(InputValidators.validateEmail('a@'), contains('too short'));
    });

    test('validateEmail returns error for emails that are too long', () {
      final longEmail = '${'a' * 250}@example.com';
      expect(InputValidators.validateEmail(longEmail), contains('too long'));
    });

    test('validateEmail returns error for invalid email formats', () {
      expect(InputValidators.validateEmail('invalid'), isNotNull);
      expect(InputValidators.validateEmail('@example.com'), isNotNull);
      expect(InputValidators.validateEmail('user@'), isNotNull);
      expect(InputValidators.validateEmail('user@domain'), isNotNull);
      expect(InputValidators.validateEmail('user.domain.com'), isNotNull);
      expect(InputValidators.validateEmail('user@@domain.com'), isNotNull);
      expect(InputValidators.validateEmail('user@domain..com'), isNotNull);
    });

    test('validateEmail returns error for emails with consecutive dots', () {
      expect(
        InputValidators.validateEmail('test..user@example.com'),
        contains('consecutive dots'),
      );
      expect(
        InputValidators.validateEmail('test@example..com'),
        contains('consecutive dots'),
      );
    });

    test(
      'validateEmail returns error for emails with dots at wrong positions',
      () {
        expect(
          InputValidators.validateEmail('.test@example.com'),
          contains('cannot start or end with a dot'),
        );
        expect(
          InputValidators.validateEmail('test.@example.com'),
          contains('cannot start or end with a dot'),
        );
      },
    );

    test('validateEmail returns error for invalid domain formats', () {
      // No TLD
      expect(InputValidators.validateEmail('test@domain'), isNotNull);
      // Domain starts with dot
      expect(InputValidators.validateEmail('test@.domain.com'), isNotNull);
      // Domain ends with dot
      expect(InputValidators.validateEmail('test@domain.com.'), isNotNull);
      // Domain starts with hyphen
      expect(InputValidators.validateEmail('test@-domain.com'), isNotNull);
      // Domain ends with hyphen
      expect(InputValidators.validateEmail('test@domain.com-'), isNotNull);
    });

    test('validateEmail handles case insensitivity', () {
      expect(InputValidators.validateEmail('Test@Example.COM'), isNull);
      expect(InputValidators.validateEmail('USER@DOMAIN.COM'), isNull);
    });

    test(
      'validateEmail rejects ambiguous patterns - single-letter local parts',
      () {
        expect(
          InputValidators.validateEmail('a@example.com'),
          contains('at least 2 characters'),
        );
        expect(
          InputValidators.validateEmail('t@gmail.com'),
          contains('at least 2 characters'),
        );
      },
    );

    test(
      'validateEmail rejects ambiguous patterns - all-numeric local parts',
      () {
        expect(
          InputValidators.validateEmail('123@example.com'),
          contains('must contain at least one letter'),
        );
        expect(
          InputValidators.validateEmail('456@test.com'),
          contains('must contain at least one letter'),
        );
      },
    );

    test(
      'validateEmail rejects ambiguous patterns - single-letter domains',
      () {
        expect(
          InputValidators.validateEmail('user@t.com'),
          contains('domain name is too short'),
        );
        expect(
          InputValidators.validateEmail('test@x.org'),
          contains('domain name is too short'),
        );
      },
    );

    test('validateEmail rejects ambiguous patterns - all-numeric domains', () {
      expect(
        InputValidators.validateEmail('user@123.com'),
        contains('must contain letters'),
      );
      expect(
        InputValidators.validateEmail('test@456.net'),
        contains('must contain letters'),
      );
    });

    test('validateEmail rejects invalid TLDs for simple domains', () {
      expect(
        InputValidators.validateEmail('user@example.xyz'),
        contains('valid email domain extension'),
      );
      expect(
        InputValidators.validateEmail('test@domain.abc'),
        contains('valid email domain extension'),
      );
    });

    test('validateEmail accepts valid TLDs', () {
      expect(InputValidators.validateEmail('user@example.com'), isNull);
      expect(InputValidators.validateEmail('test@domain.org'), isNull);
      expect(InputValidators.validateEmail('admin@site.net'), isNull);
      expect(InputValidators.validateEmail('contact@company.co'), isNull);
      expect(InputValidators.validateEmail('info@website.pk'), isNull);
      expect(InputValidators.validateEmail('support@app.io'), isNull);
    });

    test('validateEmail accepts subdomains without strict TLD validation', () {
      // Subdomains are allowed more flexibility
      expect(InputValidators.validateEmail('user@mail.example.xyz'), isNull);
      expect(InputValidators.validateEmail('test@sub.domain.custom'), isNull);
    });

    test('validateEmail accepts properly formatted alphanumeric emails', () {
      expect(InputValidators.validateEmail('user123@example.com'), isNull);
      expect(InputValidators.validateEmail('test456@domain.org'), isNull);
      expect(InputValidators.validateEmail('ab@example.com'), isNull);
      expect(InputValidators.validateEmail('user@ab.com'), isNull);
    });
  });
}
