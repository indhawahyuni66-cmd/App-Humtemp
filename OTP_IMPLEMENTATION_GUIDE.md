# Dokumentasi OTP Authentication dengan EmailJS

## 📋 Overview
Sistem OTP authentication menggunakan EmailJS untuk mengirim kode OTP ke email pengguna. Kode OTP di-generate secara random, memiliki validitas 10 menit, dan terbatas 5 percobaan verifikasi.

---

## 🚀 Setup

### 1. EmailJS Configuration

#### A. Daftar di EmailJS
1. Buka https://www.emailjs.com/
2. Buat akun gratis
3. Konfirmasi email

#### B. Setup Service (Email Provider)
1. Di dashboard EmailJS, pergi ke **Email Services**
2. Klik **Add New Service**
3. Pilih provider email (Gmail, Outlook, atau SMTP custom)
4. Ikuti proses verifikasi
5. Copy **Service ID**: `service_humtemp12`

#### C. Buat Email Template
1. Pergi ke **Email Templates**
2. Klik **Create New Template**
3. Buat template dengan kode OTP:

```html
Subject: Kode OTP Anda - HumTemp

Body:
Halo {{user_name}},

Kode OTP Anda adalah: {{otp}}

Kode ini berlaku selama 10 menit.

Jangan bagikan kode ini kepada siapa pun.

Terima kasih,
Tim HumTemp
```

4. Copy **Template ID**: `template_uln8yw4`

#### D. Dapatkan API Keys
1. Pergi ke **Account**
2. Tab **API Keys**
3. Copy:
   - **Public Key**: `qL24MXYoVf2NdZ50B`
   - **Private Key**: `auQ3OqDQ9UnMU1yBj28Oz`

### 2. Flutter Dependencies
```yaml
dependencies:
  emailjs: ^4.0.0
  firebase_auth: ^6.5.1
  firebase_core: ^4.9.0
```

Run: `flutter pub get`

---

## 📁 File Structure

```
lib/
├── screens/
│   ├── ForgetPassword.dart      (Input email, kirim OTP)
│   ├── EnterOTP.dart            (Verifikasi kode OTP)
│   ├── ResetPassword.dart       (Reset password)
│   ├── SignIn.dart              (Login)
│   └── SignUp.dart              (Register)
├── services/
│   └── OTPService.dart          (OTP management service)
└── firebase_options.dart
```

---

## 🔐 OTPService Class

### Features:
- ✅ Generate random 6-digit OTP
- ✅ Send OTP via EmailJS
- ✅ Verify OTP dengan validasi expiry
- ✅ Rate limiting (max 5 attempts)
- ✅ Resend cooldown (min 30 seconds)
- ✅ Singleton pattern untuk state management

### Konfigurasi

Edit `lib/services/OTPService.dart` untuk customize:

```dart
class OTPService {
  // Ubah credential EmailJS di sini
  final String emailjsServiceId = 'YOUR_SERVICE_ID';
  final String emailjsTemplateId = 'YOUR_TEMPLATE_ID';
  final String emailjsPublicKey = 'YOUR_PUBLIC_KEY';
  final String emailjsPrivateKey = 'YOUR_PRIVATE_KEY';
  
  // Ubah durasi validasi OTP (default: 10 menit)
  final Duration otpValidity = const Duration(minutes: 10);
  
  // Ubah max attempts (default: 5)
  final int maxAttempts = 5;
}
```

### API Methods

#### 1. sendOTP(String email)
```dart
final otpService = OTPService();

try {
  bool success = await otpService.sendOTP('user@example.com');
  if (success) {
    print('OTP sent successfully');
  }
} catch (e) {
  print('Error: ${e.toString()}');
}
```

#### 2. verifyOTP(String email, String otp)
```dart
try {
  bool verified = await otpService.verifyOTP('user@example.com', '123456');
  if (verified) {
    print('OTP verified');
    // Navigate to next screen
  }
} catch (e) {
  print('OTP verification failed: ${e.toString()}');
  // Show error to user
}
```

#### 3. resendOTP(String email)
```dart
try {
  bool success = await otpService.resendOTP('user@example.com');
  if (success) {
    print('OTP resent');
  }
} catch (e) {
  print('Error: ${e.toString()}');
}
```

#### 4. getRemainingTime(String email)
```dart
int remainingMinutes = otpService.getRemainingTime('user@example.com');
print('OTP expires in: $remainingMinutes minutes');
```

#### 5. clearOTP(String email)
```dart
otpService.clearOTP('user@example.com');
```

---

## 🔄 Authentication Flow

### Forgot Password Flow

```
1. ForgetPassword Screen
   └─ User input email
   └─ sendOTP() via OTPService
   └─ OTP dikirim ke email
   └─ Navigate ke EnterOTP

2. EnterOTP Screen
   └─ User input 6-digit OTP
   └─ verifyOTP() via OTPService
   └─ If valid → Navigate ke ResetPassword
   └─ If invalid → Show error + remaining attempts

3. ResetPassword Screen
   └─ User input password baru
   └─ Password diupdate di Firebase/Backend
   └─ Navigate ke SignIn
```

### Screen Transitions

```
SignIn
  ↓
ForgetPassword → Send OTP
  ↓
EnterOTP → Verify OTP
  ↓
ResetPassword → Update Password
  ↓
SignIn
```

---

## 📱 Implementation Details

### ForgetPassword.dart

```dart
import '../services/OTPService.dart';

class ForgetPasswordState extends State<ForgetPassword> {
  final OTPService _otpService = OTPService();
  String textField1 = '';

  Future<void> sendOTP() async {
    try {
      await _otpService.sendOTP(textField1.trim());
      _showSuccessSnackBar('OTP berhasil dikirim');
      
      Navigator.pushNamed(context, '/EnterOTP', arguments: textField1);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }
}
```

### EnterOTP.dart

```dart
import '../services/OTPService.dart';

class EnterOTPState extends State<EnterOTP> {
  final OTPService _otpService = OTPService();

  Future<void> verifyOTP() async {
    String otp = getOTPCode();
    
    try {
      await _otpService.verifyOTP(email, otp);
      _showSuccessSnackBar('OTP terverifikasi');
      
      Navigator.pushNamed(context, '/ResetPassword', arguments: email);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> resendOTP() async {
    try {
      await _otpService.resendOTP(email);
      _showSuccessSnackBar('OTP dikirim ulang');
      _startResendCountdown();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }
}
```

---

## 🛡️ Security Features

### OTP Validation
- ✅ Expiry time: 10 menit
- ✅ Max attempts: 5
- ✅ Invalid OTP shows remaining attempts
- ✅ Automatic clear setelah expiry/max attempts

### Resend Limitations
- ✅ Minimum 30 seconds between resend
- ✅ Error message jika terlalu cepat

### Email Validation
- ✅ Format validation sebelum kirim OTP
- ✅ Trim whitespace

### Password Requirements
- ✅ Minimum 8 karakter
- ✅ Harus mengandung uppercase letter
- ✅ Harus mengandung lowercase letter
- ✅ Harus mengandung angka

---

## ⚠️ Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Gagal mengirim OTP` | EmailJS credential salah | Verifikasi Service ID, Template ID, API keys |
| `OTP telah expired` | User terlalu lama menginput | Resend OTP |
| `Terlalu banyak percobaan` | User salah 5 kali | Resend OTP atau request new OTP |
| `Format email tidak valid` | Email invalid | Gunakan format email yang benar |
| `Tunggu X detik sebelum mengirim ulang` | Resend terlalu cepat | Tunggu minimal 30 detik |

---

## 🔧 Troubleshooting

### OTP tidak dikirim
1. Verifikasi EmailJS Service dan Template ID
2. Check email template di EmailJS dashboard
3. Verifikasi API keys sudah benar
4. Check email provider configuration

### OTP dikirim tapi ke folder Spam
1. Email template perlu lebih professional
2. Update template di EmailJS dengan sender name yang jelas
3. Add unsubscribe link (untuk production)

### Verification always fails
1. Pastikan OTP dikopikan dengan benar (tidak ada space)
2. Verifikasi OTPService singleton pattern
3. Check browser console untuk error details

### "User tidak ditemukan" saat reset password
1. Implement backend endpoint untuk reset password
2. Saat ini hanya support manual reset via FirebaseAuth

---

## 🚀 Production Checklist

- [ ] Ubah hardcoded credentials ke environment variables
- [ ] Implement backend endpoint untuk password reset
- [ ] Add logging untuk debug OTP issues
- [ ] Setup SMTP provider (Gmail, SendGrid, AWS SES)
- [ ] Implement rate limiting di backend
- [ ] Add email verification screen sebelum OTP
- [ ] Setup SSL/TLS untuk komunikasi dengan EmailJS
- [ ] Test dengan berbagai email providers
- [ ] Add CAPTCHA untuk prevent brute force
- [ ] Implement backup codes untuk account recovery
- [ ] Setup monitoring untuk failed OTP attempts

---

## 📝 Testing

### Test Cases

1. **Valid OTP**
   - Input correct OTP → Should succeed
   - Verify at `/EnterOTP` screen → Should navigate to `/ResetPassword`

2. **Invalid OTP**
   - Input wrong OTP → Should show error
   - Show remaining attempts → Decrease on each attempt
   - After 5 attempts → Should show "too many attempts" error

3. **OTP Expiry**
   - Wait 10 minutes → OTP should expire
   - Resend OTP → Should generate new OTP

4. **Resend Limitations**
   - Resend before 30 seconds → Should show countdown error
   - After 30 seconds → Should allow resend

5. **Email Validation**
   - Invalid email format → Should show error
   - Empty email → Should show error

---

## 📞 Support

Jika ada masalah:
1. Check console log untuk error messages
2. Verify EmailJS configuration
3. Test email template di EmailJS dashboard
4. Ensure internet connection
5. Check Firebase auth configuration

---

Generated: May 29, 2026
Version: 1.0.0
