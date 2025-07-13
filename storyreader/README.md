# StoryReader - Multimedia Story Reader Application

A cross-platform multimedia story reader that combines text stories with synchronized images and videos in customizable grid layouts.

## Features

- 📚 Support for multiple story formats (TXT, DOCX, PDF, HTML)
- 🎬 Rich media support (images and videos)
- 📱 Cross-platform (Windows, macOS, Android)
- 🔄 Auto-scroll with variable speed
- 🎨 Customizable text appearance and themes
- 📐 Dynamic grid layout system
- 🎵 Media playlists with synchronization
- 💾 Layout save/load functionality
- 📦 Portable story packages

## Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **File Handling**: file_picker, path_provider
- **Media**: video_player, image
- **Document Parsing**: pdf, html, docx_to_text
- **Storage**: shared_preferences, json_serializable
- **Packaging**: archive

## Getting Started

### Prerequisites

1. **Install Flutter SDK**
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   # Or use your package manager:
   
   # macOS (using Homebrew)
   brew install --cask flutter
   
   # Windows (using Chocolatey)
   choco install flutter
   ```

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

### Setup

1. **Clone the project**
   ```bash
   cd storyreader
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run on your platform**
   ```bash
   # Desktop (Windows/macOS/Linux)
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   
   # Android
   flutter run -d android
   
   # Or let Flutter choose
   flutter run
   ```

## Project Structure

```
lib/
├── business_logic/
│   ├── providers/          # State management (Provider pattern)
│   └── services/           # Business logic services
├── data/
│   ├── models/             # Data models
│   └── repositories/       # Data access layer
├── presentation/
│   ├── screens/            # UI screens
│   └── widgets/            # Reusable UI components
└── core/
    ├── constants/          # App constants
    ├── utils/              # Utility functions
    └── extensions/         # Dart extensions
```

## Core Components

### Story Reading
- **StoryProvider**: Manages story loading and navigation
- **DocumentParser**: Handles different file formats
- **AutoScroller**: Variable-speed auto-scrolling

### Grid Layout System
- **LayoutProvider**: Manages grid configurations
- **GridLayoutWidget**: Dynamic resizable grids
- **MediaProvider**: Handles media playlists

### Synchronization
- **SyncEngine**: Coordinates text-media synchronization
- **MetaTagParser**: Processes sync tags in story text

## Usage

### Basic Workflow

1. **Open a Story**: Click the folder icon to load a story file
2. **Create Layout**: Click + to create a new grid layout
3. **Add Media**: Drag and drop images/videos into grid panels
4. **Customize**: Adjust text size, colors, and layout
5. **Synchronize**: Add meta-tags in story text for synchronized playback
6. **Save**: Export layout or create portable packages

### Meta-tag Synchronization

Add sync markers in your story text:
```html
<sync-start id="scene1" grid="grid1" media="image1,video1">
This text will display while the specified media plays.
<sync-end id="scene1">
```

### Keyboard Shortcuts

- **Space**: Play/pause auto-scroll
- **Arrow Keys**: Navigate story
- **Ctrl/Cmd + O**: Open file
- **Ctrl/Cmd + S**: Save layout
- **F11**: Fullscreen mode

## Development Roadmap

- [x] Project setup and architecture
- [ ] Story text reader with auto-scroll
- [ ] Dynamic grid layout system
- [ ] Media handling and playlists
- [ ] Meta-tag synchronization
- [ ] Layout save/load functionality
- [ ] Multi-screen support
- [ ] Portable packaging system

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please create an issue in the repository.