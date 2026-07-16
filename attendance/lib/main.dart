import 'package:attendance/features/homepage.dart';
import 'package:attendance/features/login.dart';
import 'package:attendance/firebase_options.dart';
import 'package:attendance/services/session_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final hasSession = await SessionService().hasSession();
  runApp(MyApp(startLoggedIn: hasSession));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.startLoggedIn});

  final bool startLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: startLoggedIn ? const Homepage() : const Login(),
    );
  }
}
