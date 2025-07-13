import 'package:flutter/material.dart';
import '../../data/models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  final Map<String, List<MediaItem>> _gridPlaylists = {};
  final Map<String, int> _currentIndices = {};
  final Map<String, bool> _isPlaying = {};
  
  // Getters
  List<MediaItem> getPlaylist(String gridId) => _gridPlaylists[gridId] ?? [];
  int getCurrentIndex(String gridId) => _currentIndices[gridId] ?? 0;
  bool isPlaying(String gridId) => _isPlaying[gridId] ?? false;
  
  MediaItem? getCurrentMedia(String gridId) {
    final playlist = getPlaylist(gridId);
    final index = getCurrentIndex(gridId);
    return playlist.isNotEmpty && index < playlist.length ? playlist[index] : null;
  }
  
  // Playlist management
  void setPlaylist(String gridId, List<MediaItem> items) {
    _gridPlaylists[gridId] = items;
    _currentIndices[gridId] = 0;
    notifyListeners();
  }
  
  void addToPlaylist(String gridId, MediaItem item) {
    _gridPlaylists[gridId] = [...(_gridPlaylists[gridId] ?? []), item];
    notifyListeners();
  }
  
  void removeFromPlaylist(String gridId, int index) {
    final playlist = _gridPlaylists[gridId];
    if (playlist != null && index < playlist.length) {
      playlist.removeAt(index);
      if (_currentIndices[gridId]! >= playlist.length) {
        _currentIndices[gridId] = playlist.isNotEmpty ? playlist.length - 1 : 0;
      }
      notifyListeners();
    }
  }
  
  // Playback control
  void play(String gridId) {
    _isPlaying[gridId] = true;
    notifyListeners();
  }
  
  void pause(String gridId) {
    _isPlaying[gridId] = false;
    notifyListeners();
  }
  
  void next(String gridId) {
    final playlist = getPlaylist(gridId);
    if (playlist.isNotEmpty) {
      final currentIndex = getCurrentIndex(gridId);
      _currentIndices[gridId] = (currentIndex + 1) % playlist.length;
      notifyListeners();
    }
  }
  
  void previous(String gridId) {
    final playlist = getPlaylist(gridId);
    if (playlist.isNotEmpty) {
      final currentIndex = getCurrentIndex(gridId);
      _currentIndices[gridId] = currentIndex > 0 ? currentIndex - 1 : playlist.length - 1;
      notifyListeners();
    }
  }
  
  void setCurrentIndex(String gridId, int index) {
    final playlist = getPlaylist(gridId);
    if (playlist.isNotEmpty && index >= 0 && index < playlist.length) {
      _currentIndices[gridId] = index;
      notifyListeners();
    }
  }
  
  // Clear grid
  void clearGrid(String gridId) {
    _gridPlaylists.remove(gridId);
    _currentIndices.remove(gridId);
    _isPlaying.remove(gridId);
    notifyListeners();
  }
}