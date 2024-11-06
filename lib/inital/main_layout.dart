// lib/inital/main_layout.dart

import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/inital/groupspage.dart';
import 'package:frontend/inital/homepage.dart';
import 'package:frontend/inital/messagespage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({required this.child, Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String? fullName;
  String? email;
  String? userId; // Store the user's ID here
  List<String>? groupNames; // Only store group names

  @override
  void initState() {
    super.initState();
    _fetchAndStoreUserDetails();
  }

  Future<void> _fetchAndStoreUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email'); // Retrieve email from SharedPreferences
    if (email == null) {
      print("no email");
      return;
    }
    try {
      final url = Uri.parse('${Constants.serverUrl}/api/user/details');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        // Extract only the fields we need
        userId =
            userData['_id']; // Assuming backend returns '_id' as the user ID
        fullName = '${userData['firstName']} ${userData['lastName']}';
        email = userData['email'];
        // Extract only the group names
        groupNames = (userData['groups'] as List)
            .map((group) => group['name'] as String)
            .toList();
        // Save the required details to SharedPreferences
        await prefs.setString('userId', userId!);
        await prefs.setString('fullName', fullName!);
        await prefs.setString('email', email!);
        await prefs.setStringList('groupNames', groupNames!);
        print("----------------------");
        print("UserId: $userId");
        print("FullName: $fullName");
        print("Email: $email");
        print("Group Names: $groupNames");
        print("----------------------");
        // Update the state with the fetched details
        setState(() {});
      } else {
        print('Failed to fetch user details: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  final List<String> _tabs = ['/home', '/home/groups', '/home/messages'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    GoRouter.of(context).go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child, // Display the passed child widget
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }
}
