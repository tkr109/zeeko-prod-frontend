import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MembershipPage extends StatefulWidget {
  final String groupId;

  const MembershipPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _MembershipPageState createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  bool _isMembersSelected = true;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> admins = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/groupMembers/${widget.groupId}');

    try {
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
          members = List<Map<String, dynamic>>.from(data['members']);
          admins =
              List<Map<String, dynamic>>.from(data['admins']); // Add this line
          pendingRequests =
              List<Map<String, dynamic>>.from(data['pendingRequests']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Failed to fetch data.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error occurred: $e");
    }
  }

  Future<void> _handleAcceptRequest(Map<String, dynamic> request) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final subgroupsUrl = Uri.parse(
        '${Constants.serverUrl}/api/group/subgroups/${widget.groupId}');
    final acceptUrl =
        Uri.parse('${Constants.serverUrl}/api/group/acceptRequest');

    try {
      // Fetch the list of subgroups
      final subgroupsResponse = await http.get(
        subgroupsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (subgroupsResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch subgroups.")),
        );
        return;
      }

      final subgroupsData = jsonDecode(subgroupsResponse.body);
      final subgroups =
          List<Map<String, dynamic>>.from(subgroupsData['subgroups']);

      // Show the subgroup selection dialog
      final selectedSubgroups = await _showSubgroupSelectionDialog(subgroups);

      if (selectedSubgroups == null || selectedSubgroups.isEmpty) {
        return;
      }

      // Prepare the request body for accepting the request
      final response = await http.post(
        acceptUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupId': widget.groupId,
          'email': request['email'],
          'subgroupIds': selectedSubgroups,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request accepted successfully.")),
        );
        setState(() {
          pendingRequests
              .removeWhere((req) => req['email'] == request['email']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to accept request.")),
        );
      }
      _fetchGroupData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error occurred while accepting request.")),
      );
    }
  }

  Future<List<String>?> _showSubgroupSelectionDialog(
      List<Map<String, dynamic>> subgroups) async {
    List<String> selectedSubgroupIds = [];

    return await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Subgroups"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: subgroups.map((subgroup) {
                    return CheckboxListTile(
                      title: Text(subgroup['name']),
                      value: selectedSubgroupIds.contains(subgroup['id']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedSubgroupIds.add(subgroup['id']);
                          } else {
                            selectedSubgroupIds.remove(subgroup['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                TextButton(
                  child: const Text("Confirm"),
                  onPressed: () =>
                      Navigator.of(context).pop(selectedSubgroupIds),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRejectRequest(Map<String, dynamic> request) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('${Constants.serverUrl}/api/group/deleteRequest');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupId': widget.groupId,
          'email': request['email'],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request rejected successfully.")),
        );
        // Optionally, refresh the data to update the UI
        setState(() {
          pendingRequests
              .removeWhere((req) => req['email'] == request['email']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to reject request.")),
        );
      }
      _fetchGroupData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error occurred while rejecting request.")),
      );
    }
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('dd-MMM-yyyy').format(parsedDate);
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
          'Membership',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Color(0xFFF8ECE0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => _isMembersSelected = true),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              _isMembersSelected ? Colors.black : Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          side: BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Members",
                          style: TextStyle(
                            color: _isMembersSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(width: 60),
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => _isMembersSelected = false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              !_isMembersSelected ? Colors.black : Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          side: BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Administrators",
                          style: TextStyle(
                            color: !_isMembersSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingRequests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                if (pendingRequests.isNotEmpty)
                  if (pendingRequests.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: pendingRequests.length,
                      itemBuilder: (context, index) {
                        final request = pendingRequests[index];
                        return Dismissible(
                          key: Key(request['email']),
                          background: _buildSwipeAction(
                              Icons.check, Colors.green, "Accept"),
                          secondaryBackground: _buildSwipeAction(
                              Icons.close, Colors.red, "Reject"),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _handleAcceptRequest(request);
                            } else {
                              _handleRejectRequest(request);
                            }
                            setState(() {
                              pendingRequests.removeAt(index);
                            });
                          },
                          child: PendingRequestCard(
                            name: request['name'],
                            email: request['email'],
                            date: formatDate(request['date']),
                          ),
                        );
                      },
                    ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isMembersSelected
                          ? 'Members List'
                          : 'Administrators List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount:
                        _isMembersSelected ? members.length : admins.length,
                    itemBuilder: (context, index) {
                      final user =
                          _isMembersSelected ? members[index] : admins[index];
                      return MemberCard(
                        name: "${user['fullName']}", // Updated for admins
                        email: user['email'],
                        role: _isMembersSelected ? 'Member' : 'Administrator',
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSwipeAction(IconData icon, Color color, String label) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class MemberCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const MemberCard({
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              role,
              style: TextStyle(color: Colors.grey[500]),
            ), // Always return Text
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(name[0]),
        ),
      ),
    );
  }
}

class PendingRequestCard extends StatelessWidget {
  final String name;
  final String email;
  final String date;

  const PendingRequestCard(
      {required this.name, required this.email, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(color: Colors.grey[700])),
            Text('Requested on: $date',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(name[0]),
        ),
      ),
    );
  }
}
