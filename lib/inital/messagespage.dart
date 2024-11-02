// lib/widgets/messagespage.dart

import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Messages Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
