import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/section_tile.dart';
import 'package:frontend/widgets/poll_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/inital/Details/pollsDetailsPage.dart'; // Import your PollDetailsPage
import 'package:shared_preferences/shared_preferences.dart';

class DisplayPollsPage extends StatefulWidget {
  final String groupId;
  final String subgroupId;
  final bool isAdmin;
  const DisplayPollsPage({
    required this.groupId,
    required this.subgroupId,
    required this.isAdmin,
    super.key,
  });

  @override
  _DisplayPollsPageState createState() => _DisplayPollsPageState();
}

class _DisplayPollsPageState extends State<DisplayPollsPage> {
  List<Map<String, dynamic>> polls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPolls();
  }

  Future<void> fetchPolls() async {
    try {
      var response;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (widget.isAdmin && widget.subgroupId == "universal") {
        response = await http.get(Uri.parse(
            '${Constants.serverUrl}/api/group/admin/polls/${widget.groupId}/${userId}'));
      } else {
        response = await http.get(Uri.parse(
            '${Constants.serverUrl}/api/group/polls/${widget.groupId}/${widget.subgroupId}'));
      }
      print("poll reponse code");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? pollList = data['polls'];
        print("--polls--");
        print(data['polls']);
        setState(() {
          if (pollList != null) {
            polls = pollList.map((p) {
              return {
                "id": p['_id'] ?? '', // Ensure ID is passed
                "title": p['title']?.toString() ?? "Untitled Poll",
                "description": p['description']?.toString() ?? "No Description",
                "postedDate": formatDate(p['date']?.toString() ?? ""),
              };
            }).toList();
          } else {
            polls = [];
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load polls');
      }
    } catch (error) {
      print("Error fetching polls: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    try {
      final DateTime pollDate = DateTime.parse(dateStr);
      final DateTime today = DateTime.now();

      if (pollDate.year == today.year &&
          pollDate.month == today.month &&
          pollDate.day == today.day) {
        return "Today at ${pollDate.hour}:${pollDate.minute.toString().padLeft(2, '0')}";
      } else {
        return "${pollDate.day} ${getMonth(pollDate.month)} at ${pollDate.hour}:${pollDate.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      return "Unknown Date";
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: polls.length,
              itemBuilder: (context, index) {
                final poll = polls[index];
                final pollId = poll['id'] ?? '';

                if (pollId.isEmpty) {
                  return const SizedBox.shrink();
                }

                return PollCard(
                  title: poll['title'],
                  description: poll['description'],
                  postedDate: poll['postedDate'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PollDetailsPage(pollId: pollId),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
