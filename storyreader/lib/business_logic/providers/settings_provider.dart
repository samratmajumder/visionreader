import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  // Text Settings
  double _fontSize = AppConstants.defaultFontSize;
  String _fontFamily = 'System';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  bool _isDarkMode = false;
  
  // Auto-scroll Settings
  bool _isAutoScrollEnabled = false;
  double _autoScrollSpeed = AppConstants.defaultScrollSpeed;
  
  // Layout Settings
  bool _showGridControls = true;
  bool _snapToGrid = true;
  
  // Media Settings
  double _defaultImageDuration = AppConstants.defaultImageDisplayDuration;
  bool _autoPlayVideos = true;
  bool _loopPlaylists = false;

  // Getters
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  bool get isDarkMode => _isDarkMode;
  bool get isAutoScrollEnabled => _isAutoScrollEnabled;
  double get autoScrollSpeed => _autoScrollSpeed;
  bool get showGridControls => _showGridControls;
  bool get snapToGrid => _snapToGrid;
  double get defaultImageDuration => _defaultImageDuration;
  bool get autoPlayVideos => _autoPlayVideos;
  bool get loopPlaylists => _loopPlaylists;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _fontSize = _prefs.getDouble(AppConstants.keyFontSize) ?? AppConstants.defaultFontSize;
    _fontFamily = _prefs.getString(AppConstants.keyFontFamily) ?? 'System';
    _isDarkMode = _prefs.getBool(AppConstants.keyDarkMode) ?? false;
    _autoScrollSpeed = _prefs.getDouble(AppConstants.keyAutoScrollSpeed) ?? AppConstants.defaultScrollSpeed;
    
    // Load colors
    final bgColorValue = _prefs.getInt(AppConstants.keyBackgroundColor);
    if (bgColorValue != null) {
      _backgroundColor = Color(bgColorValue);
    }
    
    final textColorValue = _prefs.getInt(AppConstants.keyTextColor);
    if (textColorValue != null) {
      _textColor = Color(textColorValue);
    }
    
    notifyListeners();
  }

  // Text Settings
  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    await _prefs.setDouble(AppConstants.keyFontSize, _fontSize);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    await _prefs.setString(AppConstants.keyFontFamily, _fontFamily);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    await _prefs.setInt(AppConstants.keyBackgroundColor, color.value);
    notifyListeners();
  }

  Future<void> setTextColor(Color color) async {
    _textColor = color;
    await _prefs.setInt(AppConstants.keyTextColor, color.value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode);
    
    // Update default colors for dark mode
    if (_isDarkMode) {
      _backgroundColor = Colors.grey[900] ?? Colors.black;
      _textColor = Colors.white;
    } else {
      _backgroundColor = Colors.white;
      _textColor = Colors.black;
    }
    
    notifyListeners();
  }

  // Auto-scroll Settings
  Future<void> setAutoScrollEnabled(bool enabled) async {
    _isAutoScrollEnabled = enabled;
    notifyListeners();
  }

  Future<void> setAutoScrollSpeed(double speed) async {
    _autoScrollSpeed = speed.clamp(AppConstants.minScrollSpeed, AppConstants.maxScrollSpeed);
    await _prefs.setDouble(AppConstants.keyAutoScrollSpeed, _autoScrollSpeed);
    notifyListeners();
  }

  // Layout Settings
  void setShowGridControls(bool show) {
    _showGridControls = show;
    notifyListeners();
  }

  void setSnapToGrid(bool snap) {
    _snapToGrid = snap;
    notifyListeners();
  }

  // Media Settings
  void setDefaultImageDuration(double duration) {
    _defaultImageDuration = duration.clamp(
      AppConstants.minImageDisplayDuration,
      AppConstants.maxImageDisplayDuration,
    );
    notifyListeners();
  }

  void setAutoPlayVideos(bool autoPlay) {
    _autoPlayVideos = autoPlay;
    notifyListeners();
  }

  void setLoopPlaylists(bool loop) {
    _loopPlaylists = loop;
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _fontSize = AppConstants.defaultFontSize;
    _fontFamily = 'System';
    _backgroundColor = Colors.white;
    _textColor = Colors.black;
    _isDarkMode = false;
    _isAutoScrollEnabled = false;
    _autoScrollSpeed = AppConstants.defaultScrollSpeed;
    _showGridControls = true;
    _snapToGrid = true;
    _defaultImageDuration = AppConstants.defaultImageDisplayDuration;
    _autoPlayVideos = true;
    _loopPlaylists = false;
    
    await _prefs.clear();
    notifyListeners();
  }
}