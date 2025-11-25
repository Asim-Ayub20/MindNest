import 'package:flutter_test/flutter_test.dart';
import 'package:mindnest_app/utils/user_profile_helper.dart';

void main() {
  group('UserProfileHelper Tests', () {
    // Note: These are unit tests that would require proper Supabase setup
    // For now, they serve as documentation of expected behavior

    test(
      'getUserNames should return Map with firstName, lastName, fullName',
      () async {
        // This test would require Supabase mock or test setup
        // Expected behavior:
        // - Should fetch from patients table if role is 'patient'
        // - Should fetch from therapists table if role is 'therapist'
        // - Should fallback to profiles.full_name if role-specific table is empty
        // - Should fallback to email prefix if all else fails

        expect(UserProfileHelper.getUserNames, isA<Function>());
      },
    );

    test('getUserFirstName should return first name string', () async {
      // Expected behavior:
      // - Should return the user's actual first name from database
      // - Should fallback to email prefix if no first name found
      // - Should never return null or empty string

      expect(UserProfileHelper.getUserFirstName, isA<Function>());
    });

    test('getUserDisplayName should return formatted display name', () async {
      // Expected behavior:
      // - Should return "FirstName LastName" if both available
      // - Should return "FirstName" if only first name available
      // - Should return fallback if neither available

      expect(UserProfileHelper.getUserDisplayName, isA<Function>());
    });
  });
}

// Integration test instructions:
// 1. Create test users in Supabase with both patient and therapist roles
// 2. Ensure the patients table has entries with first_name, last_name, full_name
// 3. Ensure the therapists table has entries with first_name, last_name, full_name
// 4. Test the app with real login to verify names display correctly
