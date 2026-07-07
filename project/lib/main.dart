import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // tambahan untuk kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'firebase_options.dart';

import 'screens/Splashscreen.dart';
import 'screens/Splashscreen2.dart';
import 'screens/SignIn.dart';
import 'screens/SignUp.dart';
import 'screens/ForgetPassword.dart';
import 'screens/EnterOTP.dart';
import 'screens/ResetPassword.dart';
import 'screens/Dashboard.dart';
import 'screens/History.dart';
import 'screens/Userprofile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi OneSignal
  if (!kIsWeb) {
    OneSignal.initialize('f2c1a619-50be-4deb-b3d1-7602cac3f8e1');
    await OneSignal.Notifications.requestPermission(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/Splashscreen',
      routes: {
        '/Splashscreen': (context) => const SplashScreen(),
        '/Splashscreen2': (context) => const SplashScreen2(),
        '/SignIn': (context) => const SignIn(),
        '/SignUp': (context) => const SignUp(),
        '/ForgetPassword': (context) => const ForgetPassword(),
        '/EnterOTP': (context) => const EnterOTP(),
        '/ResetPassword': (context) => const ResetPassword(),
        '/Dashboard': (context) => const Dashboard(),
        '/Userprofile': (context) => const Userprofile(),
        '/History': (context) => const History(),
      },
    );
  }
}
