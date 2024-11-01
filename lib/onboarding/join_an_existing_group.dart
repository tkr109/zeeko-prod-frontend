import 'package:flutter/material.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/widgets/get_started.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JoinAnExistingGroupScreen extends StatefulWidget {
  @override
  _JoinAnExistingGroupScreenState createState() =>
      _JoinAnExistingGroupScreenState();
}

class _JoinAnExistingGroupScreenState extends State<JoinAnExistingGroupScreen> {
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(5, (_) => GlobalKey<FormState>());
  int _currentStep = 0;

  // Controllers for the form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final List<TextEditingController> groupCodeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> groupCodeFocusNodes =
      List.generate(6, (_) => FocusNode());
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool isGroupCodeComplete = false;
  bool isOtpComplete = false;
  String token = "";

  void saveUserState(String token, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('email', email);
  }

  String getCompleteGroupCode() {
    return groupCodeControllers.map((controller) => controller.text).join('');
  }

  String getOtp() {
    String otp = otpControllers.map((controller) => controller.text).join();
    return otp;
  }

  Future<void> verifyOtp(String email, String otp) async {
    final url = Uri.parse("http://192.168.100.12:5000/api/auth/verify-otp");

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
        token = data['token']; // Extract JWT token from response
        print('OTP verified successfully. Token: $token');
        saveUserState(data['token'], emailController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
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

  void addUser() async {
    print("--------------------------------------");
    print("firstName: ${firstNameController.text}");
    print("lastName: ${lastNameController.text}");
    print("email: ${emailController.text}");
    print("password: ${passwordController.text}");
    print("phoneNumber: ${phoneController.text}");
    print("dob: ${dobController.text}");

    print("--------------------------------------");

    var response = await http.post(
      Uri.parse('http://192.168.100.12:5000/api/auth/addUser'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'phoneNumber': phoneController.text,
        'dob': dobController.text,
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

  Future<void> joinGroup(String groupCode, String email, String token) async {
    print("---------------------jiii---------------------");

    final url = Uri.parse(
        'http://192.168.100.12:5000/api/group/join'); // Replace with your backend URL

    try {
      // Prepare the request body
      final body = jsonEncode({
        'groupCode': groupCode,
        'email': email,
      });

      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Set content type
          'Authorization':
              'Bearer $token', // Add token in the Authorization header
        },
        body: body,
      );

      // Handle the response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data['msg']); // Display success message
      } else {
        final errorData = jsonDecode(response.body);
        print('Error: ${errorData['msg']}'); // Display error message
      }
    } catch (error) {
      print('An error occurred: $error'); // Handle any errors
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    groupCodeControllers.forEach((controller) => controller.dispose());
    otpControllers.forEach((controller) => controller.dispose());
    groupCodeFocusNodes.forEach((node) => node.dispose());
    otpFocusNodes.forEach((node) => node.dispose());
    _pageController.dispose();
    super.dispose();
  }

  void checkGroupCodeComplete() {
    setState(() {
      isGroupCodeComplete = groupCodeControllers
          .every((controller) => controller.text.isNotEmpty);
    });
  }

  void checkOtpComplete() {
    setState(() {
      isOtpComplete =
          otpControllers.every((controller) => controller.text.isNotEmpty);
    });
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
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              _currentStep == 0 ? "Join an existing group" : "User Onboarding",
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
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
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
                // Step 0: Join an Existing Group
                buildJoinGroupPage(),
                // Step 1: Sign Up
                buildStep(
                  title: "Sign Up",
                  formKey: _formKeys[1],
                  fields: [
                    buildTextField(
                        "Email", emailController, TextInputType.emailAddress,
                        validator: validateEmail),
                    buildTextField(
                        "Password", passwordController, TextInputType.text,
                        obscureText: true, validator: validateNotEmpty),
                  ],
                ),
                // Step 2: Add Details
                buildStep(
                  title: "Add Details",
                  formKey: _formKeys[2],
                  fields: [
                    buildTextField(
                        "First Name", firstNameController, TextInputType.name,
                        validator: validateNotEmpty),
                    buildTextField(
                        "Last Name", lastNameController, TextInputType.name,
                        validator: validateNotEmpty),
                    buildTextField(
                        "Phone Number", phoneController, TextInputType.phone,
                        validator: validatePhone),
                  ],
                ),
                // Step 3: Date of Birth
                buildStep(
                  title: "Date of Birth",
                  formKey: _formKeys[3],
                  fields: [
                    buildDOBField(),
                  ],
                ),
                // Step 4: OTP Verification
                buildStep(
                  title: "Finish Up",
                  formKey: _formKeys[4],
                  fields: [
                    Text(
                      "An OTP has been sent to your registered email address.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    buildOTPFields(),
                  ],
                ),
              ],
            ),
          ),
          // Continue Button
          GetStartedButton(
            buttonText: "Continue",
            onPressed: () async {
              print(_currentStep);
              if ((isGroupCodeComplete || _currentStep != 0) &&
                  (isOtpComplete || _currentStep != 4)) {
                // Proceed to next step if fields are filled
                if (_currentStep == 3) {
                  addUser();
                  print("complete group code");
                  print(getCompleteGroupCode());
                }
                if (_currentStep == 4) {
                  // Await the response from verifyOtp
                  await verifyOtp(emailController.text, getOtp());

                  await joinGroup(
                      getCompleteGroupCode(), emailController.text, token);
                }
                if (_currentStep == 0 ||
                    (_formKeys[_currentStep].currentState?.validate() ??
                        false)) {
                  if (_currentStep < 4) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    print("Onboarding Complete");
                  }
                }
              } else {
                // Show SnackBar if fields are incomplete
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.grey.shade900,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    content: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStep == 4
                                ? "Please enter the OTP sent to your email."
                                : "Please complete all fields before continuing.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper method for "Join an Existing Group" page
  Widget buildJoinGroupPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter Group Code",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please enter the 6-digit group code provided to you to join the existing group.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 20),
            // Group Code Input Fields with auto-focus
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextFormField(
                    controller: groupCodeControllers[index],
                    focusNode: groupCodeFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      checkGroupCodeComplete();
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context)
                            .requestFocus(groupCodeFocusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context)
                            .requestFocus(groupCodeFocusNodes[index - 1]);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper method to build each step
  Widget buildStep(
      {required String title,
      required GlobalKey<FormState> formKey,
      required List<Widget> fields}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ...fields,
            SizedBox(height: 20),
            Text(
              "All your data is kept secure and is only shared with individuals you choose.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build text fields with validation
  Widget buildTextField(
    String label,
    TextEditingController controller,
    TextInputType inputType, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  // Helper method to build Date of Birth field with date picker
  Widget buildDOBField() {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: dobController,
          decoration: InputDecoration(
            labelText: "Date of Birth",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validateNotEmpty,
        ),
      ),
    );
  }

  // Helper method to build OTP fields
  Widget buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              checkOtpComplete();
              if (value.isNotEmpty && index < 3) {
                FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
              }
            },
            validator: validateNotEmpty,
          ),
        );
      }),
    );
  }

  // Validation functions
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }
}
