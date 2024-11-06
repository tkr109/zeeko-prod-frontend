import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/event_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DisplayUserEvents extends StatefulWidget {
  final List<String> groupIds;
  final String userId;

  const DisplayUserEvents({
    required this.groupIds,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  _DisplayUserEventsState createState() => _DisplayUserEventsState();
}

class _DisplayUserEventsState extends State<DisplayUserEvents> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserEvents();
  }

  Future<void> fetchUserEvents() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.serverUrl}/api/group/userSubgroupEvents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'groupIds': widget.groupIds,
          'userId': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> eventList = json.decode(response.body)['events'];

        setState(() {
          events = eventList
              .map((e) => {
                    "title": e['title'],
                    "date": formatDate(e['timings']),
                    "location": e['location'],
                    "imageUrl":
                        e['bannerImage'] ?? 'https://via.placeholder.com/150',
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
      appBar: AppBar(title: Text("User Events")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
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
