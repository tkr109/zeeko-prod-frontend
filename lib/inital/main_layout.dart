import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:go_router/go_router.dart';
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
  String? userId;
  List<String>? groupNames;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchUserDetails();
  }

  Future<void> _checkAuthAndFetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("check");
    print(token);
    if (token == null || token.isEmpty) {
      // Redirect to OptionsScreen if not authenticated
      print('main layout');
      GoRouter.of(context).go('/options');
      return;
    }

    print(token);

    // Fetch and store user details if authenticated
    await _fetchAndStoreUserDetails();
  }

  Future<void> _fetchAndStoreUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    print("mainlayout");
    if (email == null) {
      print("No email found in SharedPreferences");
      return;
    }
    try {
      final url = Uri.parse('${Constants.serverUrl}/api/user/details');
      print('main layout');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        userId = userData['_id'];
        fullName = '${userData['firstName']} ${userData['lastName']}';
        email = userData['email'];
        groupNames = (userData['groups'] as List)
            .map((group) => group['name'] as String)
            .toList();

        // Save details to SharedPreferences
        await prefs.setString('userId', userId!);
        await prefs.setString('fullName', fullName!);
        await prefs.setString('email', email!);
        await prefs.setStringList('groupNames', groupNames!);
        print(fullName);

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
