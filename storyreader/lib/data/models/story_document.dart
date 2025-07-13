import 'package:json_annotation/json_annotation.dart';
import 'sync_marker.dart';

part 'story_document.g.dart';

@JsonSerializable()
class StoryDocument {
  final String id;
  final String title;
  final String filePath;
  final String fileType;
  final String content;
  final List<SyncMarker> syncMarkers;
  final DateTime lastModified;
  final Map<String, dynamic> metadata;

  const StoryDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.content,
    required this.syncMarkers,
    required this.lastModified,
    this.metadata = const {},
  });

  factory StoryDocument.fromJson(Map<String, dynamic> json) =>
      _$StoryDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$StoryDocumentToJson(this);

  StoryDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    String? content,
    List<SyncMarker>? syncMarkers,
    DateTime? lastModified,
    Map<String, dynamic>? metadata,
  }) {
    return StoryDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      content: content ?? this.content,
      syncMarkers: syncMarkers ?? this.syncMarkers,
      lastModified: lastModified ?? this.lastModified,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayName => title.isNotEmpty ? title : 'Untitled Story';
  
  bool get hasSyncMarkers => syncMarkers.isNotEmpty;
  
  int get wordCount => content.split(RegExp(r'\s+')).length;
  
  Duration get estimatedReadingTime {
    const int wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return Duration(minutes: minutes);
  }
}