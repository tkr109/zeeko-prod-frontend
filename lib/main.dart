import 'package:flutter/material.dart';
import 'package:frontend/onboarding/welcome_screen.dart';
// import 'package:frontend/screens/welcome_screen.dart'; // Import the WelcomeScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeeko',
      home: WelcomeScreen(), // Set WelcomeScreen as the home screen
    );
  }
}
