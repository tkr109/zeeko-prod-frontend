import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  GroupDetailsPage({required this.groupId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  String groupName = "Loading..."; // Default text while data loads
  int memberCount = 0; // Default member count
  bool isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  // Function to fetch group details
  Future<void> _fetchGroupDetails() async {
    print(widget.groupId);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Retrieve the token from SharedPreferences

    try {
      final url = Uri.parse(
          '${Constants.serverUrl}/api/group/groupDetails/${widget.groupId}'); // Replace with actual URL

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Include the token in the header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          groupName = data['groupName'] ?? 'Unnamed Group';
          memberCount = data['memberCount'] ?? 0;
          isLoading = false; // Data is loaded
        });
      } else {
        setState(() {
          groupName = 'Error loading group';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        groupName = 'Error loading group';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF8ECE0),
        toolbarHeight: 40,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: null,
        actions: [
          Row(
            children: [
              Text('User', style: TextStyle(color: Colors.black)),
              Switch(
                value: false, // Dummy value for admin toggle
                onChanged: (value) {
                  // Toggle admin status
                },
                activeColor: Colors.black,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text('Admin', style: TextStyle(color: Colors.black)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section with group name, members, and buttons
          Container(
            color: Color(0xFFF8ECE0),
            padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isLoading ? "Loading..." : groupName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isLoading ? "Fetching members..." : "$memberCount members",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Members button
                    OutlinedButton(
                      onPressed: () {
                        context.push(
                            '/home/groups/group-details/${widget.groupId}/membership');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Members",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    SizedBox(width: 75),
                    // Subgroups button
                    OutlinedButton(
                      onPressed: () {
                        // Handle Subgroups button press
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Subgroups",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Additional content here (e.g., posts, polls, events) as per section selection
        ],
      ),
    );
  }
}
