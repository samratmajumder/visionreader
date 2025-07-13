import 'package:flutter/material.dart';
import '../../../data/models/grid_layout.dart';

class GridControls extends StatelessWidget {
  final GridPanel panel;
  final VoidCallback onDeletePanel;
  final VoidCallback onDuplicatePanel;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;

  const GridControls({
    super.key,
    required this.panel,
    required this.onDeletePanel,
    required this.onDuplicatePanel,
    required this.onBringToFront,
    required this.onSendToBack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Controls',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            
            // Panel info
            _buildInfoRow('ID', panel.id),
            _buildInfoRow('Position', '${panel.x.toInt()}, ${panel.y.toInt()}'),
            _buildInfoRow('Size', '${panel.width.toInt()} × ${panel.height.toInt()}'),
            _buildInfoRow('Media Items', '${panel.playlist.length}'),
            
            const SizedBox(height: 12),
            
            // Control buttons
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildControlButton(
                  icon: Icons.content_copy,
                  label: 'Duplicate',
                  onPressed: onDuplicatePanel,
                  color: Colors.blue,
                ),
                _buildControlButton(
                  icon: Icons.flip_to_front,
                  label: 'To Front',
                  onPressed: onBringToFront,
                  color: Colors.green,
                ),
                _buildControlButton(
                  icon: Icons.flip_to_back,
                  label: 'To Back',
                  onPressed: onSendToBack,
                  color: Colors.orange,
                ),
                _buildControlButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onPressed: () => _confirmDelete(context),
                  color: Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Panel settings
            _buildPanelSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 88,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panel Settings',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Aspect ratio lock
        Row(
          children: [
            const Icon(Icons.aspect_ratio, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Lock Aspect Ratio', style: TextStyle(fontSize: 11)),
            ),
            Switch(
              value: panel.settings['lockAspectRatio'] ?? false,
              onChanged: (value) {
                // TODO: Implement aspect ratio lock
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        
        // Auto-fit media
        Row(
          children: [
            const Icon(Icons.fit_screen, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Auto-fit Media', style: TextStyle(fontSize: 11)),
            ),
            Switch(
              value: panel.settings['autoFitMedia'] ?? true,
              onChanged: (value) {
                // TODO: Implement auto-fit media
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        
        // Show controls
        Row(
          children: [
            const Icon(Icons.control_camera, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Show Controls', style: TextStyle(fontSize: 11)),
            ),
            Switch(
              value: panel.settings['showControls'] ?? true,
              onChanged: (value) {
                // TODO: Implement show controls
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Panel'),
        content: const Text('Are you sure you want to delete this panel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeletePanel();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}