import 'package:flutter/material.dart';
import 'package:frontend/onboarding/create_group.dart';
import 'package:frontend/onboarding/join_an_existing_group.dart';
import 'package:frontend/onboarding/sign_in.dart';
import 'package:frontend/widgets/optionBox.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color(0xFFF8ECE0), // Matches background color in the image
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                  child: Text(
                    'Zeeko',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Options
              OptionBox(
                title: 'Join an existing group',
                subtitle:
                    'I am a member or a parent who has been invited to join a group in school',
                onTap: () {
                  print('Join an existing group tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => JoinAnExistingGroupScreen()),
                  );
                },
              ),
              SizedBox(height: 16),
              OptionBox(
                title: 'Set up a new group',
                subtitle:
                    'I want to use spond to organise events and communication in my team or group',
                onTap: () {
                  print('Set up a new group tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateGroupScreen()),
                  );
                },
              ),
              SizedBox(height: 16),
              OptionBox(
                title: 'Sign in',
                subtitle: 'I already have a Zeeko account',
                onTap: () {
                  print('Sign in tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                },
              ),
              Spacer(),

              // Larger Image with Padding at the Bottom
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 30.0),
                child: Image.asset(
                  'assets/images/slide1.png', // Path to your image asset
                  height: 250, // Adjust height for balance
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
