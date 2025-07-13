class AppConstants {
  static const String appName = 'StoryReader';
  static const String appVersion = '1.0.0';
  
  // File Extensions
  static const List<String> supportedTextFormats = ['txt', 'docx', 'pdf', 'html'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  
  // Layout Constants
  static const double minGridSize = 100.0;
  static const double maxGridSize = 800.0;
  static const double defaultGridSize = 300.0;
  
  // Auto-scroll Constants
  static const double minScrollSpeed = 0.1;
  static const double maxScrollSpeed = 10.0;
  static const double defaultScrollSpeed = 1.0;
  
  // Text Constants
  static const double minFontSize = 8.0;
  static const double maxFontSize = 72.0;
  static const double defaultFontSize = 16.0;
  
  // Media Constants
  static const double defaultImageDisplayDuration = 3.0; // seconds
  static const double minImageDisplayDuration = 0.5;
  static const double maxImageDisplayDuration = 60.0;
  
  // Sync Tag Constants
  static const String syncStartTag = '<sync-start';
  static const String syncEndTag = '<sync-end';
  
  // Settings Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyFontSize = 'font_size';
  static const String keyFontFamily = 'font_family';
  static const String keyBackgroundColor = 'background_color';
  static const String keyTextColor = 'text_color';
  static const String keyAutoScrollSpeed = 'auto_scroll_speed';
  static const String keyLastOpenedStory = 'last_opened_story';
  static const String keyRecentLayouts = 'recent_layouts';
}