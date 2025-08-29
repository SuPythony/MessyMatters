import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  /// Read auth key from local storage
  Future<String?> getAuthKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authKey');
  }

  /// Check if auth key is valid
  void checkAuthKey() async {
    String? authKey = await getAuthKey();
    if (authKey == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
    } else {
      final res = await http.get(
        Uri.parse('https://mess.iiit.ac.in/api/auth/keys/info'),
        headers: {"Authorization": ?authKey},
      );
      if (res.statusCode != 200) {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkAuthKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}
