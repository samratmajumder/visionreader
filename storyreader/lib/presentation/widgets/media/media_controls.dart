import 'package:flutter/material.dart';
import '../../../data/models/media_item.dart';

class MediaControls extends StatefulWidget {
  final String gridId;
  final MediaItem mediaItem;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final VoidCallback onShowPlaylist;

  const MediaControls({
    super.key,
    required this.gridId,
    required this.mediaItem,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onShowPlaylist,
  });

  @override
  State<MediaControls> createState() => _MediaControlsState();
}

class _MediaControlsState extends State<MediaControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1 * _fadeAnimation.value),
                  Colors.black.withOpacity(0.7 * _fadeAnimation.value),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Top controls
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: _buildTopControls(),
                ),
                
                // Center play button
                Center(
                  child: _buildCenterControls(),
                ),
                
                // Bottom controls
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: _buildBottomControls(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        // Media info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mediaItem.fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getMediaInfo(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons
        _buildActionButton(
          icon: Icons.fullscreen,
          onPressed: _enterFullscreen,
          tooltip: 'Fullscreen',
        ),
        _buildActionButton(
          icon: Icons.more_vert,
          onPressed: _showOptions,
          tooltip: 'More options',
        ),
      ],
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: widget.onPrevious,
          size: 32,
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: widget.mediaItem.type == MediaType.video
              ? Icons.play_arrow
              : Icons.refresh,
          onPressed: widget.onPlayPause,
          size: 48,
          isPrimary: true,
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: widget.onNext,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        // Progress indicator for videos
        if (widget.mediaItem.type == MediaType.video)
          Expanded(
            child: _buildProgressBar(),
          )
        else
          Expanded(
            child: _buildImageTimer(),
          ),
        
        const SizedBox(width: 8),
        
        // Playlist button
        _buildActionButton(
          icon: Icons.playlist_play,
          onPressed: widget.onShowPlaylist,
          tooltip: 'Show playlist',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isPrimary 
            ? Colors.white.withOpacity(0.9) 
            : Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isPrimary ? Colors.black : Colors.white,
          size: size * 0.5,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 14),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildProgressBar() {
    // TODO: Implement actual video progress
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.3, // Mock progress
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildImageTimer() {
    // TODO: Implement actual image display timer
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.6, // Mock timer progress
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  String _getMediaInfo() {
    final type = widget.mediaItem.type == MediaType.image ? 'Image' : 'Video';
    final extension = widget.mediaItem.fileExtension.toUpperCase();
    
    if (widget.mediaItem.duration != null) {
      final duration = Duration(seconds: widget.mediaItem.duration!.toInt());
      final durationText = _formatDuration(duration);
      return '$type • $extension • $durationText';
    }
    
    return '$type • $extension';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _enterFullscreen() {
    // TODO: Implement fullscreen mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fullscreen mode coming soon')),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Media Info'),
              onTap: () {
                Navigator.pop(context);
                _showMediaInfo();
              },
            ),
            if (widget.mediaItem.type == MediaType.image)
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Display Duration'),
                onTap: () {
                  Navigator.pop(context);
                  _editDisplayDuration();
                },
              ),
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Zoom Settings'),
              onTap: () {
                Navigator.pop(context);
                _showZoomSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Panel Settings'),
              onTap: () {
                Navigator.pop(context);
                _showPanelSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.mediaItem.fileName),
            _buildInfoRow('Type', widget.mediaItem.type.name),
            _buildInfoRow('Path', widget.mediaItem.filePath),
            if (widget.mediaItem.duration != null)
              _buildInfoRow('Duration', _formatDuration(
                Duration(seconds: widget.mediaItem.duration!.toInt()))),
            _buildInfoRow('Modified', 
              widget.mediaItem.lastModified.toString().split('.')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editDisplayDuration() {
    // TODO: Implement display duration editor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Display duration editor coming soon')),
    );
  }

  void _showZoomSettings() {
    // TODO: Implement zoom settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zoom settings coming soon')),
    );
  }

  void _showPanelSettings() {
    // TODO: Implement panel settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panel settings coming soon')),
    );
  }
}