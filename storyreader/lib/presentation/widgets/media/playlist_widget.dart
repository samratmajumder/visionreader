import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/providers/media_provider.dart';
import '../../../business_logic/providers/settings_provider.dart';
import '../../../data/models/media_item.dart';

class PlaylistWidget extends StatefulWidget {
  final String gridId;
  final List<MediaItem> playlist;
  final VoidCallback onClose;

  const PlaylistWidget({
    super.key,
    required this.gridId,
    required this.playlist,
    required this.onClose,
  });

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent tap from propagating
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildPlaylistContent()),
                    _buildPlaylistControls(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_play, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.playlist.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent() {
    if (widget.playlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_remove, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No media in playlist',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add images or videos to get started',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Consumer<MediaProvider>(
      builder: (context, media, child) {
        final currentIndex = media.getCurrentIndex(widget.gridId);
        
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.playlist.length,
          onReorder: (oldIndex, newIndex) => _reorderPlaylist(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final item = widget.playlist[index];
            final isCurrentItem = index == currentIndex;
            
            return _buildPlaylistItem(
              key: ValueKey(item.id),
              item: item,
              index: index,
              isCurrentItem: isCurrentItem,
              onTap: () => _selectItem(media, index),
              onRemove: () => _removeItem(media, index),
              onEdit: () => _editItem(item),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistItem({
    required Key key,
    required MediaItem item,
    required int index,
    required bool isCurrentItem,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required VoidCallback onEdit,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentItem ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentItem
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: _buildItemThumbnail(item),
        title: Text(
          item.fileName,
          style: TextStyle(
            fontWeight: isCurrentItem ? FontWeight.bold : FontWeight.normal,
            color: isCurrentItem ? Colors.blue : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              item.type == MediaType.image ? Icons.image : Icons.videocam,
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _getItemSubtitle(item),
              style: const TextStyle(fontSize: 10),
            ),
            if (item.duration != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDuration(Duration(seconds: item.duration!.toInt())),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentItem)
              Icon(
                Icons.play_arrow,
                color: Colors.blue,
                size: 20,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'remove':
                    onRemove();
                    break;
                }
              },
            ),
            const Icon(Icons.drag_handle, size: 16, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildItemThumbnail(MediaItem item) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: item.type == MediaType.image
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.filePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, color: Colors.grey);
                },
              ),
            )
          : const Icon(Icons.videocam, color: Colors.grey),
    );
  }

  Widget _buildPlaylistControls() {
    return Consumer2<MediaProvider, SettingsProvider>(
      builder: (context, media, settings, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              // Shuffle
              IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: () => _shufflePlaylist(media),
                tooltip: 'Shuffle',
              ),
              
              // Loop
              IconButton(
                icon: Icon(
                  settings.loopPlaylists ? Icons.repeat_one : Icons.repeat,
                  color: settings.loopPlaylists ? Colors.blue : null,
                ),
                onPressed: () => settings.setLoopPlaylists(!settings.loopPlaylists),
                tooltip: 'Loop',
              ),
              
              const Spacer(),
              
              // Add media
              ElevatedButton.icon(
                onPressed: _addMedia,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Media'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Clear all
              OutlinedButton.icon(
                onPressed: widget.playlist.isNotEmpty ? _clearPlaylist : null,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectItem(MediaProvider media, int index) {
    media.setCurrentIndex(widget.gridId, index);
  }

  void _removeItem(MediaProvider media, int index) {
    media.removeFromPlaylist(widget.gridId, index);
  }

  void _editItem(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Media Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.type == MediaType.image) ...[
              const Text('Display Duration (seconds):'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: item.duration?.toString() ?? '3.0',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Duration in seconds',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // TODO: Update item duration
                },
              ),
            ] else ...[
              Text('Video: ${item.fileName}'),
              const SizedBox(height: 8),
              const Text('Video settings will be available soon.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _reorderPlaylist(int oldIndex, int newIndex) {
    // TODO: Implement playlist reordering
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    // Update the playlist order in the provider
  }

  void _shufflePlaylist(MediaProvider media) {
    // TODO: Implement playlist shuffle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shuffle feature coming soon')),
    );
  }

  void _addMedia() {
    // TODO: Open file picker to add more media
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add media feature coming soon')),
    );
  }

  void _clearPlaylist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Playlist'),
        content: const Text('Are you sure you want to remove all media from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MediaProvider>().clearGrid(widget.gridId);
              Navigator.of(context).pop();
              _close();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  String _getItemSubtitle(MediaItem item) {
    final extension = item.fileExtension.toUpperCase();
    final size = _getFileSize(item.filePath);
    return '$extension • $size';
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}