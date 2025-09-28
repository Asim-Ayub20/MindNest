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
}
