# Story Reader

A comprehensive desktop application for immersive story reading with synchronized media display.

## 🚀 Features

### 📖 Core Reading Features
- **Multi-format Support**: DOCX, PDF, HTML, TXT files with robust parsing
- **Auto-scroll**: Variable speed scrolling (0.5x to 5x) with smooth animation
- **Advanced Typography**: Multiple font families, sizes (12-32px), and themes
- **Reading Progress**: Visual progress bar with percentage tracking
- **Keyboard Navigation**: Full keyboard support with shortcuts

### 🎬 Media Integration
- **Dynamic Media Grids**: Unlimited resizable and draggable media containers
- **Comprehensive Media Support**: Images (JPG, PNG, GIF, WebP) and Videos (MP4, AVI, MOV, WebM, MKV)
- **Advanced Playlist System**: Multiple media items per grid with auto-advance
- **Smart Media Controls**: Play/pause, previous/next, shuffle, zoom settings
- **Drag & Drop**: Direct file dropping onto grids or application

### 🎨 Customization & Themes
- **Multiple Themes**: Dark, Light, and Sepia modes
- **Font Customization**: Georgia, Times, Arial, Verdana, Consolas
- **Responsive Design**: Adapts to different screen sizes
- **Grid Resizing**: Custom height adjustment with visual feedback

### 🔍 Advanced Features
- **Full-text Search**: Real-time search with highlighting and navigation
- **Bookmarking System**: Save reading positions with preview text
- **Layout Management**: Save, load, and share custom layouts
- **Package System**: Export layouts with media files (.storypack format)
- **Settings Persistence**: All preferences automatically saved
- **Cross-platform**: Native performance on macOS and Windows

## Getting Started

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Start the application: `npm start`

### Usage
1. **Open a Story**: Click "Open Story" and select your story file
2. **Add Media**: Click "Add Media Grid" to create media containers
3. **Load Media**: Click "+" on any grid to add images/videos
4. **Customize**: Adjust font size, enable auto-scroll, set playback speed
5. **Navigate**: Use keyboard shortcuts or mouse controls

### Keyboard Shortcuts
- **Arrow Down/Page Down**: Scroll down
- **Arrow Up/Page Up**: Scroll up
- **Home**: Jump to beginning
- **End**: Jump to end
- **Ctrl/Cmd + F**: Toggle search
- **Ctrl/Cmd + B**: Add bookmark
- **Enter** (in search): Navigate to next result
- **Escape**: Close search/modals

## Development

### Tech Stack
- **Electron**: Cross-platform desktop framework
- **Node.js**: Backend file processing
- **HTML/CSS/JavaScript**: Frontend interface
- **Libraries**: officeparser, jsdom, electron-store

### File Structure
```
src/
├── main/
│   └── main.js          # Electron main process
└── renderer/
    ├── index.html       # Main UI
    └── app.js           # Application logic
```

### Building
- **Development**: `npm start`
- **Production**: `npm run build`

## Supported File Formats

### Story Files
- **.docx**: Microsoft Word documents
- **.pdf**: PDF documents
- **.html**: HTML files
- **.txt**: Plain text files

### Media Files
- **Images**: JPG, JPEG, PNG, GIF, WebP
- **Videos**: MP4, AVI, MOV, WebM, MKV

## 🎯 Advanced Usage

### Layout Management
- **Save Layouts**: Create reusable grid configurations
- **Load Layouts**: Restore saved configurations instantly
- **Package Layouts**: Export with media files for sharing
- **Import Packages**: Load .storypack files from others

### Media Management
- **Drag & Drop**: Drop files directly onto grids
- **Playlist Editing**: Reorder, remove, or add media items
- **Auto-advance**: Configure display time for images
- **Zoom Controls**: Fit or cover media display modes

### Search & Navigation
- **Real-time Search**: Find text as you type
- **Search Navigation**: Jump between results with Enter
- **Bookmarking**: Save reading positions with context
- **Progress Tracking**: Visual reading progress indicator

## 🔧 Technical Details

### Performance
- **Efficient Rendering**: Smooth scrolling and media playback
- **Memory Management**: Optimized for large documents
- **File Caching**: Smart caching for better performance
- **Cross-platform**: Native performance on all platforms

### Security
- **Local Storage**: All data stored locally
- **No Telemetry**: Complete privacy protection
- **Secure Parsing**: Safe document processing
- **Sandboxed Media**: Isolated media playback

## 📁 File Support

### Documents
- **.docx**: Full Microsoft Word support
- **.pdf**: Complete PDF text extraction
- **.html**: Rich HTML content parsing
- **.txt**: Plain text with encoding detection

### Media
- **Images**: JPG, JPEG, PNG, GIF, WebP
- **Videos**: MP4, AVI, MOV, WebM, MKV
- **Packages**: .storypack (custom format)

## 🚀 Future Enhancements
- **Meta Tag Synchronization**: Link media to story positions
- **Multiple Monitor Support**: Extend grids across displays
- **Reading Analytics**: Track reading patterns and speed
- **Cloud Sync**: Sync settings and bookmarks across devices
- **Gesture Support**: Touch and trackpad gesture controls
- **Voice Navigation**: Voice commands for hands-free reading

## 📄 License
MIT License - Feel free to modify and distribute