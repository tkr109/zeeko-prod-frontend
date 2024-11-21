import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/widgets/get_started.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PollDetailsPage extends StatefulWidget {
  final String pollId;

  const PollDetailsPage({Key? key, required this.pollId}) : super(key: key);

  @override
  _PollDetailsPageState createState() => _PollDetailsPageState();
}

class _PollDetailsPageState extends State<PollDetailsPage> {
  Map<String, dynamic>? pollDetails;
  List<Map<String, dynamic>> pollOptions = [];
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  String? _selectedOption;
  String? userId;
  bool hasVoted = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPollDetails();
  }

  // Fetch user data from SharedPreferences
  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }

  // Fetch poll details from the backend
  Future<void> fetchPollDetails() async {
    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/poll/details/${widget.pollId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pollDetails = data;
          pollOptions = (data['options'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          comments = (data['comments'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          hasVoted =
              data['voters']?.any((voter) => voter['userId'] == userId) ??
                  false;
          isLoading = false;
        });
      } else {
        showSnackbar("Failed to load poll details.");
        setState(() => isLoading = false);
      }
    } catch (error) {
      showSnackbar("Error: $error");
      setState(() => isLoading = false);
    }
  }

  // Submit a vote to the backend
  Future<void> submitVote() async {
    if (_selectedOption == null) {
      showSnackbar("Please select an option before voting.");
      return;
    }
    if (hasVoted) {
      showSnackbar("You have already voted in this poll.");
      return;
    }

    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/poll/vote/${widget.pollId}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'option': _selectedOption}),
      );

      if (response.statusCode == 200) {
        showSnackbar("Your vote has been submitted!");
        fetchPollDetails(); // Refresh poll details
      } else {
        showSnackbar("Failed to submit vote.");
      }
    } catch (error) {
      showSnackbar("Error: $error");
    }
  }

  // Submit a new comment to the backend
  Future<void> submitComment(String comment) async {
    if (comment.isEmpty) return;

    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/poll/comment/${widget.pollId}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'comment': comment}),
      );

      if (response.statusCode == 200) {
        showSnackbar("Comment added successfully!");
        _commentController.clear();
        fetchPollDetails(); // Refresh comments
      } else {
        showSnackbar("Failed to add comment.");
      }
    } catch (error) {
      showSnackbar("Error: $error");
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pollDetails?['description'] ?? "Poll Details"),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll Description
                  Text(
                    pollDetails?['description'] ?? 'No Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Poll Options
                  Text(
                    "Options:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: pollOptions.length,
                    itemBuilder: (context, index) {
                      return _buildPollOptionCard(pollOptions[index]);
                    },
                  ),
                  SizedBox(height: 16),

                  // Submit Vote Button using GetStartedButton widget
                  GetStartedButton(
                    buttonText: "Submit Vote",
                    onPressed: submitVote,
                  ),
                  SizedBox(height: 20),

                  Divider(color: Colors.grey[400], thickness: 2),

                  // Comments Section
                  Text(
                    'Comments:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return _buildComment(comments[index]);
                    },
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
      bottomNavigationBar: _buildWriteCommentField(),
    );
  }

  // Helper method to build the poll option card
  Widget _buildPollOptionCard(Map<String, dynamic> option) {
    bool isSelected = _selectedOption == option['option'];

    return GestureDetector(
      onTap: () {
        if (!hasVoted) {
          setState(() {
            _selectedOption = option['option'];
          });
        } else {
          showSnackbar("You have already voted.");
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border:
              Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(option['option'],
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${option['votes']} votes"),
          ],
        ),
      ),
    );
  }

  // Helper method to build each comment
  Widget _buildComment(Map<String, dynamic> comment) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.person)),
      title: Text(comment['userId']?['firstName'] ?? 'Anonymous'),
      subtitle: Text(comment['comment']),
    );
  }

  // Method to build the "Write a comment" input field
  Widget _buildWriteCommentField() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(hintText: 'Write a comment...'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              submitComment(_commentController.text);
            },
          ),
        ],
      ),
    );
  }
}
