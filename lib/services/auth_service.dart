import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final email = prefs
        .getString('userEmail'); // Adjust this key based on your implementation

    return token != null &&
        token.isNotEmpty &&
        email != null &&
        email.isNotEmpty;
  }
}
