import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/providers/media_provider.dart';
import '../../../data/models/grid_layout.dart';
import '../media/media_grid_widget.dart';

class ResizableGridPanel extends StatefulWidget {
  final GridPanel panel;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double, double) onPositionChanged;
  final Function(double, double) onSizeChanged;
  final VoidCallback onDelete;

  const ResizableGridPanel({
    super.key,
    required this.panel,
    required this.isEditMode,
    required this.isSelected,
    required this.onTap,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.onDelete,
  });

  @override
  State<ResizableGridPanel> createState() => _ResizableGridPanelState();
}

class _ResizableGridPanelState extends State<ResizableGridPanel> {
  late double _currentX;
  late double _currentY;
  late double _currentWidth;
  late double _currentHeight;
  
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _currentX = widget.panel.x;
    _currentY = widget.panel.y;
    _currentWidth = widget.panel.width;
    _currentHeight = widget.panel.height;
  }

  @override
  void didUpdateWidget(ResizableGridPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.panel != oldWidget.panel) {
      _currentX = widget.panel.x;
      _currentY = widget.panel.y;
      _currentWidth = widget.panel.width;
      _currentHeight = widget.panel.height;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: widget.isEditMode ? _onPanStart : null,
      onPanUpdate: widget.isEditMode ? _onPanUpdate : null,
      onPanEnd: widget.isEditMode ? _onPanEnd : null,
      child: Container(
        width: _currentWidth,
        height: _currentHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.grey,
            width: widget.isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content area
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: MediaGridWidget(
                  gridId: widget.panel.id,
                  playlist: widget.panel.playlist,
                  isEditMode: widget.isEditMode,
                ),
              ),
            ),
            
            // Edit mode overlay
            if (widget.isEditMode) ...[
              // Drag handle
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Delete button
              if (widget.isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              
              // Resize handles
              if (widget.isSelected) ..._buildResizeHandles(),
            ],
            
            // Panel info overlay
            if (widget.isEditMode)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_currentWidth.toInt()}x${_currentHeight.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles() {
    const handleSize = 8.0;
    const handleColor = Colors.blue;

    return [
      // Corner handles
      _buildResizeHandle(
        Alignment.topLeft,
        handleSize,
        handleColor,
        Cursors.resizeUpLeft,
        ResizeDirection.topLeft,
      ),
      _buildResizeHandle(
        Alignment.topRight,
        handleSize,
        handleColor,
        Cursors.resizeUpRight,
        ResizeDirection.topRight,
      ),
      _buildResizeHandle(
        Alignment.bottomLeft,
        handleSize,
        handleColor,
        Cursors.resizeDownLeft,
        ResizeDirection.bottomLeft,
      ),
      _buildResizeHandle(
        Alignment.bottomRight,
        handleSize,
        handleColor,
        Cursors.resizeDownRight,
        ResizeDirection.bottomRight,
      ),
      
      // Edge handles
      _buildResizeHandle(
        Alignment.topCenter,
        handleSize,
        handleColor,
        Cursors.resizeUp,
        ResizeDirection.top,
      ),
      _buildResizeHandle(
        Alignment.bottomCenter,
        handleSize,
        handleColor,
        Cursors.resizeDown,
        ResizeDirection.bottom,
      ),
      _buildResizeHandle(
        Alignment.centerLeft,
        handleSize,
        handleColor,
        Cursors.resizeLeft,
        ResizeDirection.left,
      ),
      _buildResizeHandle(
        Alignment.centerRight,
        handleSize,
        handleColor,
        Cursors.resizeRight,
        ResizeDirection.right,
      ),
    ];
  }

  Widget _buildResizeHandle(
    Alignment alignment,
    double size,
    Color color,
    MouseCursor cursor,
    ResizeDirection direction,
  ) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            onPanStart: (details) => _onResizeStart(details, direction),
            onPanUpdate: (details) => _onResizeUpdate(details, direction),
            onPanEnd: _onResizeEnd,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isResizing) {
      _isDragging = true;
      _dragStart = details.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging && !_isResizing) {
      setState(() {
        _currentX += details.delta.dx;
        _currentY += details.delta.dy;
        
        // Keep panel within bounds
        _currentX = _currentX.clamp(0, double.infinity);
        _currentY = _currentY.clamp(0, double.infinity);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDragging) {
      _isDragging = false;
      widget.onPositionChanged(_currentX, _currentY);
    }
  }

  void _onResizeStart(DragStartDetails details, ResizeDirection direction) {
    _isResizing = true;
    _dragStart = details.localPosition;
  }

  void _onResizeUpdate(DragUpdateDetails details, ResizeDirection direction) {
    if (_isResizing) {
      setState(() {
        final delta = details.delta;
        
        switch (direction) {
          case ResizeDirection.topLeft:
            _currentX += delta.dx;
            _currentY += delta.dy;
            _currentWidth -= delta.dx;
            _currentHeight -= delta.dy;
            break;
          case ResizeDirection.topRight:
            _currentY += delta.dy;
            _currentWidth += delta.dx;
            _currentHeight -= delta.dy;
            break;
          case ResizeDirection.bottomLeft:
            _currentX += delta.dx;
            _currentWidth -= delta.dx;
            _currentHeight += delta.dy;
            break;
          case ResizeDirection.bottomRight:
            _currentWidth += delta.dx;
            _currentHeight += delta.dy;
            break;
          case ResizeDirection.top:
            _currentY += delta.dy;
            _currentHeight -= delta.dy;
            break;
          case ResizeDirection.bottom:
            _currentHeight += delta.dy;
            break;
          case ResizeDirection.left:
            _currentX += delta.dx;
            _currentWidth -= delta.dx;
            break;
          case ResizeDirection.right:
            _currentWidth += delta.dx;
            break;
        }
        
        // Enforce minimum size
        const minSize = 50.0;
        if (_currentWidth < minSize) {
          if (direction == ResizeDirection.left || direction == ResizeDirection.topLeft || direction == ResizeDirection.bottomLeft) {
            _currentX -= minSize - _currentWidth;
          }
          _currentWidth = minSize;
        }
        if (_currentHeight < minSize) {
          if (direction == ResizeDirection.top || direction == ResizeDirection.topLeft || direction == ResizeDirection.topRight) {
            _currentY -= minSize - _currentHeight;
          }
          _currentHeight = minSize;
        }
        
        // Keep panel within bounds
        _currentX = _currentX.clamp(0, double.infinity);
        _currentY = _currentY.clamp(0, double.infinity);
      });
    }
  }

  void _onResizeEnd(DragEndDetails details) {
    if (_isResizing) {
      _isResizing = false;
      widget.onPositionChanged(_currentX, _currentY);
      widget.onSizeChanged(_currentWidth, _currentHeight);
    }
  }
}

enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}