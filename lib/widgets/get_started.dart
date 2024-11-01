import 'package:flutter/material.dart';

class GetStartedButton extends StatelessWidget {
  final String buttonText; // Customizable button text
  final VoidCallback onPressed;

  const GetStartedButton({
    Key? key,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20.0, vertical: 10.0), // Padding from edges
      child: SizedBox(
        width: double.infinity, // Full-width button
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Button color
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            elevation: 5,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: onPressed,
          child: Text(buttonText),
        ),
      ),
    );
  }
}
