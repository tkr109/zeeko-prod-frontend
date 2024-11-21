import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  Map<String, dynamic>? eventDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
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
                              onError: (error, stackTrace) => Image.asset(
                                'assets/placeholder.png',
                                fit: BoxFit.cover,
                              ),
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

  Future<void> _submitResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId =
        prefs.getString('userId'); // Retrieve userId from SharedPreferences

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
}
