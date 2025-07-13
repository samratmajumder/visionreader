import 'package:json_annotation/json_annotation.dart';

part 'sync_marker.g.dart';

@JsonSerializable()
class SyncMarker {
  final String id;
  final int startPosition;
  final int endPosition;
  final String gridId;
  final List<String> mediaIds;
  final Map<String, dynamic> properties;

  const SyncMarker({
    required this.id,
    required this.startPosition,
    required this.endPosition,
    required this.gridId,
    required this.mediaIds,
    this.properties = const {},
  });

  factory SyncMarker.fromJson(Map<String, dynamic> json) =>
      _$SyncMarkerFromJson(json);

  Map<String, dynamic> toJson() => _$SyncMarkerToJson(this);

  SyncMarker copyWith({
    String? id,
    int? startPosition,
    int? endPosition,
    String? gridId,
    List<String>? mediaIds,
    Map<String, dynamic>? properties,
  }) {
    return SyncMarker(
      id: id ?? this.id,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      gridId: gridId ?? this.gridId,
      mediaIds: mediaIds ?? this.mediaIds,
      properties: properties ?? this.properties,
    );
  }

  bool containsPosition(int position) {
    return position >= startPosition && position <= endPosition;
  }

  bool get hasMedia => mediaIds.isNotEmpty;
  
  int get textLength => endPosition - startPosition;
}