import 'package:flutter/material.dart';

class UserProfileProvider extends ChangeNotifier {
  String? _profileImagePath;

  String? get profileImagePath => _profileImagePath;

  void setProfileImagePath(String? path) {
    _profileImagePath = path;
    notifyListeners();
  }

  void clearProfileImage() {
    _profileImagePath = null;
    notifyListeners();
  }
}