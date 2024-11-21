import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/widgets/get_started.dart';
import 'package:frontend/widgets/optionBox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(6, (_) => GlobalKey<FormState>());
  int _currentStep = 0;

  // Controllers and variables
  final TextEditingController searchController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool isOtpComplete = false;
  String? selectedActivity; // This is set when an activity is selected
  String? selectedAgeGroup;

  String getOtp() {
    String otp = otpControllers.map((controller) => controller.text).join();
    return otp;
  }

  Future<void> verifyOtp(String email, String otp) async {
    final url = Uri.parse('${Constants.serverUrl}/api/auth/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']; // Extract JWT token from response
        print('OTP verified successfully. Token: $token');
        saveUserState(data['token'], emailController.text);
        context.go('/home');
        // Handle successful verification (e.g., navigate to a new screen, store the token)
      } else {
        print('Invalid OTP or request failed. Message: ${response.body}');
        // Handle error (e.g., show an error message)
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle network or server error
    }
  }

  void registerUser() async {
    print("--------------------------------------");
    print("firstName: ${firstNameController.text}");
    print("lastName: ${lastNameController.text}");
    print("email: ${emailController.text}");
    print("password: ${passwordController.text}");
    print("phoneNumber: ${phoneController.text}");
    print("groupName: ${groupNameController.text}");
    print("groupActivity: ${selectedActivity}");
    print("groupAgeGroup: ${selectedAgeGroup}");
    print("--------------------------------------");

    var response = await http.post(
      Uri.parse('${Constants.serverUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'phoneNumber': phoneController.text,
        'groupName': groupNameController.text,
        'groupActivity': selectedActivity ?? '',
        'groupAgeGroup': selectedAgeGroup ?? '',
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      print('-------------');
      print(jsonResponse);
      print('-------------');
    } else if (response.statusCode == 400) {
      var jsonResponse = json.decode(response.body);
      print('-------------');
      print(jsonResponse);
      print('-------------');
    }
  }

  void saveUserState(String token, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('email', email);
  }

  // Activity categories with items
  Map<String, List<String>> activityCategories = {
    "Sports": ["Football", "Cricket", "Basketball", "Kabaddi", "Hockey"],
    "Recreation": ["Dance", "Music", "Singing"],
  };
  List<String> filteredActivities = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterActivities);
    _initializeFilteredActivities();
  }

  @override
  void dispose() {
    searchController.dispose();
    groupNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otpControllers.forEach((controller) => controller.dispose());
    otpFocusNodes.forEach((node) => node.dispose());
    _pageController.dispose();
    super.dispose();
  }

  void _initializeFilteredActivities() {
    filteredActivities =
        activityCategories.values.expand((items) => items).toList();
  }

  void _filterActivities() {
    setState(() {
      final searchQuery = searchController.text.toLowerCase();
      filteredActivities = activityCategories.values
          .expand((items) => items)
          .where((activity) => activity.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  void checkOtpComplete() {
    setState(() {
      isOtpComplete =
          otpControllers.every((controller) => controller.text.isNotEmpty);
    });
  }

  void goToNextStep() {
    if (_currentStep == 0 && selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a group activity to continue."),
          backgroundColor: Colors.grey.shade900,
        ),
      );
      return;
    }

    // Debug statement to check if selectedActivity is correctly set
    print("Selected activity: $selectedActivity");

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      print("Group Creation Complete");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8ECE0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Color(0xFFF8ECE0),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                });
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "Create Group",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.grey.shade300,
              color: Colors.black,
              minHeight: 5,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                buildActivitySelection(),
                buildAgeGroupSelection(),
                buildGroupNameForm(),
                buildSummaryScreen(),
                buildAccountSetup(),
                buildOtpVerification(),
              ],
            ),
          ),
          GetStartedButton(
            buttonText: "Continue",
            onPressed: () {
              if (_currentStep == 4) {
                registerUser();
                goToNextStep();
              } else if (_currentStep == 5) {
                verifyOtp(emailController.text, getOtp());
              } else {
                goToNextStep();
              }
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildActivitySelection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Group Activity",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "Search activity",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: activityCategories.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                    ...entry.value
                        .where(
                            (activity) => filteredActivities.contains(activity))
                        .map((activity) {
                      return ListTile(
                        title: Text(activity),
                        leading: Radio<String>(
                          value: activity,
                          groupValue: selectedActivity,
                          onChanged: (value) {
                            setState(() {
                              selectedActivity = value;
                              print(
                                  "Activity selected: $selectedActivity"); // Debug print statement
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAgeGroupSelection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose Age Group",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Age Group affects settings regarding parental control & safeguarding",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 20),
          OptionBox(
            title: "Children/Youth",
            subtitle:
                "Members aged 0-17, where communication is mainly with guardians",
            isSelected: selectedAgeGroup == "Children/Youth",
            onTap: () {
              setState(() {
                selectedAgeGroup = "Children/Youth";
              });
            },
          ),
          SizedBox(height: 16),
          OptionBox(
            title: "Adults",
            subtitle: "Members 18+",
            isSelected: selectedAgeGroup == "Adults",
            onTap: () {
              setState(() {
                selectedAgeGroup = "Adults";
              });
            },
          ),
          SizedBox(height: 16),
          OptionBox(
            title: "Mixed",
            subtitle: "Members of all ages with or without guardians",
            isSelected: selectedAgeGroup == "Mixed",
            onTap: () {
              setState(() {
                selectedAgeGroup = "Mixed";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildGroupNameForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Group Name",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextFormField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: validateNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryScreen() {
    return Scaffold(
      backgroundColor:
          Color(0xFFF8ECE0), // Match background color with other pages

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Group Name Title (Dynamic)
            Text(
              groupNameController
                  .text, // Displays the group name entered in the previous step
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            // Illustration/Image in the Center
            Image.asset(
              'assets/images/slide3.png', // Use your desired image path here
              height: 350,
              fit: BoxFit.contain,
            ),

            SizedBox(height: 30),

            // Completion Message
            Text(
              "Awesome!\nYou’re almost done",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10),

            // Subtext below the completion message
            Text(
              "Lorem Ipsum Lorem IpsumLoremLorem IpsumLorem Lorem IpsumLorem",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget buildAccountSetup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align title to the left
          children: [
            Text(
              "Set Up Your Account", // Heading for the form
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15.0), // Add some spacing after the heading
            buildTextField(
              "First Name",
              firstNameController,
              TextInputType.name,
            ),
            SizedBox(height: 15),
            buildTextField(
              "Last Name",
              lastNameController,
              TextInputType.name,
            ),
            SizedBox(height: 15),
            buildTextField(
              "Phone Number",
              phoneController,
              TextInputType.phone,
              validator: validatePhone,
            ),
            SizedBox(height: 15),
            buildTextField(
              "Your Email",
              emailController,
              TextInputType.emailAddress,
              validator: validateEmail,
            ),
            SizedBox(height: 15),
            buildTextField(
              "Password",
              passwordController,
              TextInputType.text,
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOtpVerification() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Enter the OTP sent to", style: TextStyle(fontSize: 18)),
          Text(emailController.text,
              style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 60,
                child: TextFormField(
                  controller: otpControllers[index],
                  focusNode: otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    checkOtpComplete();
                    if (value.isNotEmpty && index < 3) {
                      FocusScope.of(context)
                          .requestFocus(otpFocusNodes[index + 1]);
                    } else if (value.isEmpty && index > 0) {
                      FocusScope.of(context)
                          .requestFocus(otpFocusNodes[index - 1]);
                    }
                  },
                  validator: validateNotEmpty,
                ),
              );
            }),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () {
              print("Request another OTP");
            },
            child: Text("Request another OTP",
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, TextInputType inputType,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  String? validateNotEmpty(String? value) {
    return value == null || value.isEmpty ? 'This field cannot be empty' : null;
  }

  String? validateEmail(String? value) {
    return (value == null ||
            value.isEmpty ||
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
        ? 'Please enter a valid email'
        : null;
  }

  String? validatePhone(String? value) {
    return (value == null ||
            value.isEmpty ||
            !RegExp(r'^[0-9]{10}$').hasMatch(value))
        ? 'Please enter a valid 10-digit phone number'
        : null;
  }
}
