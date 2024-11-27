import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:bakenation_customer/customer/login.dart';
import 'package:bakenation_customer/customer/signup.dart';
import 'package:bakenation_customer/database/firebase_options.dart';
//import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bake Nation',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? const CustomerFramePage()
          : const LoginPage(),
      routes: {
        '/homepage': (context) => const CustomerFramePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}
