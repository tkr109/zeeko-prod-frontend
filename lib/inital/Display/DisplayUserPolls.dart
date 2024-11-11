import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/poll_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayUserPolls extends StatefulWidget {
  const DisplayUserPolls({Key? key}) : super(key: key);

  @override
  _DisplayUserPollsState createState() => _DisplayUserPollsState();
}

class _DisplayUserPollsState extends State<DisplayUserPolls> {
  List<Map<String, dynamic>> polls = [];
  bool isLoading = true;
  String? userId;
  List<String> groupIds = [];

  @override
  void initState() {
    super.initState();
    _getUserDataAndFetchPolls();
  }

  Future<void> _getUserDataAndFetchPolls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    groupIds = prefs.getStringList('groupIds') ?? []; // List of groupIds

    if (userId != null && groupIds.isNotEmpty) {
      fetchUserPolls();
    } else {
      showSnackbar("User ID or group IDs not found in preferences.");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserPolls() async {
    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/group/userSubgroupPolls');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode({
          "userId": userId,
          "groupIds": groupIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          polls = List<Map<String, dynamic>>.from(data['polls'].map((poll) => {
                "title": poll['description'],
                "postedDate": formatDate(poll['createdAt']),
              }));
          isLoading = false;
        });
      } else {
        showSnackbar("Failed to fetch polls.");
        setState(() => isLoading = false);
      }
    } catch (error) {
      showSnackbar("Error: $error");
      setState(() => isLoading = false);
    }
  }

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? ''; // Retrieve the token
  }

  String formatDate(String dateStr) {
    final DateTime date = DateTime.parse(dateStr);
    return "${date.day} ${getMonth(date.month)} ${date.year}";
  }

  String getMonth(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: polls.length,
              itemBuilder: (context, index) {
                return PollCard(
                  title: polls[index]['title']!,
                  postedDate: polls[index]['postedDate']!,
                  onTap: () {
                    // Add any onTap functionality here, e.g., navigate to poll details
                  },
                );
              },
            ),
    );
  }
}
