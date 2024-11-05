import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddEventPage extends StatefulWidget {
  final String groupId;
  final String subgroupId;

  const AddEventPage(
      {required this.groupId, required this.subgroupId, Key? key})
      : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bannerImageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isSubmitting = false;
  DateTime? selectedDateTime;

  Future<void> submitEvent() async {
    if (!_formKey.currentState!.validate() || selectedDateTime == null) {
      _showCustomSnackBar('Please enter all fields correctly',
          isSuccess: false);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/addEvent/${widget.groupId}/${widget.subgroupId}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleController.text,
          'bannerImage': bannerImageController.text,
          'timings': selectedDateTime!.toIso8601String(),
          'duration': int.parse(durationController.text),
          'location': locationController.text,
          'description': descriptionController.text,
        }),
      );

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 201) {
        _showCustomSnackBar('Event created successfully!', isSuccess: true);
        _clearFormFields();
      } else {
        _showCustomSnackBar('Failed to create event', isSuccess: false);
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showCustomSnackBar('Error creating event', isSuccess: false);
    }
  }

  // Clear form fields
  void _clearFormFields() {
    titleController.clear();
    bannerImageController.clear();
    durationController.clear();
    locationController.clear();
    descriptionController.clear();
    selectedDateTime = null;
  }

  // Helper method to show SnackBar
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

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    bannerImageController.dispose();
    durationController.dispose();
    locationController.dispose();
    descriptionController.dispose();
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
          "Create Event",
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
          child: ListView(
            children: [
              _buildTextField("Event Title", titleController),
              _buildTextField("Banner Image URL", bannerImageController),
              ListTile(
                title: Text(
                  selectedDateTime == null
                      ? "Select Timings"
                      : "Timings: ${selectedDateTime!.toLocal()}",
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              _buildTextField("Duration (minutes)", durationController,
                  isNumber: true),
              _buildTextField("Location", locationController),
              _buildTextField("Description", descriptionController,
                  maxLines: 3),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: isSubmitting ? null : submitEvent,
                  child: Text(
                    isSubmitting ? "Submitting..." : "Submit Event",
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

  // Helper method for building text fields
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
