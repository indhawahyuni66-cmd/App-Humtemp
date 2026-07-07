# Setup Instructions - Button Implementation

## Status
✅ **main.dart** - Already updated with routes
⚠️ **Screen files** - Need to replace old files with new ones

## Files to Replace

### In `project/lib/screens/` directory:

#### Option 1: Manual Replace (Recommended)
1. Delete `ForgetPassword.dart` → Replace with `ForgetPassword_new.dart`
2. Delete `EnterOTP.dart` → Replace with `EnterOTP_new.dart`  
3. Delete `ResetPassword.dart` → Replace with `ResetPassword_new.dart`

#### Option 2: Command Line (Windows)
```batch
cd project\lib\screens
del ForgetPassword.dart
rename ForgetPassword_new.dart ForgetPassword.dart

del EnterOTP.dart
rename EnterOTP_new.dart EnterOTP.dart

del ResetPassword.dart
rename ResetPassword_new.dart ResetPassword.dart
```

#### Option 3: Command Line (Mac/Linux)
```bash
cd project/lib/screens
rm ForgetPassword.dart && mv ForgetPassword_new.dart ForgetPassword.dart
rm EnterOTP.dart && mv EnterOTP_new.dart EnterOTP.dart
rm ResetPassword.dart && mv ResetPassword_new.dart ResetPassword.dart
```

## Implementation Details

### Button Functionality

#### **ForgetPassword Screen**
- **Back Button** (Top left): Returns to previous screen
- **Continue Button**: 
  - Validates email/phone input
  - Navigates to OTP screen if valid
  - Shows error message if empty

#### **EnterOTP Screen**
- **Back Button** (Top left): Returns to ForgetPassword
- **Reset Password Button**: Navigates to password reset form
- **Resend OTP** (Text): Shows resend OTP text

#### **ResetPassword Screen**  
- **Back Button** (Top left): Returns to OTP screen
- **Submit Button**: 
  - Shows success dialog
  - Returns to SignIn after confirmation
  - Clears navigation stack

## Navigation Flow

```
ForgetPassword (email/phone input)
    ↓ [Continue]
EnterOTP (OTP verification)
    ↓ [Reset Password]
ResetPassword (new password)
    ↓ [Submit]
SignIn (navigation stack cleared)
```

## Code Changes Summary

### GestureDetector Wrapping
All buttons are wrapped with `GestureDetector` for click handling:
```dart
GestureDetector(
  onTap: () {
    // Navigation logic here
  },
  child: Container(
    // Button UI
  ),
)
```

### Navigation Methods Used

1. **Back Navigation:**
```dart
Navigator.pop(context)
```

2. **Forward Navigation:**
```dart
Navigator.pushNamed(context, '/EnterOTP')
```

3. **Reset to Login (after reset):**
```dart
Navigator.pushNamedAndRemoveUntil(
  context,
  '/SignIn',
  (route) => false,
)
```

### Input Validation
```dart
if (textField1.isNotEmpty) {
  // Navigate
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Masukkan email atau nomor telepon')),
  );
}
```

## Testing Steps

1. Run the app: `flutter run`
2. Click on a "Forget Password" option (if available on SignIn)
3. Verify ForgetPassword screen appears
4. Test Continue button with empty input (should show error)
5. Test Continue button with text entered (should navigate to OTP)
6. Test back button (should return to previous screen)
7. On OTP screen, click "Reset Password" button
8. On ResetPassword screen, click "Submit" button
9. Verify dialog appears and returns to SignIn after confirmation

## Next Steps

- [ ] Replace old dart files with new ones
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` to test
- [ ] Verify all button functionality
- [ ] Test navigation flow end-to-end
- [ ] Consider adding actual password reset logic in ResetPassword screen

## Support

If you encounter any issues:
1. Make sure all files are properly replaced
2. Run `flutter clean` to clear cache
3. Run `flutter pub get` to reinstall dependencies
4. Check that route names match in `main.dart` and navigation calls
