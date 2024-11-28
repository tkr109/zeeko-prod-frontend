// lib/widgets/messagespage.dart

import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages Page'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Messages Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
