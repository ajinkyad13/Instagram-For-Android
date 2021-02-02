import 'package:assignment2/signInScreen.dart';
import 'package:assignment2/signUpScreen.dart';
import 'package:flutter/material.dart';
import 'dart:io';

// overriding http certificates
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  runApp(new MyApp());
}

// main
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final primaryColor = const Color(0xFF151026);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/signIn': (BuildContext context) => SignInPage(),
      },
      title: 'Assignment 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignUpPage(),
    );
  }
}
