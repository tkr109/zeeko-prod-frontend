import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

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

  Future<void> _fetchUserJoinedGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    if (userId == null || token == null) {
      showSnackbar(context, "User ID or token not found. Please log in again.",
          isError: true);
      return;
    }

    try {
      final url = Uri.parse('${Constants.serverUrl}/api/user/groups/$userId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

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

    String? email = prefs.getString('email');
    String? fullName = prefs.getString('fullName');
    String? token = prefs.getString('token');
    String groupCode = codeController.text;

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
          Uri.parse('${Constants.serverUrl}/api/group/addPendingRequest');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
        backgroundColor: const Color(0xFFF8ECE0),
        elevation: 0,
        title: const Text(
          "Groups",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [
          Icon(Icons.notifications, color: Colors.black),
          Padding(
            padding: EdgeInsets.all(8.0),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Groups Joined",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two items per row
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1, // Square items
                      ),
                      itemCount: joinedGroups.length,
                      itemBuilder: (context, index) {
                        final group = joinedGroups[index];
                        return GestureDetector(
                          onTap: () {
                            context.push(
                                '/home/groups/group-details/${group['id']}');
                          },
                          child: GroupCircle(title: group['name']),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Do you have a group code?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
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
                      icon: const Icon(Icons.arrow_forward),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
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

  const GroupCircle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          child: Text(
            title[0],
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontWeight: FontWeight.normal)),
      ],
    );
  }
}
