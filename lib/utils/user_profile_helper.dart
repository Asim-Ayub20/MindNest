import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class for fetching and managing user profile information
class UserProfileHelper {
  /// Fetches the user's actual first name and last name from the database
  /// based on their role (patient or therapist)
  static Future<Map<String, String?>> getUserNames() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'firstName': null, 'lastName': null, 'fullName': null};
      }

      // First get the user's role from the profiles table
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        // Fallback to email prefix if no profile found
        final emailPrefix = user.email?.split('@')[0] ?? 'User';
        return {
          'firstName': emailPrefix,
          'lastName': null,
          'fullName': emailPrefix,
        };
      }

      final userRole = profileData['role'] as String?;
      final profileFullName = profileData['full_name'] as String?;

      // Try to get detailed name information from role-specific table
      if (userRole == 'patient') {
        final patientData = await Supabase.instance.client
            .from('patients')
            .select('first_name, last_name, full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (patientData != null) {
          return {
            'firstName': patientData['first_name'] as String?,
            'lastName': patientData['last_name'] as String?,
            'fullName': patientData['full_name'] as String?,
          };
        }
      } else if (userRole == 'therapist') {
        final therapistData = await Supabase.instance.client
            .from('therapists')
            .select('first_name, last_name, full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (therapistData != null) {
          return {
            'firstName': therapistData['first_name'] as String?,
            'lastName': therapistData['last_name'] as String?,
            'fullName': therapistData['full_name'] as String?,
          };
        }
      }

      // Fallback to profile full_name or email prefix
      if (profileFullName != null && profileFullName.isNotEmpty) {
        final nameParts = profileFullName.split(' ');
        return {
          'firstName': nameParts.isNotEmpty ? nameParts[0] : null,
          'lastName': nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : null,
          'fullName': profileFullName,
        };
      }

      // Final fallback to email prefix
      final emailPrefix = user.email?.split('@')[0] ?? 'User';
      return {
        'firstName': emailPrefix,
        'lastName': null,
        'fullName': emailPrefix,
      };
    } catch (e) {
      // If any error occurs, fallback to email prefix
      final user = Supabase.instance.client.auth.currentUser;
      final emailPrefix = user?.email?.split('@')[0] ?? 'User';
      return {
        'firstName': emailPrefix,
        'lastName': null,
        'fullName': emailPrefix,
      };
    }
  }

  /// Shorthand method to get just the first name for display
  static Future<String> getUserFirstName() async {
    final names = await getUserNames();
    return names['firstName'] ?? 'User';
  }

  /// Shorthand method to get the full name for display
  static Future<String> getUserFullName() async {
    final names = await getUserNames();
    return names['fullName'] ?? names['firstName'] ?? 'User';
  }

  /// Method to get a display name (first name + last name or just first name)
  static Future<String> getUserDisplayName() async {
    final names = await getUserNames();
    final firstName = names['firstName'];
    final lastName = names['lastName'];

    if (firstName != null) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      } else {
        return firstName;
      }
    }

    return 'User';
  }
}
