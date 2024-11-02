import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final TextEditingController codeController = TextEditingController();
  List<Map<String, dynamic>> joinedGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchUserJoinedGroups();
  }

  // Function to fetch the joined groups of the user using the user ID
  Future<void> _fetchUserJoinedGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId =
        prefs.getString('userId'); // Retrieve user ID from SharedPreferences
    String? token =
        prefs.getString('token'); // Retrieve token for authentication

    if (userId == null || token == null) {
      showSnackbar(context, "User ID or token not found. Please log in again.",
          isError: true);
      return;
    }

    try {
      final url =
          Uri.parse('http://192.168.100.12:5000/api/user/groups/$userId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Send token for authentication
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          joinedGroups = List<Map<String, dynamic>>.from(data['groups']);
        });
      } else {
        showSnackbar(context, "Failed to fetch groups.", isError: true);
      }
    } catch (e) {
      showSnackbar(context, "Error occurred: $e", isError: true);
    }
  }

  Future<void> sendPendingRequest(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve email, name, and token from shared preferences
    String? email = prefs.getString('email');
    String? fullName = prefs.getString('fullName');
    String? token = prefs.getString('token');
    String groupCode = codeController.text;

    // Check if all necessary data is present
    if (email == null ||
        fullName == null ||
        token == null ||
        groupCode.isEmpty) {
      showSnackbar(context, "Missing required information.", isError: true);
      return;
    }

    if (groupCode.length != 6) {
      showSnackbar(context, "Please enter a complete 6-digit code.",
          isError: true);
      return;
    }

    try {
      final url =
          Uri.parse('http://192.168.100.12:5000/api/group/addPendingRequest');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send token in headers
        },
        body: jsonEncode({
          'groupCode': groupCode,
          'name': fullName,
          'email': email,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        showSnackbar(context, responseData['msg'], isError: false);
      } else {
        showSnackbar(context, responseData['msg'] ?? 'Failed to send request',
            isError: true);
      }
    } catch (e) {
      showSnackbar(context, "Error occurred: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFF8ECE0),
        elevation: 0,
        title: Text(
          "Groups",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Icon(Icons.notifications, color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 18,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20), // Add 20px gap from AppBar
                    Text(
                      "Groups Joined",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: joinedGroups.map((group) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              context.go(
                                  '/home/group-details/${group['id']}'); // Navigate to dynamic route
                            },
                            child: GroupCircle(title: group['name']),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Do you have a group code?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                              6), // Limit to 6 digits
                        ],
                        decoration: InputDecoration(
                          labelText: "Enter 6-digit group code",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (codeController.text.length == 6) {
                          sendPendingRequest(context);
                        } else {
                          showSnackbar(
                              context, "Please enter a complete 6-digit code.",
                              isError: true);
                        }
                      },
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSnackbar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? Colors.redAccent : Colors.greenAccent,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCircle extends StatelessWidget {
  final String title;

  GroupCircle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          child: Text(
            title[0],
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(title, style: TextStyle(fontWeight: FontWeight.normal)),
      ],
    );
  }
}
