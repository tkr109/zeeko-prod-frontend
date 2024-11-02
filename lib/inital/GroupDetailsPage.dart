// lib/inital/GroupDetailsPage.dart

import 'package:flutter/material.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupId;

  GroupDetailsPage({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group Details"),
      ),
      body: Center(
        child: Text(
          "Details for Group ID: $groupId",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
