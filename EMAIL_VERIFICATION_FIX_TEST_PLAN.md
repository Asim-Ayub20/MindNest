# Test Plan: Email Verification Duplicate Screen Fix

## Test Case 1: Normal Email Verification Flow
**Objective**: Verify that the success screen appears only once when user verifies email while waiting on the verification screen.

**Steps**:
1. Sign up with a new account (patient or therapist)
2. Observe that you are navigated to the Email Verification Flow Screen (waiting state)
3. Check your email and click the verification link
4. Observe the app behavior

**Expected Result**:
- ✅ Screen transitions smoothly from waiting state to success state
- ✅ Success screen (green checkmark) appears **only once**
- ✅ No brief flashing or duplicate screens
- ✅ After 3 seconds, automatically navigates to onboarding
- ✅ User can also click "Continue" button to proceed immediately

**Debug Log Check**:
Look for these logs in sequence:
```
[EmailVerificationFlowScreen] Screen is now active
[EmailVerificationFlowScreen] Email verified successfully!
[EmailVerificationFlowScreen] Handling successful verification
(main.dart should NOT show "New user from email verification" log)
```

---

## Test Case 2: Verify from Another Device
**Objective**: Verify that the success screen appears correctly when user verifies on a different device.

**Steps**:
1. Sign up with a new account on Device A (or emulator)
2. Close the app or return to login screen
3. On Device B (or browser), click the verification link from email
4. Return to Device A and open/login to the app

**Expected Result**:
- ✅ App shows the EmailVerificationFlowScreen with success state
- ✅ Success screen appears only once
- ✅ User sees "Email Verified!" message
- ✅ Navigates to onboarding after 3 seconds or when clicking "Continue"

**Debug Log Check**:
```
[MainApp] New user from email verification - showing success screen
(EmailVerificationFlowScreen.isActive should be false)
```

---

## Test Case 3: Login with Unverified Account
**Objective**: Ensure existing flow for unverified login still works.

**Steps**:
1. Create an account but do NOT verify email
2. Close the app
3. Try to log in with the unverified account

**Expected Result**:
- ✅ Shows message "Please verify your email before logging in"
- ✅ Navigates to EmailVerificationFlowScreen (waiting state)
- ✅ User can resend verification email
- ✅ When verified, transitions to success state smoothly

---

## Test Case 4: Rapid Link Clicking
**Objective**: Test the duplicate prevention mechanism.

**Steps**:
1. Sign up with a new account
2. Wait on the verification screen
3. Open email and click the verification link multiple times rapidly
4. Observe the app behavior

**Expected Result**:
- ✅ Success screen appears only once
- ✅ No multiple screen flashes
- ✅ Flag prevents duplicate navigation
- ✅ Navigation happens smoothly to onboarding

**Debug Log Check**:
```
[EmailVerificationFlowScreen] Already verified or not mounted, skipping
(Should see this if handler is called multiple times)
Already handling email verification, skipping duplicate navigation
(Should see this in main.dart if flag is working)
```

---

## Test Case 5: Background App Verification
**Objective**: Test verification when app is in background.

**Steps**:
1. Sign up with a new account
2. Navigate to verification screen
3. Put app in background (press home button)
4. Click verification link from notification or email
5. App should come to foreground

**Expected Result**:
- ✅ App resumes with success state showing
- ✅ No duplicate screens
- ✅ Smooth transition to onboarding

---

## Test Case 6: Slow Network
**Objective**: Test behavior with slow or unstable network.

**Steps**:
1. Enable network throttling or slow 3G
2. Sign up with new account
3. Wait on verification screen
4. Click verification link

**Expected Result**:
- ✅ Shows loading/processing indicators
- ✅ Eventually transitions to success state
- ✅ No duplicate screens
- ✅ Appropriate error handling if network fails

---

## Test Case 7: Already Completed Onboarding
**Objective**: Ensure users who completed onboarding don't see verification screen again.

**Steps**:
1. Log in with an existing account that has completed onboarding
2. Observe navigation behavior

**Expected Result**:
- ✅ Goes directly to dashboard
- ✅ Does NOT show email verification screen
- ✅ No unexpected navigation

---

## How to Check Debug Logs

### Android (via Android Studio):
```
View → Tool Windows → Logcat
Filter: package:io.supabase.mindnest
```

### Flutter DevTools:
```bash
flutter run
Press 'h' for help menu
Press 'd' for DevTools
Navigate to Logging tab
```

### VS Code:
```
DEBUG CONSOLE tab
Filter for:
- [EmailVerificationFlowScreen]
- [MainApp]
```

---

## Success Criteria

All test cases should pass with:
- ✅ No duplicate screen appearances
- ✅ Smooth transitions
- ✅ Proper logging output
- ✅ Correct navigation flow
- ✅ No errors in console

---

## Rollback Plan

If issues are discovered:
1. Revert changes to `lib/main.dart` and `lib/screens/email_verification_flow_screen.dart`
2. Run: `git revert <commit-hash>`
3. Or restore from backup
4. Report issue with debug logs

---

## Notes

- Test on both Android and iOS if possible
- Test with both patient and therapist user types
- Monitor memory usage for potential leaks
- Check that flag is properly reset after navigation
