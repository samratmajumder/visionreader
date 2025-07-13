import 'package:flutter/material.dart';
import '../../data/models/grid_layout.dart';

class LayoutProvider extends ChangeNotifier {
  GridLayout? _currentLayout;
  List<GridLayout> _savedLayouts = [];
  bool _isEditing = false;
  
  // Getters
  GridLayout? get currentLayout => _currentLayout;
  List<GridLayout> get savedLayouts => _savedLayouts;
  bool get isEditing => _isEditing;
  bool get hasLayout => _currentLayout != null;
  
  // Layout management
  void createNewLayout(String name) {
    final layout = GridLayout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      panels: [],
      storyPanelWidth: 400.0,
      lastModified: DateTime.now(),
    );
    
    _currentLayout = layout;
    notifyListeners();
  }
  
  void loadLayout(GridLayout layout) {
    _currentLayout = layout;
    notifyListeners();
  }
  
  Future<void> saveCurrentLayout() async {
    if (_currentLayout != null) {
      // TODO: Implement save logic
      _savedLayouts.add(_currentLayout!);
      notifyListeners();
    }
  }
  
  void addPanel(GridPanel panel) {
    if (_currentLayout != null) {
      final updatedPanels = List<GridPanel>.from(_currentLayout!.panels)..add(panel);
      _currentLayout = _currentLayout!.copyWith(panels: updatedPanels);
      notifyListeners();
    }
  }
  
  void removePanel(String panelId) {
    if (_currentLayout != null) {
      final updatedPanels = _currentLayout!.panels.where((p) => p.id != panelId).toList();
      _currentLayout = _currentLayout!.copyWith(panels: updatedPanels);
      notifyListeners();
    }
  }
  
  void setEditingMode(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }
}