import 'dart:async';
import '../../data/models/story_document.dart';
import '../../data/models/sync_marker.dart';
import '../../data/models/media_item.dart';

class SyncService {
  static const String _syncStartPattern = r'<sync-start\s+([^>]+)>';
  static const String _syncEndPattern = r'<sync-end\s+([^>]+)>';
  
  final StreamController<SyncEvent> _syncEventController = StreamController<SyncEvent>.broadcast();
  
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;
  
  List<SyncMarker> _currentMarkers = [];
  int _currentTextPosition = 0;
  bool _isProcessing = false;

  /// Parse sync markers from story content
  List<SyncMarker> parseStoryContent(String content) {
    final markers = <SyncMarker>[];
    final startRegex = RegExp(_syncStartPattern, multiLine: true);
    final endRegex = RegExp(_syncEndPattern, multiLine: true);
    
    final startMatches = startRegex.allMatches(content).toList();
    final endMatches = endRegex.allMatches(content).toList();
    
    // Match start and end tags
    for (final startMatch in startMatches) {
      final startAttributes = _parseAttributes(startMatch.group(1) ?? '');
      final syncId = startAttributes['id'];
      
      if (syncId == null) continue;
      
      // Find corresponding end tag
      final endMatch = endMatches.cast<RegExp?>().firstWhere(
        (match) {
          if (match == null) return false;
          final endAttributes = _parseAttributes(match.group(1) ?? '');
          return endAttributes['id'] == syncId;
        },
        orElse: () => null,
      );
      
      if (endMatch != null) {
        final marker = SyncMarker(
          id: syncId,
          startPosition: startMatch.start,
          endPosition: endMatch.end,
          gridId: startAttributes['grid'] ?? '',
          mediaIds: _parseMediaIds(startAttributes['media'] ?? ''),
          properties: Map<String, dynamic>.from(startAttributes)
            ..remove('id')
            ..remove('grid')
            ..remove('media'),
        );
        
        markers.add(marker);
      }
    }
    
    return markers..sort((a, b) => a.startPosition.compareTo(b.startPosition));
  }

  /// Initialize synchronization with story markers
  void initializeSync(List<SyncMarker> markers) {
    _currentMarkers = List.from(markers);
    _currentTextPosition = 0;
    _isProcessing = false;
  }

  /// Update current reading position and trigger sync events
  void updateReadingPosition(int position) {
    if (_isProcessing) return;
    
    _currentTextPosition = position;
    _checkForSyncTriggers();
  }

  /// Check if any sync markers should be triggered at current position
  void _checkForSyncTriggers() {
    for (final marker in _currentMarkers) {
      if (marker.containsPosition(_currentTextPosition)) {
        _triggerSyncEvent(SyncEvent(
          type: SyncEventType.enter,
          marker: marker,
          position: _currentTextPosition,
        ));
      } else if (_wasInMarker(marker) && !marker.containsPosition(_currentTextPosition)) {
        _triggerSyncEvent(SyncEvent(
          type: SyncEventType.exit,
          marker: marker,
          position: _currentTextPosition,
        ));
      }
    }
  }

  /// Process sync event and update media grids
  void _triggerSyncEvent(SyncEvent event) {
    _syncEventController.add(event);
  }

  /// Check if we were previously in a marker (for exit detection)
  bool _wasInMarker(SyncMarker marker) {
    // This is a simplified implementation
    // In a real implementation, you'd track previous state
    return false;
  }

  /// Parse attributes from sync tag
  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final regex = RegExp(r'(\w+)=[\"\']([^\"\']+)[\"\']');
    
    for (final match in regex.allMatches(attributeString)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        attributes[key] = value;
      }
    }
    
    return attributes;
  }

  /// Parse comma-separated media IDs
  List<String> _parseMediaIds(String mediaString) {
    return mediaString
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Create a clean story content without sync tags for display
  String createCleanContent(String originalContent) {
    String cleanContent = originalContent;
    
    // Remove sync-start tags
    cleanContent = cleanContent.replaceAll(RegExp(_syncStartPattern), '');
    
    // Remove sync-end tags
    cleanContent = cleanContent.replaceAll(RegExp(_syncEndPattern), '');
    
    // Clean up any extra whitespace
    cleanContent = cleanContent.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return cleanContent.trim();
  }

  /// Get active sync markers at given position
  List<SyncMarker> getActiveMarkersAt(int position) {
    return _currentMarkers
        .where((marker) => marker.containsPosition(position))
        .toList();
  }

  /// Get next sync marker after given position
  SyncMarker? getNextMarkerAfter(int position) {
    final futureMarkers = _currentMarkers
        .where((marker) => marker.startPosition > position)
        .toList();
    
    if (futureMarkers.isEmpty) return null;
    
    futureMarkers.sort((a, b) => a.startPosition.compareTo(b.startPosition));
    return futureMarkers.first;
  }

  /// Get previous sync marker before given position
  SyncMarker? getPreviousMarkerBefore(int position) {
    final pastMarkers = _currentMarkers
        .where((marker) => marker.endPosition < position)
        .toList();
    
    if (pastMarkers.isEmpty) return null;
    
    pastMarkers.sort((a, b) => b.endPosition.compareTo(a.endPosition));
    return pastMarkers.first;
  }

  /// Jump to specific sync marker
  void jumpToMarker(SyncMarker marker) {
    updateReadingPosition(marker.startPosition);
  }

  /// Get sync statistics
  SyncStatistics getStatistics() {
    final totalMarkers = _currentMarkers.length;
    final activeMarkers = getActiveMarkersAt(_currentTextPosition);
    final completedMarkers = _currentMarkers
        .where((marker) => marker.endPosition < _currentTextPosition)
        .length;
    
    return SyncStatistics(
      totalMarkers: totalMarkers,
      activeMarkers: activeMarkers.length,
      completedMarkers: completedMarkers,
      remainingMarkers: totalMarkers - completedMarkers,
      progressPercentage: totalMarkers > 0 ? (completedMarkers / totalMarkers) : 0.0,
    );
  }

  /// Validate sync markers in content
  List<SyncValidationError> validateSyncMarkers(String content) {
    final errors = <SyncValidationError>[];
    final startMatches = RegExp(_syncStartPattern, multiLine: true).allMatches(content);
    final endMatches = RegExp(_syncEndPattern, multiLine: true).allMatches(content);
    
    final startIds = <String>[];
    final endIds = <String>[];
    
    // Collect all IDs
    for (final match in startMatches) {
      final attributes = _parseAttributes(match.group(1) ?? '');
      final id = attributes['id'];
      if (id != null) {
        if (startIds.contains(id)) {
          errors.add(SyncValidationError(
            type: SyncValidationErrorType.duplicateStartId,
            message: 'Duplicate sync-start ID: $id',
            position: match.start,
            id: id,
          ));
        }
        startIds.add(id);
      } else {
        errors.add(SyncValidationError(
          type: SyncValidationErrorType.missingId,
          message: 'sync-start tag missing id attribute',
          position: match.start,
        ));
      }
    }
    
    for (final match in endMatches) {
      final attributes = _parseAttributes(match.group(1) ?? '');
      final id = attributes['id'];
      if (id != null) {
        endIds.add(id);
      }
    }
    
    // Check for unmatched tags
    for (final id in startIds) {
      if (!endIds.contains(id)) {
        errors.add(SyncValidationError(
          type: SyncValidationErrorType.unmatchedStart,
          message: 'Unmatched sync-start tag with ID: $id',
          id: id,
        ));
      }
    }
    
    for (final id in endIds) {
      if (!startIds.contains(id)) {
        errors.add(SyncValidationError(
          type: SyncValidationErrorType.unmatchedEnd,
          message: 'Unmatched sync-end tag with ID: $id',
          id: id,
        ));
      }
    }
    
    return errors;
  }

  void dispose() {
    _syncEventController.close();
  }
}

/// Represents a synchronization event
class SyncEvent {
  final SyncEventType type;
  final SyncMarker marker;
  final int position;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.marker,
    required this.position,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum SyncEventType {
  enter,  // Entering a sync region
  exit,   // Exiting a sync region
}

/// Statistics about sync markers
class SyncStatistics {
  final int totalMarkers;
  final int activeMarkers;
  final int completedMarkers;
  final int remainingMarkers;
  final double progressPercentage;

  const SyncStatistics({
    required this.totalMarkers,
    required this.activeMarkers,
    required this.completedMarkers,
    required this.remainingMarkers,
    required this.progressPercentage,
  });
}

/// Validation error for sync markers
class SyncValidationError {
  final SyncValidationErrorType type;
  final String message;
  final int? position;
  final String? id;

  const SyncValidationError({
    required this.type,
    required this.message,
    this.position,
    this.id,
  });
}

enum SyncValidationErrorType {
  missingId,
  duplicateStartId,
  unmatchedStart,
  unmatchedEnd,
  invalidGrid,
  invalidMedia,
}