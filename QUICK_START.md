# 🚀 Quick Start - OTP System

## 📦 What's New

### Files Created
```
lib/services/OTPService.dart
```

### Files Modified
```
lib/screens/ForgetPassword.dart
lib/screens/EnterOTP.dart
lib/screens/ResetPassword.dart
```

### Documentation Added
```
OTP_IMPLEMENTATION_GUIDE.md
OTP_COMPLETED.md
QUICK_START.md (this file)
```

---

## ⚡ Quick Setup

### 1. Verify EmailJS Credentials
Edit `lib/services/OTPService.dart` - Check these values:

```dart
final String emailjsServiceId = 'service_humtemp12';
final String emailjsTemplateId = 'template_uln8yw4';
final String emailjsPublicKey = 'qL24MXYoVf2NdZ50B';
final String emailjsPrivateKey = 'auQ3OqDQ9UnMU1yBj28Oz';
```

**If different, update with your EmailJS credentials:**
1. Go to https://www.emailjs.com/
2. Dashboard → Email Services → Get Service ID
3. Dashboard → Email Templates → Get Template ID
4. Dashboard → Account → API Keys → Get Public & Private Key

### 2. Run Flutter
```bash
flutter pub get
flutter run
```

### 3. Test OTP Flow
1. Navigate to **Forget Password**
2. Enter valid email: `test@example.com`
3. Click **Send OTP**
4. Check email for OTP code
5. Enter 6-digit OTP on next screen
6. Click **Verify OTP**
7. Set new password (min 8 chars, uppercase, lowercase, number)
8. Click **Reset Password**

---

## 🎯 Key Features

| Feature | Details |
|---------|---------|
| OTP Generation | Random 6-digit number |
| OTP Validity | 10 minutes |
| Max Attempts | 5 wrong tries |
| Resend Cooldown | 30 seconds minimum |
| Email Validation | Format checking |
| Password Rules | 8+ chars, uppercase, lowercase, number |
| Configuration | Centralized in OTPService.dart |

---

## 🔧 Using OTPService

### In Your Code

```dart
import 'package:myapp/services/OTPService.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final OTPService _otp = OTPService();
  
  void sendOTP() async {
    try {
      await _otp.sendOTP('user@example.com');
      print('OTP sent!');
    } catch (e) {
      print('Error: $e');
    }
  }
  
  void verifyOTP() async {
    try {
      await _otp.verifyOTP('user@example.com', '123456');
      print('Verified!');
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

---

## 📱 Screen Flow

```
┌─────────────────────┐
│  ForgetPassword     │
│                     │
│ Enter Email: [ ]    │
│   [Send OTP]        │
└──────────┬──────────┘
           │ sendOTP()
           ↓
      EmailJS API
           │
           ↓
┌─────────────────────┐
│   User's Email      │
│                     │
│  Your OTP: 123456   │
└─────────────────────┘
           │
           ↓
┌─────────────────────┐
│    EnterOTP         │
│                     │
│ [1][2][3][4][5][6]  │
│ [Verify] [Resend]   │
└──────────┬──────────┘
           │ verifyOTP()
           ↓
    OTPService Validation
           │
    ┌──────┴──────┐
    ↓             ↓
  Valid        Invalid
    │             │
    ↓             ↓
Password      Error
Reset         Msg
    │
    ↓
Login
```

---

## ✅ Checklist Before Using

- [ ] EmailJS credentials verified
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] No compilation errors
- [ ] Email provider configured (Gmail verified, etc.)
- [ ] Test email ready
- [ ] Connection to internet working

---

## 🐛 Common Issues & Fixes

### OTP not sent
```
❌ Problem: Message says "Gagal mengirim OTP"
✅ Solution:
   1. Check internet connection
   2. Verify EmailJS credentials in OTPService.dart
   3. Verify email template exists in EmailJS
   4. Check email provider settings
```

### OTP not received in email
```
❌ Problem: Email doesn't arrive
✅ Solution:
   1. Check spam/junk folder
   2. Wait 1-2 seconds for email delivery
   3. Try resending OTP
   4. Check email address is correct
   5. Verify email template is approved
```

### Verification failed
```
❌ Problem: "OTP tidak valid"
✅ Solution:
   1. Copy OTP carefully (no spaces)
   2. Check OTP not expired (10 min limit)
   3. Check not exceeded 5 attempts
   4. Try requesting new OTP
```

---

## 📊 OTP Settings

Edit these in `lib/services/OTPService.dart`:

```dart
// Change expiry time (in minutes)
final Duration otpValidity = const Duration(minutes: 10);

// Change max attempts
final int maxAttempts = 5;
```

---

## 🔒 Security Reminders

- ✅ OTP is random (not hardcoded)
- ✅ OTP expires after 10 minutes
- ✅ OTP limited to 5 attempts
- ✅ Resend limited to 30-second intervals
- ✅ Password must be 8+ chars with uppercase/lowercase/number
- ✅ Configuration centralized (easy to update)

---

## 📖 More Information

For detailed documentation, see:

1. **OTP_IMPLEMENTATION_GUIDE.md** - Complete setup guide
2. **OTP_COMPLETED.md** - Detailed implementation
3. **OTP_FIXES_SUMMARY.md** - Problems & solutions

---

## 🎮 Try It Out

```dart
// Quick test
final otp = OTPService();

// 1. Send OTP
await otp.sendOTP('your.email@example.com');

// 2. Get from email, then verify
await otp.verifyOTP('your.email@example.com', '123456');

// 3. Check remaining time
int mins = otp.getRemainingTime('your.email@example.com');
print('OTP expires in $mins minutes');
```

---

**Ready to go! 🚀**

For support, check the documentation files or review the source code with comments.
