import 'package:flutter/material.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/get_started.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

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
        final token = data['token'];
        print('OTP verified successfully. Token: $token');
        await saveUserState(data['token'], emailController.text);

        // Navigate to HomePage using GoRouter

        context.go('/home');
      } else {
        print('Invalid OTP or request failed. Message: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void loginUser() async {
    var response = await http.post(
      Uri.parse('http://192.168.100.12:5000/api/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      print('Login successful');
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      print('Login failed');
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
                context.pop();
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "${_currentStep + 1}/2",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                buildSignInForm(),
                buildOtpVerification(),
              ],
            ),
          ),
          GetStartedButton(
            buttonText: "Continue",
            onPressed: () {
              if ((_currentStep == 0 &&
                      (_formKey.currentState?.validate() ?? false)) ||
                  (_currentStep == 1 && isOtpComplete)) {
                if (_currentStep < 1) {
                  loginUser();
                } else {
                  verifyOtp(emailController.text, getOtp());
                  print("Onboarding Complete");
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.grey.shade900,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
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

  Widget buildSignInForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sign In",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget buildOtpVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Enter the OTP sent to",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(emailController.text,
              style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 20),
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
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      TextInputType keyboardType,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email.";
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$")
        .hasMatch(value)) {
      return "Please enter a valid email.";
    }
    return null;
  }

  String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return "This field cannot be empty.";
    }
    return null;
  }
}
