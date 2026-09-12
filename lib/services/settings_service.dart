import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyConcurrentDownloads = 'concurrent_downloads';
  static const String _keyAutoClipboard = 'auto_clipboard';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyWifiOnly = 'wifi_only';

  final SharedPreferences _prefs;

  int _concurrentDownloads;
  bool _autoClipboard;
  bool _notificationsEnabled;
  bool _isDarkMode;
  bool _wifiOnly;

  SettingsService(this._prefs)
      : _concurrentDownloads = _prefs.getInt(_keyConcurrentDownloads) ?? 2,
        _autoClipboard = _prefs.getBool(_keyAutoClipboard) ?? true,
        _notificationsEnabled = _prefs.getBool(_keyNotifications) ?? true,
        _isDarkMode = _prefs.getBool(_keyDarkMode) ?? true,
        _wifiOnly = _prefs.getBool(_keyWifiOnly) ?? false;

  int get concurrentDownloads => _concurrentDownloads;
  bool get autoClipboard => _autoClipboard;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isDarkMode => _isDarkMode;
  bool get wifiOnly => _wifiOnly;

  Future<void> setConcurrentDownloads(int value) async {
    if (value < 1) value = 1;
    if (value > 4) value = 4;
    _concurrentDownloads = value;
    await _prefs.setInt(_keyConcurrentDownloads, value);
    notifyListeners();
  }

  Future<void> setAutoClipboard(bool value) async {
    _autoClipboard = value;
    await _prefs.setBool(_keyAutoClipboard, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    await _prefs.setBool(_keyWifiOnly, value);
    notifyListeners();
  }
}
