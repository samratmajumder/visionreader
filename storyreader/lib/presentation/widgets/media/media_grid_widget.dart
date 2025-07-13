import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../business_logic/providers/media_provider.dart';
import '../../../business_logic/providers/settings_provider.dart';
import '../../../data/models/media_item.dart';
import 'playlist_widget.dart';
import 'media_controls.dart';

class MediaGridWidget extends StatefulWidget {
  final String gridId;
  final List<MediaItem> playlist;
  final bool isEditMode;

  const MediaGridWidget({
    super.key,
    required this.gridId,
    required this.playlist,
    this.isEditMode = false,
  });

  @override
  State<MediaGridWidget> createState() => _MediaGridWidgetState();
}

class _MediaGridWidgetState extends State<MediaGridWidget> {
  bool _showControls = false;
  bool _showPlaylist = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaProvider = context.read<MediaProvider>();
      if (widget.playlist.isNotEmpty) {
        mediaProvider.setPlaylist(widget.gridId, widget.playlist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MediaProvider, SettingsProvider>(
      builder: (context, media, settings, child) {
        final currentMedia = media.getCurrentMedia(widget.gridId);
        final hasMedia = currentMedia != null;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _showControls = true),
          onExit: (_) => setState(() => _showControls = false),
          child: GestureDetector(
            onTap: () => _handleTap(media),
            onDoubleTap: () => _handleDoubleTap(),
            onLongPress: () => _handleLongPress(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: hasMedia ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Main media content
                  if (hasMedia)
                    _buildMediaContent(currentMedia, media)
                  else
                    _buildEmptyState(),
                  
                  // Media controls overlay
                  if (_showControls && hasMedia && !widget.isEditMode)
                    Positioned.fill(
                      child: MediaControls(
                        gridId: widget.gridId,
                        mediaItem: currentMedia,
                        onPrevious: () => media.previous(widget.gridId),
                        onNext: () => media.next(widget.gridId),
                        onPlayPause: () => _togglePlayback(media),
                        onShowPlaylist: () => setState(() => _showPlaylist = true),
                      ),
                    ),
                  
                  // Playlist overlay
                  if (_showPlaylist)
                    Positioned.fill(
                      child: PlaylistWidget(
                        gridId: widget.gridId,
                        playlist: widget.playlist,
                        onClose: () => setState(() => _showPlaylist = false),
                      ),
                    ),
                  
                  // Edit mode overlay
                  if (widget.isEditMode)
                    _buildEditModeOverlay(),
                  
                  // Media info badge
                  if (hasMedia && widget.playlist.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${media.getCurrentIndex(widget.gridId) + 1}/${widget.playlist.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaContent(MediaItem mediaItem, MediaProvider media) {
    switch (mediaItem.type) {
      case MediaType.image:
        return _buildImageContent(mediaItem);
      case MediaType.video:
        return _buildVideoContent(mediaItem, media);
    }
  }

  Widget _buildImageContent(MediaItem mediaItem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(mediaItem.filePath),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Failed to load image');
        },
      ),
    );
  }

  Widget _buildVideoContent(MediaItem mediaItem, MediaProvider media) {
    // For now, show a placeholder with video info
    // TODO: Integrate video_player package
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              media.isPlaying(widget.gridId) ? Icons.pause_circle : Icons.play_circle,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              mediaItem.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (mediaItem.duration != null)
              Text(
                _formatDuration(Duration(seconds: mediaItem.duration!.toInt())),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return DragTarget<List<String>>(
      onAccept: (filePaths) => _handleFileDrop(filePaths),
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            color: isDragOver ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
            border: Border.all(
              color: isDragOver ? Colors.blue : Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDragOver ? Icons.file_download : Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: isDragOver ? Colors.blue : Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  isDragOver ? 'Drop files here' : 'Add Media',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDragOver ? Colors.blue : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isDragOver)
                  Text(
                    'Drag & drop or click to add\nimages and videos',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditModeOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            const Text(
              'Edit Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(MediaProvider media) {
    if (widget.isEditMode) {
      _openFilePicker();
    } else if (media.getCurrentMedia(widget.gridId) != null) {
      _togglePlayback(media);
    } else {
      _openFilePicker();
    }
  }

  void _handleDoubleTap() {
    // TODO: Implement fullscreen mode
  }

  void _handleLongPress() {
    if (!widget.isEditMode) {
      setState(() => _showPlaylist = true);
    }
  }

  void _togglePlayback(MediaProvider media) {
    if (media.isPlaying(widget.gridId)) {
      media.pause(widget.gridId);
    } else {
      media.play(widget.gridId);
    }
  }

  void _openFilePicker() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker integration coming soon')),
    );
  }

  void _handleFileDrop(List<String> filePaths) {
    // TODO: Implement drag and drop file handling
    final mediaProvider = context.read<MediaProvider>();
    final mediaItems = <MediaItem>[];
    
    for (final filePath in filePaths) {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      MediaType? type;
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
        type = MediaType.image;
      } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(extension)) {
        type = MediaType.video;
      }
      
      if (type != null) {
        final mediaItem = MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: filePath,
          fileName: fileName,
          type: type,
          lastModified: file.lastModifiedSync(),
        );
        mediaItems.add(mediaItem);
      }
    }
    
    if (mediaItems.isNotEmpty) {
      for (final item in mediaItems) {
        mediaProvider.addToPlaylist(widget.gridId, item);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}