import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/providers/layout_provider.dart';
import '../../../business_logic/providers/media_provider.dart';
import '../../../business_logic/providers/settings_provider.dart';
import '../../../data/models/grid_layout.dart';
import '../../../data/models/media_item.dart';
import 'resizable_grid_panel.dart';
import 'grid_controls.dart';

class DynamicGridWidget extends StatefulWidget {
  const DynamicGridWidget({super.key});

  @override
  State<DynamicGridWidget> createState() => _DynamicGridWidgetState();
}

class _DynamicGridWidgetState extends State<DynamicGridWidget> {
  bool _isEditMode = false;
  GridPanel? _selectedPanel;

  @override
  Widget build(BuildContext context) {
    return Consumer3<LayoutProvider, MediaProvider, SettingsProvider>(
      builder: (context, layout, media, settings, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              if (settings.showGridControls) _buildControlBar(layout),
              Expanded(
                child: layout.hasLayout
                    ? _buildGridLayout(layout, media)
                    : _buildEmptyState(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(LayoutProvider layout) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              layout.setEditingMode(_isEditMode);
            },
            tooltip: _isEditMode ? 'Exit Edit Mode' : 'Enter Edit Mode',
          ),
          if (_isEditMode) ...[
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.add_box),
              onPressed: () => _addNewPanel(layout),
              tooltip: 'Add Panel',
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () => _showGridTemplates(layout),
              tooltip: 'Grid Templates',
            ),
          ],
          const Spacer(),
          if (layout.hasLayout) ...[
            Text(
              layout.currentLayout!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => layout.saveCurrentLayout(),
              tooltip: 'Save Layout',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridLayout(LayoutProvider layout, MediaProvider media) {
    return Stack(
      children: [
        // Grid background with snap guides
        if (_isEditMode) _buildGridBackground(),
        
        // Media panels
        ...layout.currentLayout!.panels.map((panel) {
          return Positioned(
            left: panel.x,
            top: panel.y,
            child: ResizableGridPanel(
              panel: panel,
              isEditMode: _isEditMode,
              isSelected: _selectedPanel?.id == panel.id,
              onTap: () => _selectPanel(panel),
              onPositionChanged: (newX, newY) => _updatePanelPosition(layout, panel.id, newX, newY),
              onSizeChanged: (newWidth, newHeight) => _updatePanelSize(layout, panel.id, newWidth, newHeight),
              onDelete: () => _deletePanel(layout, panel.id),
            ),
          );
        }).toList(),
        
        // Grid controls overlay
        if (_isEditMode && _selectedPanel != null)
          Positioned(
            right: 8,
            top: 8,
            child: GridControls(
              panel: _selectedPanel!,
              onDeletePanel: () => _deletePanel(layout, _selectedPanel!.id),
              onDuplicatePanel: () => _duplicatePanel(layout, _selectedPanel!),
              onBringToFront: () => _bringToFront(layout, _selectedPanel!.id),
              onSendToBack: () => _sendToBack(layout, _selectedPanel!.id),
            ),
          ),
      ],
    );
  }

  Widget _buildGridBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: GridBackgroundPainter(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Layout Created',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new layout to start organizing your media',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewLayout(),
            icon: const Icon(Icons.add),
            label: const Text('Create Layout'),
          ),
        ],
      ),
    );
  }

  void _selectPanel(GridPanel panel) {
    setState(() {
      _selectedPanel = panel;
    });
  }

  void _addNewPanel(LayoutProvider layout) {
    final newPanel = GridPanel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      x: 50.0,
      y: 50.0,
      width: 200.0,
      height: 150.0,
      playlist: [],
    );
    
    layout.addPanel(newPanel);
    _selectPanel(newPanel);
  }

  void _updatePanelPosition(LayoutProvider layout, String panelId, double x, double y) {
    final currentLayout = layout.currentLayout!;
    final panelIndex = currentLayout.panels.indexWhere((p) => p.id == panelId);
    
    if (panelIndex != -1) {
      final updatedPanel = currentLayout.panels[panelIndex].copyWith(x: x, y: y);
      final updatedPanels = List<GridPanel>.from(currentLayout.panels);
      updatedPanels[panelIndex] = updatedPanel;
      
      final updatedLayout = currentLayout.copyWith(panels: updatedPanels);
      layout.loadLayout(updatedLayout);
    }
  }

  void _updatePanelSize(LayoutProvider layout, String panelId, double width, double height) {
    final currentLayout = layout.currentLayout!;
    final panelIndex = currentLayout.panels.indexWhere((p) => p.id == panelId);
    
    if (panelIndex != -1) {
      final updatedPanel = currentLayout.panels[panelIndex].copyWith(
        width: width,
        height: height,
      );
      final updatedPanels = List<GridPanel>.from(currentLayout.panels);
      updatedPanels[panelIndex] = updatedPanel;
      
      final updatedLayout = currentLayout.copyWith(panels: updatedPanels);
      layout.loadLayout(updatedLayout);
    }
  }

  void _deletePanel(LayoutProvider layout, String panelId) {
    layout.removePanel(panelId);
    if (_selectedPanel?.id == panelId) {
      setState(() {
        _selectedPanel = null;
      });
    }
  }

  void _duplicatePanel(LayoutProvider layout, GridPanel panel) {
    final duplicatedPanel = panel.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      x: panel.x + 20,
      y: panel.y + 20,
    );
    
    layout.addPanel(duplicatedPanel);
    _selectPanel(duplicatedPanel);
  }

  void _bringToFront(LayoutProvider layout, String panelId) {
    final currentLayout = layout.currentLayout!;
    final panels = List<GridPanel>.from(currentLayout.panels);
    final panelIndex = panels.indexWhere((p) => p.id == panelId);
    
    if (panelIndex != -1) {
      final panel = panels.removeAt(panelIndex);
      panels.add(panel);
      
      final updatedLayout = currentLayout.copyWith(panels: panels);
      layout.loadLayout(updatedLayout);
    }
  }

  void _sendToBack(LayoutProvider layout, String panelId) {
    final currentLayout = layout.currentLayout!;
    final panels = List<GridPanel>.from(currentLayout.panels);
    final panelIndex = panels.indexWhere((p) => p.id == panelId);
    
    if (panelIndex != -1) {
      final panel = panels.removeAt(panelIndex);
      panels.insert(0, panel);
      
      final updatedLayout = currentLayout.copyWith(panels: panels);
      layout.loadLayout(updatedLayout);
    }
  }

  void _createNewLayout() {
    final layout = context.read<LayoutProvider>();
    layout.createNewLayout('New Layout ${DateTime.now().millisecondsSinceEpoch}');
    setState(() {
      _isEditMode = true;
    });
  }

  void _showGridTemplates(LayoutProvider layout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Templates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Single Panel'),
              onTap: () => _applyTemplate(layout, 'single'),
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda),
              title: const Text('Two Panels (Vertical)'),
              onTap: () => _applyTemplate(layout, 'two_vertical'),
            ),
            ListTile(
              leading: const Icon(Icons.view_day),
              title: const Text('Two Panels (Horizontal)'),
              onTap: () => _applyTemplate(layout, 'two_horizontal'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Four Panels'),
              onTap: () => _applyTemplate(layout, 'four_grid'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(LayoutProvider layout, String templateType) {
    Navigator.of(context).pop();
    
    final List<GridPanel> templatePanels = [];
    
    switch (templateType) {
      case 'single':
        templatePanels.add(GridPanel(
          id: '1',
          x: 50,
          y: 50,
          width: 300,
          height: 200,
          playlist: [],
        ));
        break;
        
      case 'two_vertical':
        templatePanels.addAll([
          GridPanel(id: '1', x: 20, y: 20, width: 180, height: 150, playlist: []),
          GridPanel(id: '2', x: 220, y: 20, width: 180, height: 150, playlist: []),
        ]);
        break;
        
      case 'two_horizontal':
        templatePanels.addAll([
          GridPanel(id: '1', x: 20, y: 20, width: 300, height: 100, playlist: []),
          GridPanel(id: '2', x: 20, y: 140, width: 300, height: 100, playlist: []),
        ]);
        break;
        
      case 'four_grid':
        templatePanels.addAll([
          GridPanel(id: '1', x: 20, y: 20, width: 150, height: 120, playlist: []),
          GridPanel(id: '2', x: 190, y: 20, width: 150, height: 120, playlist: []),
          GridPanel(id: '3', x: 20, y: 160, width: 150, height: 120, playlist: []),
          GridPanel(id: '4', x: 190, y: 160, width: 150, height: 120, playlist: []),
        ]);
        break;
    }
    
    // Clear existing panels and add template panels
    final currentLayout = layout.currentLayout!;
    final updatedLayout = currentLayout.copyWith(panels: templatePanels);
    layout.loadLayout(updatedLayout);
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}