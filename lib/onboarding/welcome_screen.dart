import 'package:flutter/material.dart';
import 'package:frontend/onboarding/options_screen.dart';
import 'package:frontend/widgets/get_started.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Zeeko Title at the top
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Text(
                  'Zeeko',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Swipeable Image Section with PageController
            Expanded(
              flex: 4,
              child: Container(
                child: PageView(
                  controller: _pageController,
                  children: [
                    Placeholder(
                      fallbackHeight: 250,
                      fallbackWidth: 250,
                      color: Colors.grey,
                    ),
                    Placeholder(
                      fallbackHeight: 250,
                      fallbackWidth: 250,
                      color: Colors.blue,
                    ),
                    Placeholder(
                      fallbackHeight: 250,
                      fallbackWidth: 250,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Dots indicator for swipe pages
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor:
                        _currentPage == index ? Colors.black : Colors.grey,
                  ),
                );
              }),
            ),
            SizedBox(height: 30),

            // Subtitle and Description Text Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Text(
                    'Recreational, Made Simple and Easy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Smooth communication between organizers, teachers, \nstudents, and parents on one platform',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Spacer(), // Pushes content above to align the button at the bottom

            // Get Started Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: GetStartedButton(
                buttonText: 'Get Started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OptionsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
