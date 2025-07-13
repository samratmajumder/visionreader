import 'package:json_annotation/json_annotation.dart';

part 'media_item.g.dart';

enum MediaType { image, video }

@JsonSerializable()
class MediaItem {
  final String id;
  final String filePath;
  final String fileName;
  final MediaType type;
  final double? duration; // For videos and image display time
  final Map<String, dynamic> metadata;
  final DateTime lastModified;

  const MediaItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.duration,
    this.metadata = const {},
    required this.lastModified,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);

  MediaItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    MediaType? type,
    double? duration,
    Map<String, dynamic>? metadata,
    DateTime? lastModified,
  }) {
    return MediaItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  String get displayName => fileName;
  
  bool get isImage => type == MediaType.image;
  
  bool get isVideo => type == MediaType.video;
  
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }
  
  double get aspectRatio {
    final width = metadata['width'] as double? ?? 16.0;
    final height = metadata['height'] as double? ?? 9.0;
    return width / height;
  }
}