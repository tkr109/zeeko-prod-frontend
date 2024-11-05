import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/groupInfo/Display/DisplayGroupEvent.dart';
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
  String groupName = "Loading...";
  int memberCount = 0;
  bool isLoading = true;
  int _selectedSection = 0; // 0 = Events, 1 = Posts, 2 = Payments, 3 = Polls
  bool _isAdmin = false;
  List<Map<String, dynamic>> _subgroups = []; // Store fetched subgroups
  bool _subgroupsLoading = false; // Loading state for subgroups

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final url = Uri.parse(
          '${Constants.serverUrl}/api/group/groupDetails/${widget.groupId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          groupName = data['groupName'] ?? 'Unnamed Group';
          memberCount = data['memberCount'] ?? 0;
          isLoading = false;
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

  // Fetch subgroups from the backend and handle loading state in the drawer
  Future<void> fetchAndDisplaySubgroups(StateSetter setModalState) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/subgroups/${widget.groupId}');

    setModalState(() {
      _subgroupsLoading = true; // Start loading
    });

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setModalState(() {
          _subgroups = List<Map<String, dynamic>>.from(data['subgroups']);
          _subgroupsLoading = false; // Data loaded
        });
      } else {
        setModalState(() {
          _subgroupsLoading = false; // Stop loading on error
        });
        _showSnackBar('Failed to load subgroups');
      }
    } catch (e) {
      setModalState(() {
        _subgroupsLoading = false;
      });
      _showSnackBar('Error loading subgroups');
    }
  }

  // Method to show bottom drawer with main categories and subgroup selection in the same flow
  void _showBottomDrawer() {
    bool showingSubgroups = false;
    String selectedCategory = "";
    String selectedSubgroupId = "";

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      showingSubgroups
                          ? "Select Subgroup for $selectedCategory"
                          : "Choose an Option",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (!showingSubgroups) ...[
                    _buildDrawerItem(
                      icon: Icons.event,
                      text: "Events",
                      onTap: () {
                        setModalState(() {
                          showingSubgroups = true;
                          selectedCategory = "Events";
                        });
                        fetchAndDisplaySubgroups(setModalState);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.post_add,
                      text: "Posts",
                      onTap: () {
                        setModalState(() {
                          showingSubgroups = true;
                          selectedCategory = "Posts";
                        });
                        fetchAndDisplaySubgroups(setModalState);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.poll,
                      text: "Polls",
                      onTap: () {
                        setModalState(() {
                          showingSubgroups = true;
                          selectedCategory = "Polls";
                        });
                        fetchAndDisplaySubgroups(setModalState);
                      },
                    ),
                  ] else if (_subgroupsLoading) ...[
                    Center(child: CircularProgressIndicator())
                  ] else if (_subgroups.isNotEmpty) ...[
                    for (var subgroup in _subgroups)
                      _buildDrawerItem(
                        icon: Icons.group,
                        text: subgroup['name'],
                        onTap: () {
                          Navigator.pop(context); // Close the drawer
                          if (selectedCategory == "Posts") {
                            context.push(
                                '/home/groups/group-details/${widget.groupId}/add-post/${subgroup['id']}');
                          } else if (selectedCategory == "Polls") {
                            context.push(
                                '/home/groups/group-details/${widget.groupId}/add-poll/${subgroup['id']}');
                          } else if (selectedCategory == "Events") {
                            context.push(
                                '/home/groups/group-details/${widget.groupId}/add-event/${subgroup['id']}');
                          }
                        },
                      ),
                  ] else ...[
                    Center(child: Text("No subgroups available")),
                  ],
                  if (showingSubgroups)
                    ListTile(
                      leading: Icon(Icons.arrow_back),
                      title: Text("Back"),
                      onTap: () {
                        setModalState(() {
                          showingSubgroups = false;
                        });
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Method to get the content for each section
  Widget _getSectionContent() {
    switch (_selectedSection) {
      case 0:
        return DisplayGroupEvent();
      case 1:
        return Center(
            child: Text('No Posts available',
                style: TextStyle(fontSize: 16, color: Colors.grey)));
      case 2:
        return Center(
            child: Text('Payments Section',
                style: TextStyle(fontSize: 16, color: Colors.grey)));
      case 3:
        return Center(
            child: Text('Polls Section',
                style: TextStyle(fontSize: 16, color: Colors.grey)));
      default:
        return Container();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          groupName,
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Text('User', style: TextStyle(color: Colors.black)),
              Switch(
                value: _isAdmin,
                onChanged: (value) => setState(() => _isAdmin = value),
                activeColor: Colors.black,
              ),
              Text('Admin', style: TextStyle(color: Colors.black)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section with group name, member count, and buttons
          Container(
            color: Color(0xFFF8ECE0),
            padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 4),
                Text(
                  "$memberCount members",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopButton("Members", () {
                      context.push(
                          '/home/groups/group-details/${widget.groupId}/membership');
                    }),
                    SizedBox(width: 20),
                    _buildTopButton("Subgroups", () {
                      context.push(
                          '/home/groups/group-details/${widget.groupId}/subgroups'); // Navigate to SubgroupsPage
                    }),
                  ],
                ),
              ],
            ),
          ),
          // Section navigation buttons (Events, Posts, Payments, Polls)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
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
          Expanded(child: _getSectionContent()), // Content for each section
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomDrawer,
        backgroundColor: Color(0xFFF8ECE0),
        child: Icon(Icons.add),
      ),
    );
  }

  // Button builder for Members and Subgroups
  Widget _buildTopButton(String title, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        side: BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        title,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Button builder for Events, Posts, Payments, Polls
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
            color: _selectedSection == index ? Colors.white : Colors.black),
      ),
    );
  }

  // Helper to create list items in the bottom drawer
  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }
}
