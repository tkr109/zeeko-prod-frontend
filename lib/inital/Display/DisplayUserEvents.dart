import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/inital/Details/eventsDetailsPage.dart';
import 'package:frontend/widgets/event_card.dart';
import 'package:frontend/widgets/section_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

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

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      groupIds = prefs.getStringList('groupIds') ?? [];

      if (userId == null || groupIds.isEmpty) {
        print("User ID or Group IDs not found in SharedPreferences");
        _showSnackbar("User data not found. Please log in again.",
            isError: true);
        setState(() {
          isLoading = false;
        });
        return;
      }

      await fetchUserEvents();
    } catch (e) {
      print("Error loading user data: $e");
      _showSnackbar("Error loading user data.", isError: true);
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
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> eventList = responseData['events'] ?? [];

        setState(() {
          events = eventList.map<Map<String, dynamic>>((e) {
            return {
              "id": e['_id'] ?? '', // Safeguard against null
              "title": e['title'] ?? 'No Title',
              "date": formatDate(e['timings'] ?? ''),
              "location": e['location'] ?? 'No Location',
              "imageUrl": e['bannerImage'] ?? 'https://via.placeholder.com/150',
              "description": e['description'] ?? 'No Description',
              "responses": e['responses'] ?? {},
              "isAcceptingResponses": e['isAcceptingResponses'] ?? false,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print("Failed to load events. Status code: ${response.statusCode}");
        _showSnackbar("Failed to load events. Please try again.",
            isError: true);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching events: $error");
      _showSnackbar("Error fetching events.", isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    try {
      final DateTime eventDate = DateTime.parse(dateStr);
      return "${eventDate.day} ${getMonth(eventDate.month)} ${eventDate.year}";
    } catch (e) {
      print("Error parsing date: $e");
      return "Invalid Date";
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
    return (month > 0 && month <= 12) ? months[month - 1] : "Unknown";
  }

  void _showSnackbar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? Center(
                  child: Text(
                    "No events found.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: 'This week'),
                        ...events.map((event) {
                          final eventId = event['id'] ?? '';
                          return EventCard(
                            id: eventId,
                            title: event['title'],
                            date: event['date'],
                            location: event['location'],
                            imageUrl: event['imageUrl'],
                            onTap: () {
                              if (eventId.isNotEmpty) {
                                context.goNamed(
                                  'eventDetails', // Use the name defined in AppRouter
                                  pathParameters: {
                                    'eventId': eventId
                                  }, // Pass the eventId as a route parameter
                                );
                              } else {
                                _showSnackbar("Event ID is missing.",
                                    isError: true);
                              }
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
