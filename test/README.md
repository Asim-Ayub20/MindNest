# Test Directory

This directory contains test files for the MindNest application.

## Files

### `supabase_connection_test.dart`
A comprehensive test file for verifying Supabase backend connectivity and functionality.

**Features:**
- Visual test widget for manual testing (use with device/simulator)
- Unit tests for configuration verification  
- JWT token format validation
- Widget rendering tests

**How to use the test widget for manual testing:**

1. **Temporarily add to main.dart:**
   ```dart
   import 'test/supabase_connection_test.dart';
   
   // In MaterialApp, change:
   home: SupabaseTestWidget(),
   ```

2. **Run the app on device/simulator:**
   ```bash
   flutter run
   ```

3. **View test results:**
   - Green status = Connection successful
   - Red status = Connection failed
   - Test buttons for manual verification

4. **Remove after testing:**
   - Revert main.dart to original home widget
   - Keep test file for future debugging

**How to run unit tests:**
```bash
flutter test test/supabase_connection_test.dart
```

**Note:** The SupabaseTestWidget requires a device environment (not unit test environment) to fully test Supabase connectivity. Unit tests only verify configuration validity.

### `password_reset_test.dart`
Unit tests for password reset functionality validation logic.

**Features:**
- Email masking function tests
- Email format validation tests
- Password strength validation tests

### `integrated_otp_login_test.dart`
Unit tests for the integrated OTP login functionality within the main login screen.

**Features:**
- Email masking validation for login screen
- Email format validation
- OTP format validation (6-digit numeric)
- Login screen state management tests

## Usage Guidelines

- Use `supabase_connection_test.dart` when debugging backend issues
- Use `password_reset_test.dart` for password reset validation testing
- Use `integrated_otp_login_test.dart` for OTP login functionality testing
- Run tests before deploying to ensure connectivity and functionality
- Keep test files updated with any backend changes
- Remove test widgets from production builds

## Running Tests

**Individual test files:**
```bash
flutter test test/supabase_connection_test.dart
flutter test test/password_reset_test.dart
flutter test test/integrated_otp_login_test.dart
```

**All tests:**
```bash
flutter test
```

## Supabase Configuration

The tests use the following configuration:
- **URL:** `https://yqhgsmrtxgfjuljazoie.supabase.co`
- **Environment:** Production
- **Features tested:** Authentication, Database connectivity, Session management, Password Reset, OTP Login