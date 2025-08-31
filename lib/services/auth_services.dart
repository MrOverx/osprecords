import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:osprecords/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:osprecords/pages/osprecords_home.dart';

import 'package:osprecords/providers/user_provider.dart';
import 'package:osprecords/utils/constants.dart';
import 'package:osprecords/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> signUpUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      User user = User(
        id: '',
        name: name,
        email: email,
        token: '',
        password: password,
      );

      print('Attempting signup to: ${Constants.uri}/api/signup');
      print('User data: ${user.toJson()}');

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Signup response status: ${res.statusCode}');
      print('Signup response body: ${res.body}');

      if (context.mounted) {
        httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Success'),
                content: Text(
                  'Account created! Login with the same credentials.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close success dialog
                      Navigator.of(context).pop(); // Close signup dialog
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Signup error: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Signup failed: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      print('Attempting signin to: ${Constants.uri}/api/signin');
      print('Signin data: {"email": "$email", "password": "***"}');

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Signin response status: ${res.statusCode}');
      print('Signin response body: ${res.body}');

      if (context.mounted) {
        httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            userProvider.setUser(res.body);
            await prefs.setString(
              'x-auth-token',
              jsonDecode(res.body)['token'],
            );
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const OSPHomePage()),
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      print('Signin error: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Signin failed: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // get user data

  void getUserData(BuildContext context) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      if (token == null) {
        prefs.setString('x-auth-token', '');
        return; // Exit early if no token
      }

      var tokenRes = await http.post(
        Uri.parse('${Constants.uri}/tokenIsValid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      var response = jsonDecode(tokenRes.body);

      if (response == true) {
        http.Response userRes = await http.get(
          Uri.parse('${Constants.uri}/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token,
          },
        );
        userProvider.setUser(userRes.body);
      }
    } catch (e) {
      // Don't show dialog during app initialization
      // Just log the error for debugging
      print('Auth service error: $e');
    }
  }

  void signOut(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('x-auth-token', '');

    // Clear the user data in the provider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUserFromModel(
        User(id: '', name: '', email: '', token: '', password: ''),
      );
    } catch (e) {
      print('Error clearing user provider: $e');
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully signed out'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Navigate back to home page instead of signup page
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OSPHomePage()),
        (route) => false,
      );
    }
  }

  // Safe method to show auth errors after app initialization
  void showAuthError(BuildContext context, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Authentication Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> requestOtp({required String email}) async {
    final res = await http.post(
      Uri.parse('${Constants.uri}/api/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  Future<void> verifyOtpAndSignup({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('${Constants.uri}/api/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'otp': otp,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('OTP verification failed');
    }
  }
}
