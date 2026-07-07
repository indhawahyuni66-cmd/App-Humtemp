# Button Code Examples

## 1. ForgetPassword - Continue Button with Validation

```dart
IntrinsicHeight(
  child: GestureDetector(
    onTap: () {
      if (textField1.isNotEmpty) {
        Navigator.pushNamed(context, '/EnterOTP');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan email atau nomor telepon'),
          ),
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Color(0xFF3461FD),
      ),
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 7,
        left: 24,
        right: 24,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            "Continue",
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 16,
            ),
          ),
          Container(
            color: Color(0xFF3461FD),
            height: 14,
            width: double.infinity,
            child: SizedBox(),
          ),
        ],
      ),
    ),
  ),
),
```

## 2. Back Button (All Screens)

```dart
GestureDetector(
  onTap: () => Navigator.pop(context),
  child: Container(
    margin: const EdgeInsets.only(bottom: 32, left: 24),
    width: 24,
    height: 24,
    child: Image.network(
      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/t8nh056n_expires_30_days.png",
      fit: BoxFit.fill,
    ),
  ),
),
```

## 3. EnterOTP - Reset Password Button

```dart
IntrinsicHeight(
  child: GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, '/ResetPassword');
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Color(0xFF3461FD),
      ),
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 7,
        left: 24,
        right: 24,
      ),
      margin: const EdgeInsets.only(
        bottom: 16,
        left: 24,
        right: 24,
      ),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            "Reset Password",
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 16,
            ),
          ),
          Container(
            color: Color(0xFF3461FD),
            height: 14,
            width: double.infinity,
            child: SizedBox(),
          ),
        ],
      ),
    ),
  ),
),
```

## 4. ResetPassword - Submit Button with Success Dialog

```dart
IntrinsicHeight(
  child: GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Berhasil'),
            content: Text('Password berhasil direset'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/SignIn',
                    (route) => false,
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Color(0xFF3461FD),
      ),
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 7,
        left: 24,
        right: 24,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 80),
            width: 24,
            height: 24,
            child: Image.network(
              "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/9kbyfwyi_expires_30_days.png",
              fit: BoxFit.fill,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 100),
            child: Text(
              "Submit",
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            color: Color(0xFF3461FD),
            height: 14,
            width: double.infinity,
            child: SizedBox(),
          ),
        ],
      ),
    ),
  ),
),
```

## Key Navigation Methods

### 1. Pop Back
```dart
Navigator.pop(context)
```
Goes back to the previous screen in the navigation stack.

### 2. Push Named (Forward)
```dart
Navigator.pushNamed(context, '/EnterOTP')
```
Navigates to a new screen and pushes it on the stack.

### 3. Push Named And Remove Until (Complete Flow)
```dart
Navigator.pushNamedAndRemoveUntil(
  context,
  '/SignIn',
  (route) => false,
)
```
Navigates to a new screen and removes all previous screens from the stack. This is used after successful password reset to prevent user from going back to the password reset screens.

## Error Handling

### SnackBar for Validation
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Masukkan email atau nomor telepon'),
  ),
);
```

### Dialog for Success
```dart
showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Berhasil'),
      content: Text('Password berhasil direset'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Additional navigation
          },
          child: Text('OK'),
        ),
      ],
    );
  },
);
```

## Integration in main.dart

```dart
routes: {
  '/SignIn': (context) => const SignIn(),
  '/SignUp': (context) => const SignUp(),
  '/ForgetPassword': (context) => const ForgetPassword(),
  '/EnterOTP': (context) => const EnterOTP(),
  '/ResetPassword': (context) => const ResetPassword(),
},
```

Make sure route names match exactly with what you use in `Navigator.pushNamed()` calls!
