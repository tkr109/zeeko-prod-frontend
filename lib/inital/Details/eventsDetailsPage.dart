import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  Map<String, dynamic>? eventDetails;
  bool isLoading = true;
  TextEditingController _commentController =
      TextEditingController(); // Controller for comment input

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  @override
  void dispose() {
    _commentController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }

  Future<void> _fetchEventDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse(
          '${Constants.serverUrl}/api/event/details/${widget.eventId}');
      final httpResponse = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(httpResponse);

      if (httpResponse.statusCode == 200) {
        setState(() {
          eventDetails = json.decode(httpResponse.body);
          isLoading = false;
        });
      } else {
        _showSnackbar("Failed to load event details", isError: true);
      }
    } catch (error) {
      _showSnackbar("Error fetching event details: $error", isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      _showSnackbar('Comment cannot be empty', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    final userName = prefs.getString(
        'userName'); // Ensure userName is stored in SharedPreferences

    if (userId == null || userName == null) {
      _showSnackbar('User not logged in', isError: true);
      return;
    }

    try {
      final url = Uri.parse(
          '${Constants.serverUrl}/api/event/addComment/${widget.eventId}');
      final httpResponse = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'userName': userName,
          'content': commentText,
        }),
      );

      if (httpResponse.statusCode == 200) {
        _showSnackbar('Comment added successfully!');
        _commentController.clear();
        _fetchEventDetails(); // Refresh event details to get updated comments
      } else {
        final responseBody = json.decode(httpResponse.body);
        _showSnackbar(responseBody['message'] ?? 'Failed to add comment',
            isError: true);
      }
    } catch (error) {
      _showSnackbar('Error adding comment: $error', isError: true);
    }
  }

  Future<void> _submitResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (userId == null) {
      _showSnackbar("User not logged in", isError: true);
      return;
    }

    try {
      final url = Uri.parse(
          '${Constants.serverUrl}/api/event/respond/${widget.eventId}');
      final httpResponse = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'response': userResponse,
        }),
      );

      if (httpResponse.statusCode == 200) {
        _showSnackbar("Response submitted successfully!");
        _fetchEventDetails(); // Refresh the event details after submission
      } else {
        final responseBody = json.decode(httpResponse.body);
        _showSnackbar(responseBody['message'] ?? "Failed to submit response",
            isError: true);
      }
    } catch (error) {
      _showSnackbar("Error submitting response: $error", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Banner Image with Placeholder
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: NetworkImage(
                                eventDetails?['bannerImage'] ??
                                    'https://via.placeholder.com/150',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Event Title
                        Text(
                          eventDetails?['title'] ?? 'Event Title',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Host Information
                        Text(
                          'Host: ${eventDetails?['hostName'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Event Timing
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              'Meet: ${eventDetails?['timings'] ?? 'Date & Time'}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Event Location
                        Row(
                          children: [
                            Icon(Icons.location_pin, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              eventDetails?['location'] ??
                                  'Location not specified',
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Event Description
                        Text(
                          'Description',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          eventDetails?['description'] ??
                              'No description provided.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 30),

                        // Responses Summary
                        Divider(),
                        Text(
                          'Responses',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text(
                              '${eventDetails?['responses']['attending'] ?? 0} attending'),
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.help_outline, color: Colors.orange),
                          title: Text(
                              '${eventDetails?['responses']['unanswered'] ?? 0} unanswered'),
                        ),
                        ListTile(
                          leading: Icon(Icons.cancel, color: Colors.red),
                          title: Text(
                              '${eventDetails?['responses']['declined'] ?? 0} declined'),
                        ),

                        // Comments Section
                        Divider(),
                        Text(
                          'Comments',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        // Display comments
                        eventDetails?['comments'] != null &&
                                eventDetails!['comments'].isNotEmpty
                            ? Column(
                                children: List.generate(
                                    eventDetails!['comments'].length, (index) {
                                  final comment =
                                      eventDetails!['comments'][index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(comment['userName'][0]
                                          .toUpperCase()), // Display first letter of user name
                                    ),
                                    title: Text(comment['userName']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(comment['content']),
                                        SizedBox(height: 5),
                                        Text(
                                          comment['timestamp'] ?? '',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              )
                            : Text('No comments yet.'),
                        SizedBox(height: 20),
                        // Add Comment Input
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            labelText: 'Add a comment',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        // Submit Comment Button
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: Text('Submit Comment'),
                        ),
                        SizedBox(height: 100), // Extra space at the bottom
                      ],
                    ),
                  ),
                ),

                // Floating Action Buttons for Responses
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _submitResponse("Attending"),
                        label: Text('Attend'),
                        icon: Icon(Icons.check),
                        backgroundColor: Colors.green,
                      ),
                      FloatingActionButton.extended(
                        onPressed: () => _submitResponse("Declined"),
                        label: Text('Decline'),
                        icon: Icon(Icons.close),
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
