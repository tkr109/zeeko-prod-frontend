import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/inital/Details/postDetailPage.dart';
import 'package:frontend/widgets/post_card.dart';
import 'package:frontend/widgets/section_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayGroupPosts extends StatefulWidget {
  final String groupId;
  final String subgroupId;
  final bool isAdmin;

  const DisplayGroupPosts({
    required this.groupId,
    required this.subgroupId,
    required this.isAdmin,
    super.key,
  });

  @override
  _DisplayGroupPostsState createState() => _DisplayGroupPostsState();
}

class _DisplayGroupPostsState extends State<DisplayGroupPosts> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      var response;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (widget.isAdmin && widget.subgroupId == "universal") {
        response = await http.get(Uri.parse(
            '${Constants.serverUrl}/api/group/admin/posts/${widget.groupId}/${userId}'));
      } else {
        response = await http.get(Uri.parse(
            '${Constants.serverUrl}/api/group/posts/${widget.groupId}/${widget.subgroupId}'));
      }
      print(response.statusCode);
      if (response.statusCode == 200) {
        final List<dynamic> postList = json.decode(response.body)['posts'];

        setState(() {
          posts = postList
              .map((post) => {
                    "id": post['_id'], // Ensure `id` is passed for details page
                    "title": post['title'],
                    "description": post['description'],
                    "date": DateTime.parse(post['date']),
                  })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (error) {
      print("Error fetching posts: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.day} ${getMonth(date.month)} ${date.year}";
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

  List<Widget> buildPostSections() {
    final today = DateTime.now();
    final thisWeekPosts = posts.where((post) {
      final difference = today.difference(post['date']).inDays;
      return difference >= 0 && difference < 7;
    }).toList();

    final otherPosts = posts.where((post) {
      final difference = today.difference(post['date']).inDays;
      return difference >= 7;
    }).toList();

    List<Widget> sections = [];

    if (thisWeekPosts.isNotEmpty) {
      sections.add(const SectionTitle(title: 'This Week'));
      sections.addAll(
        thisWeekPosts.map((post) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetailsPage(postId: post['id']), // Pass post ID
                  ),
                );
              },
              child: PostCard(
                title: post['title'],
                date: formatDate(post['date']),
                description: post['description'],
              ),
            )),
      );
    }

    final groupedPosts = <String, List<Map<String, dynamic>>>{};
    for (var post in otherPosts) {
      final dateKey = formatDate(post['date']);
      if (!groupedPosts.containsKey(dateKey)) {
        groupedPosts[dateKey] = [];
      }
      groupedPosts[dateKey]!.add(post);
    }

    for (var entry in groupedPosts.entries) {
      sections.add(SectionTitle(title: entry.key));
      sections.addAll(
        entry.value.map((post) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetailsPage(postId: post['id']), // Pass post ID
                  ),
                );
              },
              child: PostCard(
                title: post['title'],
                date: formatDate(post['date']),
                description: post['description'],
              ),
            )),
      );
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buildPostSections(),
              ),
            ),
    );
  }
}
