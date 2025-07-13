import 'package:flutter/material.dart';
import '../../data/models/story_document.dart';

class StoryProvider extends ChangeNotifier {
  StoryDocument? _currentStory;
  int _currentPosition = 0;
  bool _isLoading = false;
  
  // Getters
  StoryDocument? get currentStory => _currentStory;
  int get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get hasStory => _currentStory != null;
  
  // Story loading
  Future<void> loadStory(String filePath) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Implement story loading logic
      await Future.delayed(const Duration(milliseconds: 500)); // Placeholder
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Load story document directly
  void loadStoryDocument(StoryDocument document) {
    _currentStory = document;
    _currentPosition = 0;
    notifyListeners();
  }
  
  // Navigation
  void setPosition(int position) {
    _currentPosition = position;
    notifyListeners();
  }
  
  void nextPage() {
    // TODO: Implement page navigation
    notifyListeners();
  }
  
  void previousPage() {
    // TODO: Implement page navigation
    notifyListeners();
  }
  
  void clearStory() {
    _currentStory = null;
    _currentPosition = 0;
    notifyListeners();
  }
}