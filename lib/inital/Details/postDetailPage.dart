import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  Map<String, dynamic>? postDetails;
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPostDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchPostDetails(); // Re-fetch details when the page is revisited
  }

  // Fetch post details from the backend
  Future<void> fetchPostDetails() async {
    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/post/details/${widget.postId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          postDetails = data;
          comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
          isLoading = false;
        });
        print(data);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to load post details"),
              backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
    }
  }

  // Submit a new comment to the backend
  Future<void> _submitComment(String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User not logged in"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final url =
          Uri.parse('${Constants.serverUrl}/api/post/comment/${widget.postId}');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newComment = {
          'userId': {'firstName': 'You', 'lastName': ''},
          'comment': comment,
          'createdAt': 'Just now',
        };

        setState(() {
          comments.add(newComment);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Comment added successfully"),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to add comment"),
              backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
    }
  }

  // Helper method to format the date
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No Date';

    try {
      final DateTime parsedDate = DateTime.parse(dateStr);
      return "${parsedDate.day}-${parsedDate.month}-${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute}";
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: Text(
          postDetails?['title'] ?? 'No Title',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Heading
                        Text(
                          postDetails?['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Date Information
                        Text(
                          formatDate(postDetails?['date']),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Post Description
                        Text(
                          postDetails?['description'] ?? 'No Description',
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Divider(color: Colors.grey[400], thickness: 2),

                        // Comments Section
                        const Text(
                          'Comments:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return _buildComment(comments[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Write Comment Section
                _buildWriteCommentField(),
              ],
            ),
    );
  }

  // Helper method to build each comment
  Widget _buildComment(Map<String, dynamic> comment) {
    final firstName = comment['userId']?['firstName'] ?? 'Anonymous';
    final lastName = comment['userId']?['lastName'] ?? '';
    final userName = '$firstName $lastName'.trim();
    final commentText = comment['comment'] ?? 'No Content';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(commentText),
        ),
        const Divider(),
      ],
    );
  }

  // Method to build "Write a comment" input field
  Widget _buildWriteCommentField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Write a comment...',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.grey[800]),
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                _submitComment(_commentController.text);
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
