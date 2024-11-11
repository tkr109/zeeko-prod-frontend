import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/event_card.dart';
import 'package:frontend/widgets/section_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayUserEvents extends StatefulWidget {
  const DisplayUserEvents({Key? key}) : super(key: key);

  @override
  _DisplayUserEventsState createState() => _DisplayUserEventsState();
}

class _DisplayUserEventsState extends State<DisplayUserEvents> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  List<String> groupIds = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchEvents();
  }

  Future<void> _loadUserDataAndFetchEvents() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    groupIds = prefs.getStringList('groupIds') ?? []; // Use group IDs

    if (userId != null && groupIds.isNotEmpty) {
      await fetchUserEvents();
    } else {
      print("User ID or Group IDs not found in SharedPreferences");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserEvents() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.serverUrl}/api/group/userSubgroupEvents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'groupIds': groupIds,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> eventList = json.decode(response.body)['events'];
        print(response);
        setState(() {
          events = eventList
              .map((e) => {
                    "title": e['title'],
                    "date": formatDate(e['timings']),
                    "location": e['location'],
                    "imageUrl":
                        e['bannerImage'] ?? 'https://via.placeholder.com/150',
                    "description": e['description'],
                    "responses": e['responses'] ?? {},
                    "isAcceptingResponses": e['isAcceptingResponses'],
                  })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (error) {
      print("Error fetching events: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    final DateTime eventDate = DateTime.parse(dateStr);
    return "${eventDate.day} ${getMonth(eventDate.month)} ${eventDate.year}";
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
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(title: 'This week'),
                    ...events.map((event) => EventCard(
                          title: event['title'],
                          date: event['date'],
                          location: event['location'],
                          imageUrl: event['imageUrl'],
                          onTap: () {
                            // Define your onTap behavior here, like navigating to event details
                          },
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}
