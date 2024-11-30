import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/section_tile.dart';
import '../../widgets/event_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class DisplayGroupEvent extends StatefulWidget {
  final String groupId;
  final String subgroupId;

  const DisplayGroupEvent(
      {required this.groupId, required this.subgroupId, super.key});

  @override
  _DisplayGroupEventState createState() => _DisplayGroupEventState();
}

class _DisplayGroupEventState extends State<DisplayGroupEvent> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse(
          '${Constants.serverUrl}/api/group/events/${widget.groupId}/${widget.subgroupId}'));

      if (response.statusCode == 200) {
        final List<dynamic> eventList = json.decode(response.body)['events'];

        setState(() {
          events = eventList.map((e) {
            final bannerImage = e['bannerImage'] ?? '';
            final isBase64Image = bannerImage.isNotEmpty &&
                bannerImage.startsWith('/9j'); // Check for base64 format

            return {
              "id": e['_id'],
              "title": e['title'],
              "date": formatDate(e['timings']),
              "location": e['location'],
              "image": isBase64Image ? bannerImage : null, // Save base64 string
              "imageUrl": isBase64Image
                  ? null
                  : bannerImage.isNotEmpty
                      ? bannerImage
                      : 'https://via.placeholder.com/150', // Default URL
              "responses": e['responses'],
              "duration": e['duration'],
              "description": e['description'],
              "isAcceptingResponses": e['isAcceptingResponses'],
              "isVisible": e['isVisible'],
              "comments": e['comments'] ?? []
            };
          }).toList();
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
    final DateTime today = DateTime.now();

    if (eventDate.year == today.year &&
        eventDate.month == today.month &&
        eventDate.day == today.day) {
      return "Today at ${eventDate.hour}:${eventDate.minute.toString().padLeft(2, '0')}";
    } else {
      return "${eventDate.day} ${getMonth(eventDate.month)} at ${eventDate.hour}:${eventDate.minute.toString().padLeft(2, '0')}";
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'This Week'),
                    ...events.map((event) => EventCard(
                          id: event['id'],
                          title: event['title'],
                          date: event['date'],
                          location: event['location'],
                          image: event['image'], // Pass base64 string
                          imageUrl: event['imageUrl'], // Pass URL
                          onTap: () {
                            context.goNamed(
                              'eventDetails', // Replace with the route name for `DisplayUserEvents`
                              pathParameters: {'eventId': event['id']},
                            );
                          },
                        )),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.pending_actions),
                        label: const Text('Awaiting Response'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
