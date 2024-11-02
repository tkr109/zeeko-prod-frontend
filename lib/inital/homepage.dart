// lib/widgets/homepage.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  Future<Map<String, String?>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs
        .getString('email'); // Adjust this key based on your implementation
    final token = prefs
        .getString('token'); // Adjust this key based on your implementation

    return {
      'email': email,
      'token': token,
    };
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clear the authToken
    await prefs.remove('email'); // Clear the userEmail
    context.go('/options'); // Navigate back to options using GoRouter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading user info'));
          } else {
            final userInfo = snapshot.data!;
            final email = userInfo['email'] ?? 'No email found';
            final token = userInfo['token'] ?? 'No token found';

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to the Home Page!',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  Text('Email: $email'),
                  Text('Token: $token'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: Text('Logout'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
