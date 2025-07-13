import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../business_logic/providers/settings_provider.dart';

class TextCustomizationPanel extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const TextCustomizationPanel({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<TextCustomizationPanel> createState() => _TextCustomizationPanelState();
}

class _TextCustomizationPanelState extends State<TextCustomizationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<String> _fontFamilies = [
    'System',
    'Serif',
    'Sans-serif',
    'Monospace',
    'Georgia',
    'Times New Roman',
    'Arial',
    'Helvetica',
    'Courier New',
  ];

  final List<Map<String, dynamic>> _presetThemes = [
    {
      'name': 'Light',
      'background': Colors.white,
      'text': Colors.black87,
      'icon': Icons.light_mode,
    },
    {
      'name': 'Dark',
      'background': Color(0xFF1E1E1E),
      'text': Colors.white,
      'icon': Icons.dark_mode,
    },
    {
      'name': 'Sepia',
      'background': Color(0xFFF4F1EA),
      'text': Color(0xFF5C4B37),
      'icon': Icons.auto_stories,
    },
    {
      'name': 'High Contrast',
      'background': Colors.black,
      'text': Colors.white,
      'icon': Icons.contrast,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(TextCustomizationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
          child: Container(
            width: 320,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPresetThemes(settings),
                            const SizedBox(height: 24),
                            _buildFontSizeControl(settings),
                            const SizedBox(height: 24),
                            _buildFontFamilyControl(settings),
                            const SizedBox(height: 24),
                            _buildColorControls(settings),
                            const SizedBox(height: 24),
                            _buildAutoScrollControls(settings),
                            const SizedBox(height: 24),
                            _buildResetButton(settings),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_paint),
          const SizedBox(width: 12),
          const Text(
            'Text Customization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetThemes(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Themes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetThemes.map((theme) {
            final isSelected = settings.backgroundColor == theme['background'] &&
                settings.textColor == theme['text'];
            
            return GestureDetector(
              onTap: () {
                settings.setBackgroundColor(theme['background']);
                settings.setTextColor(theme['text']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme['background'],
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(theme['icon'], color: theme['text'], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      theme['name'],
                      style: TextStyle(color: theme['text'], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSizeControl(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Font Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${settings.fontSize.toInt()}px',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => settings.setFontSize(settings.fontSize - 1),
            ),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: 8,
                max: 72,
                divisions: 64,
                onChanged: settings.setFontSize,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => settings.setFontSize(settings.fontSize + 1),
            ),
          ],
        ),
        Center(
          child: Text(
            'Sample text at current size',
            style: TextStyle(
              fontSize: settings.fontSize,
              fontFamily: settings.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilyControl(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Family',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: settings.fontFamily,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _fontFamilies.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setFontFamily(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildColorControls(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colors',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildColorPicker(
                'Background',
                settings.backgroundColor,
                (color) => settings.setBackgroundColor(color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildColorPicker(
                'Text',
                settings.textColor,
                (color) => settings.setTextColor(color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showColorPicker(currentColor, onChanged),
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoScrollControls(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auto-scroll Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Default Speed'),
            Text('${settings.autoScrollSpeed.toStringAsFixed(1)}x'),
          ],
        ),
        Slider(
          value: settings.autoScrollSpeed,
          min: 0.1,
          max: 5.0,
          divisions: 49,
          onChanged: settings.setAutoScrollSpeed,
        ),
      ],
    );
  }

  Widget _buildResetButton(SettingsProvider settings) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showResetDialog(settings),
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onChanged,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all customization settings to their defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}