import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddPollPage extends StatefulWidget {
  final String groupId;
  final String subgroupId;

  const AddPollPage({required this.groupId, required this.subgroupId, Key? key})
      : super(key: key);

  @override
  _AddPollPageState createState() => _AddPollPageState();
}

class _AddPollPageState extends State<AddPollPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController()
  ];

  bool isSubmitting = false;

  void addOptionField() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  Future<void> submitPoll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/addPoll/${widget.groupId}/${widget.subgroupId}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': descriptionController.text,
          'options': optionControllers
              .map((controller) => {'option': controller.text})
              .toList(),
        }),
      );

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 200) {
        _showCustomSnackBar('Poll created successfully!', isSuccess: true);
        descriptionController.clear();
        optionControllers.forEach((controller) => controller.clear());
      } else {
        _showCustomSnackBar('Failed to create poll', isSuccess: false);
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showCustomSnackBar('Error creating poll', isSuccess: false);
    }
  }

  void _showCustomSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    optionControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8ECE0),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8ECE0),
        elevation: 0,
        title: Text(
          "Create Poll",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                children: List.generate(optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: TextFormField(
                      controller: optionControllers[index],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Option cannot be empty';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: 'Option ${index + 1}',
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: addOptionField,
                  child: Text("Add Another Option"),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: isSubmitting ? null : submitPoll,
                  child: Text(
                    isSubmitting ? "Submitting..." : "Submit Poll",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}