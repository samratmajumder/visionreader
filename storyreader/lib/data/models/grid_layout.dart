import 'package:json_annotation/json_annotation.dart';
import 'media_item.dart';

part 'grid_layout.g.dart';

@JsonSerializable()
class GridPanel {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final List<MediaItem> playlist;
  final int currentIndex;
  final Map<String, dynamic> settings;

  const GridPanel({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.playlist,
    this.currentIndex = 0,
    this.settings = const {},
  });

  factory GridPanel.fromJson(Map<String, dynamic> json) =>
      _$GridPanelFromJson(json);

  Map<String, dynamic> toJson() => _$GridPanelToJson(this);

  GridPanel copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    List<MediaItem>? playlist,
    int? currentIndex,
    Map<String, dynamic>? settings,
  }) {
    return GridPanel(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      settings: settings ?? this.settings,
    );
  }

  bool get hasMedia => playlist.isNotEmpty;
  
  MediaItem? get currentMedia => 
      playlist.isNotEmpty && currentIndex < playlist.length 
          ? playlist[currentIndex] 
          : null;
          
  bool get isPlaylist => playlist.length > 1;
  
  double get aspectRatio => width / height;
}

@JsonSerializable()
class GridLayout {
  final String id;
  final String name;
  final List<GridPanel> panels;
  final double storyPanelWidth;
  final Map<String, dynamic> settings;
  final DateTime lastModified;

  const GridLayout({
    required this.id,
    required this.name,
    required this.panels,
    required this.storyPanelWidth,
    this.settings = const {},
    required this.lastModified,
  });

  factory GridLayout.fromJson(Map<String, dynamic> json) =>
      _$GridLayoutFromJson(json);

  Map<String, dynamic> toJson() => _$GridLayoutToJson(this);

  GridLayout copyWith({
    String? id,
    String? name,
    List<GridPanel>? panels,
    double? storyPanelWidth,
    Map<String, dynamic>? settings,
    DateTime? lastModified,
  }) {
    return GridLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      panels: panels ?? this.panels,
      storyPanelWidth: storyPanelWidth ?? this.storyPanelWidth,
      settings: settings ?? this.settings,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  GridPanel? getPanelById(String panelId) {
    try {
      return panels.firstWhere((panel) => panel.id == panelId);
    } catch (e) {
      return null;
    }
  }
  
  bool get hasPanels => panels.isNotEmpty;
  
  int get totalMediaItems => panels.fold(0, (sum, panel) => sum + panel.playlist.length);
}