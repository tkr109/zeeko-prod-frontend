import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:typed_data';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  Map<String, dynamic>? eventDetails;
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
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

  Future<void> _submitResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (userId == null) {
      _showSnackbar('User not logged in', isError: true);
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
        _showSnackbar('Response submitted successfully!');
        _fetchEventDetails(); // Refresh event details to reflect new response
      } else {
        final responseBody = json.decode(httpResponse.body);
        _showSnackbar(responseBody['message'] ?? 'Failed to submit response',
            isError: true);
      }
    } catch (error) {
      _showSnackbar('Error submitting response: $error', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
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

    if (userId == null) {
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
          'comment': commentText,
        }),
      );

      if (httpResponse.statusCode == 200) {
        _showSnackbar('Comment added successfully!');
        _commentController.clear();
        _fetchEventDetails(); // Refresh event details to reflect the new comment
      } else {
        final responseBody = json.decode(httpResponse.body);
        _showSnackbar(responseBody['message'] ?? 'Failed to add comment',
            isError: true);
      }
    } catch (error) {
      _showSnackbar('Error adding comment: $error', isError: true);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    final DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('EEE, MMM d, y h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Event Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventDetails == null || eventDetails!.isEmpty
              ? const Center(child: Text('Failed to load event details.'))
              : _buildEventDetails(),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildEventDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventBanner(),
          const SizedBox(height: 20),
          _buildEventInfo(),
          const SizedBox(height: 20),
          _buildResponsesSummary(),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            'Comments:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          // Place the comment box above the comments list
          _buildWriteCommentField(),
          const SizedBox(height: 10),
          _buildCommentsSection(),
          const SizedBox(height: 65),
        ],
      ),
    );
  }

  Widget _buildEventBanner() {
    // Check if `bannerImage` exists and is not empty
    final String? base64Image = eventDetails?['bannerImage'];
    if (base64Image == null || base64Image.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade300, // Placeholder background color
        ),
        child: const Center(
          child: Text(
            'No Image Available',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }

    try {
      // Decode the base64 string
      Uint8List decodedBytes = base64Decode(base64Image);

      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: MemoryImage(decodedBytes), // Use MemoryImage for base64 data
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade300, // Placeholder background color
        ),
        child: const Center(
          child: Text(
            'Error Loading Image',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildEventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventDetails?['title'] ?? 'Event Title',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              eventDetails?['location'] ?? 'Unknown Location',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.schedule, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Timings: ${_formatDate(eventDetails?['timings'])}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.timer, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Duration: ${eventDetails?['duration'] ?? 'N/A'} mins',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(eventDetails?['description'] ?? 'No description provided.'),
      ],
    );
  }

  Widget _buildResponsesSummary() {
    final responses = eventDetails?['responses'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Responses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text('Attending: ${responses['attending'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: Colors.orange),
          title: Text('Unanswered: ${responses['unanswered'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.cancel, color: Colors.red),
          title: Text('Declined: ${responses['declined'] ?? 0}'),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    final comments = eventDetails?['comments'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Comments:',
        //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        // ),
        const SizedBox(height: 8),
        comments.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildComment(comment);
                },
              )
            : const Text('No comments yet.'),
      ],
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person),
      ),
      title: Text(
        comment['userId']?.toString() ?? 'Anonymous',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment['comment'] ?? 'No content'),
          const SizedBox(height: 5),
          Text(
            _formatDate(comment['createdAt']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteCommentField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              side: const BorderSide(color: Colors.green, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            onPressed: () {
              _submitResponse('Attending');
            },
            child: const Text(
              'ATTEND',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            onPressed: () {
              _submitResponse('Declined');
            },
            child: const Text(
              'DECLINE',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
