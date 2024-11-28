import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class AddEventPage extends StatefulWidget {
  final String groupId;
  final String subgroupId;

  const AddEventPage({
    required this.groupId,
    required this.subgroupId,
    super.key,
  });

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isSubmitting = false;
  DateTime? selectedDateTime;
  File? _selectedImage;

  // Request permissions for camera and storage
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.storage] != PermissionStatus.granted) {
      _showPermissionSettingsDialog();
    }
  }

  // Show dialog to redirect users to settings if permissions are denied
  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
            "Please enable camera and storage permissions in your device settings to use this feature."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    // await _requestPermissions();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        _showCustomSnackBar('No image selected', isSuccess: false);
      }
    } catch (e) {
      _showCustomSnackBar('Error picking image: $e', isSuccess: false);
    }
  }

  // Submit the event details to the backend
  Future<void> submitEvent() async {
    if (!_formKey.currentState!.validate() ||
        selectedDateTime == null ||
        _selectedImage == null) {
      _showCustomSnackBar('Please fill all fields and select an image',
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
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleController.text,
          'bannerImage': base64Image,
          'timings': selectedDateTime!.toIso8601String(),
          'duration': int.parse(durationController.text),
          'location': locationController.text,
          'description': descriptionController.text,
          'isAcceptingResponses': true, // Default to accepting responses
          'isVisible': true, // Default visibility
        }),
      );

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 201) {
        _showCustomSnackBar('Event created successfully!', isSuccess: true);
        _clearFormFields();
      } else {
        final responseBody = jsonDecode(response.body);
        _showCustomSnackBar('Failed to create event: ${responseBody['error']}',
            isSuccess: false);
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showCustomSnackBar('Error creating event: $e', isSuccess: false);
    }
  }

  // Clear form fields
  void _clearFormFields() {
    titleController.clear();
    durationController.clear();
    locationController.clear();
    descriptionController.clear();
    selectedDateTime = null;
    _selectedImage = null;
  }

  // Show custom SnackBar
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
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

  // Select date and time
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
    durationController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8ECE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8ECE0),
        elevation: 0,
        title: const Text(
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
              ListTile(
                leading: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 50, color: Colors.grey),
                title: const Text("Select Image"),
                trailing: const Icon(Icons.add_a_photo),
                onTap: _pickImage,
              ),
              ListTile(
                title: Text(
                  selectedDateTime == null
                      ? "Select Timings"
                      : "Timings: ${selectedDateTime!.toLocal()}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              _buildTextField("Duration (minutes)", durationController,
                  isNumber: true),
              _buildTextField("Location", locationController),
              _buildTextField("Description", descriptionController,
                  maxLines: 3),
              const SizedBox(height: 20),
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
                    style: const TextStyle(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
