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
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;

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
          members = List<Map<String, dynamic>>.from(
              data['members'].map((name) => {'name': name}));
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
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];
                      return PendingRequestCard(
                        name: request['name'],
                        email: request['email'],
                        date: formatDate(request['date']),
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
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return MemberCard(
                        name: member['name'],
                        role: _isMembersSelected ? 'Member' : 'Administrator',
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class MemberCard extends StatelessWidget {
  final String name;
  final String role;

  const MemberCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: role == 'Administrator' ? Text(role) : null,
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
