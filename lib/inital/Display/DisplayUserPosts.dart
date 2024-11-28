import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/inital/Details/postDetailPage.dart';
import 'package:frontend/widgets/post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DisplayUserPosts extends StatefulWidget {
  const DisplayUserPosts({super.key});

  @override
  _DisplayUserPostsState createState() => _DisplayUserPostsState();
}

class _DisplayUserPostsState extends State<DisplayUserPosts> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserPosts();
  }

  Future<void> fetchUserPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('userId');
      List<String>? groupIds = prefs.getStringList('groupIds');

      if (token == null ||
          userId == null ||
          groupIds == null ||
          groupIds.isEmpty) {
        _showSnackbar(context, "User information or group IDs are missing.",
            isError: true);
        setState(() {
          isLoading = false;
        });
        return;
      }

      final url =
          Uri.parse('${Constants.serverUrl}/api/group/userSubgroupPosts');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "userId": userId,
          "groupIds": groupIds,
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> postList =
            json.decode(response.body)['posts'] ?? [];
        setState(() {
          posts = postList.map((post) {
            // Ensure fields are not null before accessing them
            final postId = post['_id']?.toString() ?? '';
            final title = post['title']?.toString() ?? 'No Title';
            final description =
                post['description']?.toString() ?? 'No Description';
            final date = formatDate(post['date']?.toString() ?? '');

            return {
              "postId": postId,
              "title": title,
              "description": description,
              "date": date,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        _showSnackbar(context, "Failed to load posts.", isError: true);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching posts: $error");
      _showSnackbar(context, "Error occurred: $error", isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return "${date.day} ${getMonth(date.month)} ${date.year}";
    } catch (e) {
      return 'Invalid Date';
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
    return month > 0 && month <= 12 ? months[month - 1] : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final postId = posts[index]['postId'];
                    if (postId != null && postId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailsPage(postId: postId),
                        ),
                      );
                    } else {
                      _showSnackbar(context, "Invalid Post ID", isError: true);
                    }
                  },
                  child: PostCard(
                    title: posts[index]['title'] ?? 'No Title',
                    date: posts[index]['date'] ?? 'No Date',
                    description:
                        posts[index]['description'] ?? 'No Description',
                  ),
                );
              },
            ),
    );
  }

  void _showSnackbar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
