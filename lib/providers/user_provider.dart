import 'package:flutter/material.dart';
import 'package:osprecords/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(id: '', name: '', email: '', token: '', password: '');

  User get user => _user;

  UserProvider() {
    loadUserFromPrefs();
  }

  void setUser(String userJson) async {
    _user = User.fromJson(userJson);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', userJson);
  }

  void setUserFromModel(User user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', user.toJson());
  }

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null && userJson.isNotEmpty) {
      _user = User.fromJson(userJson);
      notifyListeners();
    }
  }

  void clearUser() async {
    _user = User(id: '', name: '', email: '', token: '', password: '');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
  }
}
