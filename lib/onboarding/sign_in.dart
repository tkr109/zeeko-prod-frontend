import 'package:flutter/material.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/widgets/get_started.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool isOtpComplete = false;

  Future<void> saveUserState(String token, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('email', email);
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
        final token = data['token']; // Extract JWT token from response
        print('OTP verified successfully. Token: $token');
        print(emailController.text);
        await saveUserState(data['token'], emailController.text);
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

  void loginUser() async {
    print("--------------------------------------");
    print("email: ${emailController.text}");
    print("password: ${passwordController.text}");
    print("--------------------------------------");

    var response = await http.post(
      Uri.parse('http://192.168.100.12:5000/api/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    otpControllers.forEach((controller) => controller.dispose());
    otpFocusNodes.forEach((node) => node.dispose());
    _pageController.dispose();
    super.dispose();
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
              "User Onboarding",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "${_currentStep + 1}/2",
                style: TextStyle(
                  color: Colors
                      .grey.shade600, // Muted grey color for less visibility
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
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
                // Step 1: Sign In
                buildSignInForm(),
                // Step 2: OTP Verification
                buildOtpVerification(),
              ],
            ),
          ),
          // Continue Button
          GetStartedButton(
            buttonText: "Continue",
            onPressed: () {
              if ((_currentStep == 0 &&
                      (_formKey.currentState?.validate() ?? false)) ||
                  (_currentStep == 1 && isOtpComplete)) {
                if (_currentStep < 1) {
                  loginUser();
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  verifyOtp(emailController.text, getOtp());
                  print("Onboarding Complete");
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
                            _currentStep == 1
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

  // Helper method to build Sign In Form
  Widget buildSignInForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sign In",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            buildTextField("Email", emailController, TextInputType.emailAddress,
                validator: validateEmail),
            buildTextField("Password", passwordController, TextInputType.text,
                obscureText: true, validator: validateNotEmpty),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to build OTP Verification
  Widget buildOtpVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter the OTP sent to",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            emailController.text, // Displays the entered email
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 20),
          // OTP Input Fields with auto-focus
          Row(
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
                      FocusScope.of(context)
                          .requestFocus(otpFocusNodes[index + 1]);
                    } else if (value.isEmpty && index > 0) {
                      FocusScope.of(context)
                          .requestFocus(otpFocusNodes[index - 1]);
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
          SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                // Handle OTP resend action here
                print("Request another OTP");
              },
              child: Text(
                "Request another OTP",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
}
