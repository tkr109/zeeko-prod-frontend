import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/groupInfo/Display/DisplayGroupEvent.dart';
import 'package:frontend/groupInfo/Display/DisplayGroupPosts.dart';
import 'package:frontend/groupInfo/Display/DisplayPollsPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  String groupName = "Loading...";
  int memberCount = 0;
  int groupcode = 0;
  bool isLoading = true;
  int _selectedSection = 0; // 0 = Events, 1 = Posts, 2 = Payments, 3 = Polls
  bool _isAdmin = false;
  List<Map<String, dynamic>> _subgroups = []; // Store fetched subgroups
  bool _subgroupsLoading = false; // Loading state for subgroups
  String? selectedSubgroupId; // Store selected subgroup ID
  String? userSubgroup;
  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    _getUserSubgroup();
    _checkAdminStatus();

    print(_isAdmin);
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

      print("------groupdetails--------");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debugging the decoded data structure
        print("Decoded Data: $data");

        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            groupName = data['groupName'] ?? 'Unnamed Group';
            memberCount = data['memberCount'] ?? 0;

            // Check if groupcode is a string and convert to int
            var code = data['code'];
            if (code is String) {
              groupcode =
                  int.tryParse(code) ?? 0; // If it's a string, parse it to int
            } else {
              groupcode = code ?? 0; // Use code directly if it's already an int
            }

            isLoading = false;
          });
        } else {
          setState(() {
            groupName = 'Invalid response format';
            isLoading = false;
            groupcode = 0;
          });
        }
      } else {
        // Handle HTTP errors
        setState(() {
          groupName = 'Error loading group';
          isLoading = false;
          groupcode = 0;
        });
      }
    } catch (e) {
      // Handle exceptions
      print("Exception: $e");
      setState(() {
        groupName = 'Error loading group';
        isLoading = false;
        groupcode = 0;
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/isAdmin/${widget.groupId}/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('resp: $response');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Admin check");
        print(data);
        setState(() {
          _isAdmin = data['isAdmin'] ?? false;
        });
      } else {
        setState(() {
          _isAdmin = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAdmin = false;
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

  Future<void> _getUserSubgroup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');
    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/userSubgroups/${widget.groupId}/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userSubgroup = data['subgroup']['subgroupId'];
          print(userSubgroup); // Store the subgroup ID
        });
      } else {
        _showSnackBar('Failed to load user subgroup');
      }
    } catch (e) {
      _showSnackBar('Error loading user subgroup');
    }
  }

  // Method to show bottom drawer with main categories and subgroup selection in the same flow
  void _showBottomDrawer() {
    bool showingSubgroups = false;
    String selectedCategory = "";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!showingSubgroups) ...[
                    // Show "Events" only for admins
                    if (_isAdmin)
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
                    // Always show "Posts" and "Polls" for all users
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
                    const Center(child: CircularProgressIndicator())
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
                          } else if (selectedCategory == "Events" && _isAdmin) {
                            context.push(
                                '/home/groups/group-details/${widget.groupId}/add-event/${subgroup['id']}');
                          } else if (selectedCategory == "Events") {
                            _showSnackBar("Only admins can add events.");
                          }
                        },
                      ),
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "No subgroups available",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8), // Add spacing between the texts
                          Text(
                            "Please create a subgroup from the subgroups tab.",
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showingSubgroups)
                    ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: const Text("Back"),
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade800,
      ),
    );
  }

  // Method to get the content for each section
  Widget _getSectionContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selectedSection) {
      case 0:
        if (userSubgroup != null) {
          return DisplayGroupEvent(
            groupId: widget.groupId,
            subgroupId: userSubgroup!,
            isAdmin: _isAdmin,
          );
        } else if (userSubgroup == null && _isAdmin) {
          print("Navigating to DisplayGroupEvent with isAdmin: $_isAdmin");
          return DisplayGroupEvent(
            groupId: widget.groupId,
            subgroupId: "universal",
            isAdmin: _isAdmin,
          );
        } else {
          return const Center(
              child: Text('Please select a subgroup for Events'));
        }
      case 1:
        if (userSubgroup != null && widget.groupId.isNotEmpty) {
          return DisplayGroupPosts(
              groupId: widget.groupId,
              subgroupId: userSubgroup!,
              isAdmin: _isAdmin);
        } else if (userSubgroup == null && _isAdmin) {
          return DisplayGroupPosts(
              groupId: widget.groupId,
              subgroupId: "universal",
              isAdmin: _isAdmin);
        } else {
          return const Center(
              child: Text('Please select a valid subgroup for Events'));
        }
      case 2:
        return const Center(
            child: Text('Payments Section',
                style: TextStyle(fontSize: 16, color: Colors.grey)));
      case 3:
        if (userSubgroup != null && widget.groupId.isNotEmpty) {
          return DisplayPollsPage(
              groupId: widget.groupId,
              subgroupId: userSubgroup!,
              isAdmin: _isAdmin);
        } else if (userSubgroup == null && _isAdmin) {
          return DisplayPollsPage(
              groupId: widget.groupId,
              subgroupId: "universal",
              isAdmin: _isAdmin);
        } else {
          return const Center(
              child: Text('Please select a valid subgroup for Events'));
        }
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8ECE0),
        toolbarHeight: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          groupName,
          style: const TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   Row(
        //     children: [
        //       const Text('User', style: TextStyle(color: Colors.black)),
        //       Switch(
        //         value: _isAdmin,
        //         onChanged: (value) => setState(() => _isAdmin = value),
        //         activeColor: Colors.black,
        //       ),
        //       const Text('Admin', style: TextStyle(color: Colors.black)),
        //     ],
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Top section with group name, member count, and buttons
          Container(
            color: const Color(0xFFF8ECE0),
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Align content to the center
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    // Add spacing between the name and code
                    if (_isAdmin) // Display the code only if the user is an admin
                      Text(
                        '#$groupcode', // Display the code with a '#' prefix
                        style: const TextStyle(
                          fontSize:
                              13, // Adjusted font size for better visibility
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$memberCount members",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopButton("Members", () {
                      context.push(
                          '/home/groups/group-details/${widget.groupId}/membership');
                    }),
                    const SizedBox(width: 20),
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
        onPressed: () {
          _showBottomDrawer(); // Allow admins to access the drawer
        },
        backgroundColor: const Color(0xFFF8ECE0),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Button builder for Members and Subgroups
  Widget _buildTopButton(String title, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        title,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        side: const BorderSide(color: Colors.black),
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
