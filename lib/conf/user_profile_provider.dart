import 'package:flutter/material.dart';

class UserProfileProvider extends ChangeNotifier {
  String? _localProfileImagePath;
  String? _remoteProfileImageUrl;

  String? get localProfileImagePath => _localProfileImagePath;
  String? get remoteProfileImageUrl => _remoteProfileImageUrl;

  void setLocalProfileImagePath(String? path) {
    _localProfileImagePath = path;
    if (path != null && path.isNotEmpty) {
      _remoteProfileImageUrl = null;
    }
    notifyListeners();
  }

  void setRemoteProfileImageUrl(String? url) {
    _remoteProfileImageUrl = url;
    if (url != null && url.isNotEmpty) {
      _localProfileImagePath = null;
    }
    notifyListeners();
  }

  void clearProfileImage() {
    _localProfileImagePath = null;
    _remoteProfileImageUrl = null;
    notifyListeners();
  }
}