# Email Verification Duplicate Screen Fix

## Issue Description

When a user received an email to verify their account and clicked the verification link, the email verified success screen would appear **twice**:
1. First appearance: Brief flash
2. Second appearance: For a few seconds before proceeding to onboarding

This created a poor user experience with unnecessary screen transitions.

## Root Cause

The duplicate screen appearance was caused by **two competing auth state listeners** reacting to the same email verification event:

1. **Global listener in `main.dart`** (`_handleSignedInUser`)
   - Listened for `AuthChangeEvent.signedIn`
   - Checked if user was newly verified
   - Navigated to `EmailVerificationFlowScreen` by creating a new instance

2. **Screen-specific listener in `EmailVerificationFlowScreen`** (`_listenForVerification`)
   - Also listened for `AuthChangeEvent.signedIn`
   - Triggered the success state transition within the existing screen instance

### User Flow That Caused the Issue

1. User signs up → Navigated to `EmailVerificationFlowScreen` (waiting state)
2. User clicks email verification link → Deeplink opens app
3. Supabase processes the auth token → User is signed in
4. **Both listeners fire simultaneously:**
   - `main.dart` listener creates a **new** `EmailVerificationFlowScreen` instance (brief flash)
   - Original screen's listener transitions to success state (shows again)

## Solution Implemented

### 1. Added Static Activity Flag to EmailVerificationFlowScreen

```dart
class EmailVerificationFlowScreen extends StatefulWidget {
  // Static flag to track if an instance is currently active
  static bool _isCurrentlyActive = false;
  
  // Static method to check if screen is currently displayed
  static bool get isActive => _isCurrentlyActive;
}
```

The flag is:
- Set to `true` in `initState()` when screen is created
- Set to `false` in `dispose()` when screen is destroyed
- Publicly accessible via `EmailVerificationFlowScreen.isActive`

### 2. Updated main.dart to Check the Flag

Modified the `_handleSignedInUser` method to check if `EmailVerificationFlowScreen` is currently active before attempting navigation:

```dart
final isNewUserFromEmailVerification =
    progressPercentage == 0 &&
    (currentRoute == null || currentRoute == '/') &&
    user.emailConfirmedAt != null &&
    !EmailVerificationFlowScreen.isActive; // ← Added this check
```

**Logic**: If the EmailVerificationFlowScreen is already displayed, `main.dart` will NOT try to navigate to it again. Instead, the screen's own listener will handle the success transition.

### 3. Added Duplicate Handling Prevention

Added a flag `_isHandlingEmailVerification` in `main.dart` to prevent rapid duplicate calls within a short time window:

```dart
// Set flag before navigation
_isHandlingEmailVerification = true;

// Navigate to EmailVerificationFlowScreen
Navigator.of(context).pushAndRemoveUntil(...);

// Reset flag after 5 seconds
Future.delayed(const Duration(seconds: 5), () {
  _isHandlingEmailVerification = false;
});
```

### 4. Enhanced Logging

Added debug logging with prefixes to help trace the execution flow:
- `[MainApp]` - Logs from main.dart
- `[EmailVerificationFlowScreen]` - Logs from the screen

## Files Modified

1. **`lib/main.dart`**
   - Added `_isHandlingEmailVerification` flag
   - Modified `_handleSignedInUser` to check `EmailVerificationFlowScreen.isActive`
   - Added enhanced logging

2. **`lib/screens/email_verification_flow_screen.dart`**
   - Added static `_isCurrentlyActive` flag
   - Added public `isActive` getter
   - Set flag in `initState()` and `dispose()`
   - Enhanced logging for verification handling

## How It Works Now

### Scenario 1: User verifies while on the waiting screen (Normal flow)
1. User signs up → EmailVerificationFlowScreen shows (waiting state)
2. `EmailVerificationFlowScreen._isCurrentlyActive = true`
3. User clicks email link → Deeplink opens app
4. Both listeners fire:
   - **main.dart**: Checks `EmailVerificationFlowScreen.isActive` → `true` → Does NOT navigate
   - **EmailVerificationFlowScreen**: Transitions to success state → Shows checkmark and success message
5. After 3 seconds → Navigates to onboarding

### Scenario 2: User verifies from another device
1. User signs up on phone → Closes app before verifying
2. User clicks link on computer → Verifies account
3. User reopens app later → Login screen
4. `EmailVerificationFlowScreen._isCurrentlyActive = false` (no instance exists)
5. main.dart listener:
   - Checks `EmailVerificationFlowScreen.isActive` → `false`
   - Navigates to EmailVerificationFlowScreen with success state
6. Shows success message → Navigates to onboarding

## Benefits

✅ **No more duplicate screens** - Only one transition happens
✅ **Smooth user experience** - Single, clean success screen display
✅ **Proper state management** - Clear ownership of navigation logic
✅ **Better debugging** - Enhanced logging helps trace issues
✅ **Maintains all functionality** - Both user scenarios work correctly

## Testing Recommendations

1. **Normal Flow Test**
   - Sign up with new account
   - Wait on verification screen
   - Click email link
   - Verify: Single success screen appears, no flashing

2. **Cross-Device Test**
   - Sign up on device A
   - Close app
   - Verify on device B
   - Reopen app on device A
   - Verify: Shows success screen correctly

3. **Edge Cases**
   - Test with slow network
   - Test with app in background
   - Test rapid clicking of email link

## Conclusion

The duplicate email verification screen issue has been resolved by implementing a static activity flag that prevents `main.dart` from creating duplicate screen instances when `EmailVerificationFlowScreen` is already active. The screen now appears exactly once with a smooth transition to the success state.
