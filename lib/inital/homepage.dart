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
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedSection = 0;
  List<Map<String, dynamic>> joinedGroups = [];
  List<String>? groupNames;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
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
        return DisplayUserEvents();
      case 1:
        return DisplayUserPosts();
      case 2:
        return Center(
            child: Text('Payments Section', style: TextStyle(fontSize: 18)));
      case 3:
        return DisplayUserPolls();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF8ECE0),
        elevation: 0,
        title: Text(
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
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
          ? Center(child: CircularProgressIndicator())
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
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        side: BorderSide(color: Colors.black),
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
