import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/inital/Display/DisplayUserEvents.dart';
import 'package:frontend/inital/Display/DisplayUserPolls.dart';
import 'package:frontend/inital/Display/DisplayUserPosts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedSection = 0;
  List<Map<String, dynamic>> joinedGroups = [];
  List<String>? groupNames;
  bool isLoading = true;
  String? fullName;
  String? email;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchAndStoreUserDetails();
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
      print("response code homepage");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print(userData);
        userId = userData['_id'];
        fullName = '${userData['firstName']} ${userData['lastName']}';
        email = userData['email'];
        groupNames = (userData['groups'] as List)
            .map((group) => group['name'] as String)
            .toList();

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Save details to SharedPreferences
        await prefs.setString('userId', userId!);
        await prefs.setString('fullName', fullName!);
        await prefs.setString('email', email!);
        await prefs.setStringList('groupNames', groupNames!);
        print(fullName);

        setState(() {});
        _checkUserSession();
      } else {
        print('Failed to fetch user details: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(milliseconds: 300));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? email = prefs.getString('email');
    String? token = prefs.getString('token');

    print(email);
    print(token);
    print(userId);

    if (userId == "" || email == "" || token == "") {
      _showSnackbar("User session not found. Redirecting to login.");
      GoRouter.of(context).goNamed('options');
      return;
    }

    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    if (userId == null || token == null) {
      _showSnackbar("User ID or token not found. Please log in again.",
          isError: true);
      setState(() {
        isLoading = false;
      });
      GoRouter.of(context).goNamed('options');
      return;
    }

    try {
      final url = Uri.parse('${Constants.serverUrl}/api/user/groups/$userId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          joinedGroups = List<Map<String, dynamic>>.from(
            data['groups'].map((group) => {
                  'id': group['id'],
                  'name': group['name'],
                  'code': group['code'] ?? 'No code'
                }),
          );
          groupNames =
              joinedGroups.map((group) => group['name'] as String).toList();
          isLoading = false;
        });

        await prefs.setStringList('groupNames', groupNames!);
        await prefs.setStringList('groupIds',
            joinedGroups.map((group) => group['id'] as String).toList());
        await prefs.setStringList('groupCodes',
            joinedGroups.map((group) => group['code'] as String).toList());
      } else {
        _showSnackbar("Failed to fetch groups: ${response.reasonPhrase}",
            isError: true);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackbar("Error fetching groups: $e", isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _getSectionContent() {
    switch (_selectedSection) {
      case 0:
        return const DisplayUserEvents();
      case 1:
        return const DisplayUserPosts();
      case 2:
        return const Center(
            child: Text('Payments Section', style: TextStyle(fontSize: 18)));
      case 3:
        return const DisplayUserPolls();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8ECE0),
        elevation: 0,
        title: const Text(
          "Zeeko",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              GoRouter.of(context).goNamed('about');
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSectionButton("Events", 0),
                      _buildSectionButton("Posts", 1),
                      _buildSectionButton("Payments", 2),
                      _buildSectionButton("Polls", 3),
                    ],
                  ),
                ),
                Expanded(child: _getSectionContent()),
              ],
            ),
    );
  }

  Widget _buildSectionButton(String title, int index) {
    return OutlinedButton(
      onPressed: () => setState(() => _selectedSection = index),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            _selectedSection == index ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: _selectedSection == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
