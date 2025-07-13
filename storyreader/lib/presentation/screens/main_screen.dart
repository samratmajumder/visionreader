import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../business_logic/providers/settings_provider.dart';
import '../../business_logic/providers/story_provider.dart';
import '../../business_logic/providers/layout_provider.dart';
import '../../business_logic/providers/media_provider.dart';
import '../../business_logic/services/document_parser_service.dart';
import '../../business_logic/services/file_service.dart';
import '../widgets/story_reader/story_text_widget.dart';
import '../widgets/story_reader/text_customization_panel.dart';
import '../widgets/grid_layout/dynamic_grid_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DocumentParserService _documentParser = DocumentParserService();
  final FileService _fileService = FileService();
  bool _showTextCustomization = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initialize();
      _loadRecentContent();
    });
  }

  @override
  void dispose() {
    _documentParser.dispose();
    super.dispose();
  }

  Future<void> _loadRecentContent() async {
    // Load recent stories and layouts
    final layouts = await _fileService.getAllGridLayouts();
    if (layouts.isNotEmpty) {
      context.read<LayoutProvider>().loadLayout(layouts.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMainContent(),
                if (_showTextCustomization)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: TextCustomizationPanel(
                      isVisible: _showTextCustomization,
                      onClose: () => setState(() => _showTextCustomization = false),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<StoryProvider>(
        builder: (context, story, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('StoryReader', style: TextStyle(fontSize: 18)),
              if (story.hasStory)
                Text(
                  story.currentStory!.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          );
        },
      ),
      actions: [
        // Text customization toggle
        IconButton(
          icon: Icon(_showTextCustomization ? Icons.format_paint : Icons.format_paint_outlined),
          onPressed: () => setState(() => _showTextCustomization = !_showTextCustomization),
          tooltip: 'Text Customization',
        ),
        
        // Layout management
        PopupMenuButton<String>(
          icon: const Icon(Icons.dashboard),
          tooltip: 'Layout Management',
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_layout',
              child: Row(
                children: [Icon(Icons.add), SizedBox(width: 8), Text('New Layout')],
              ),
            ),
            const PopupMenuItem(
              value: 'save_layout',
              child: Row(
                children: [Icon(Icons.save), SizedBox(width: 8), Text('Save Layout')],
              ),
            ),
            const PopupMenuItem(
              value: 'load_layout',
              child: Row(
                children: [Icon(Icons.folder_open), SizedBox(width: 8), Text('Load Layout')],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'export_package',
              child: Row(
                children: [Icon(Icons.archive), SizedBox(width: 8), Text('Export Package')],
              ),
            ),
            const PopupMenuItem(
              value: 'import_package',
              child: Row(
                children: [Icon(Icons.unarchive), SizedBox(width: 8), Text('Import Package')],
              ),
            ),
          ],
          onSelected: (value) => _handleLayoutAction(value),
        ),
        
        // File operations
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: _openStoryFile,
          tooltip: 'Open Story',
        ),
        
        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettings,
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Consumer4<SettingsProvider, StoryProvider, LayoutProvider, MediaProvider>(
      builder: (context, settings, story, layout, media, child) {
        return Container(
          color: settings.backgroundColor,
          child: Row(
            children: [
              // Story reading panel
              Expanded(
                flex: _showTextCustomization ? 2 : 3,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  child: story.hasStory 
                      ? const StoryTextWidget()
                      : _buildWelcomeMessage(settings),
                ),
              ),
              
              // Media grids panel
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  child: const DynamicGridWidget(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons() {
    return Consumer<LayoutProvider>(
      builder: (context, layout, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (layout.hasLayout)
              FloatingActionButton(
                heroTag: "add_panel",
                mini: true,
                onPressed: _addGridPanel,
                tooltip: 'Add Panel',
                child: const Icon(Icons.add_box),
              ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "new_layout",
              onPressed: _createNewLayout,
              tooltip: 'New Layout',
              child: const Icon(Icons.dashboard),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoryReader(SettingsProvider settings, StoryProvider story) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.currentStory?.title ?? 'Untitled',
            style: TextStyle(
              fontSize: settings.fontSize * 1.2,
              fontWeight: FontWeight.bold,
              color: settings.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                story.currentStory?.content ?? '',
                style: TextStyle(
                  fontSize: settings.fontSize,
                  color: settings.textColor,
                  fontFamily: settings.fontFamily,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(SettingsProvider settings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: settings.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to StoryReader',
            style: TextStyle(
              fontSize: settings.fontSize * 1.5,
              color: settings.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a story file to begin reading',
            style: TextStyle(
              fontSize: settings.fontSize,
              color: settings.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrids(LayoutProvider layout, MediaProvider media) {
    if (layout.currentLayout!.panels.isEmpty) {
      return _buildGridPlaceholder();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: layout.currentLayout!.panels.length,
      itemBuilder: (context, index) {
        final panel = layout.currentLayout!.panels[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: panel.hasMedia
              ? _buildMediaPanel(panel, media)
              : _buildEmptyPanel(panel),
        );
      },
    );
  }

  Widget _buildMediaPanel(GridPanel panel, MediaProvider media) {
    final currentMedia = media.getCurrentMedia(panel.id);
    
    return Stack(
      children: [
        Center(
          child: currentMedia != null
              ? Text(
                  currentMedia.fileName,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                )
              : const Text('No media'),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Text(
            '${media.getCurrentIndex(panel.id) + 1}/${panel.playlist.length}',
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  // Action handlers
  Future<void> _openStoryFile() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentParserService.getSupportedExtensions(),
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          final document = await _documentParser.parseDocument(filePath);
          context.read<StoryProvider>().loadStoryDocument(document);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded: ${document.title}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading story: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleLayoutAction(String action) {
    switch (action) {
      case 'new_layout':
        _createNewLayout();
        break;
      case 'save_layout':
        _saveCurrentLayout();
        break;
      case 'load_layout':
        _showLoadLayoutDialog();
        break;
      case 'export_package':
        _exportStoryPackage();
        break;
      case 'import_package':
        _importStoryPackage();
        break;
    }
  }

  void _createNewLayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Layout Name',
                hintText: 'Enter a name for your layout',
              ),
              onSubmitted: (name) {
                Navigator.of(context).pop();
                if (name.isNotEmpty) {
                  context.read<LayoutProvider>().createNewLayout(name);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LayoutProvider>().createNewLayout('New Layout ${DateTime.now().millisecondsSinceEpoch}');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentLayout() async {
    final layout = context.read<LayoutProvider>().currentLayout;
    if (layout != null) {
      try {
        await _fileService.saveGridLayout(layout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Layout "${layout.name}" saved')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving layout: $e')),
        );
      }
    }
  }

  Future<void> _showLoadLayoutDialog() async {
    try {
      final layouts = await _fileService.getAllGridLayouts();
      
      if (!mounted) return;
      
      if (layouts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved layouts found')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Load Layout'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: layouts.length,
              itemBuilder: (context, index) {
                final layout = layouts[index];
                return ListTile(
                  title: Text(layout.name),
                  subtitle: Text('${layout.panels.length} panels • ${layout.lastModified.toString().split('.')[0]}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<LayoutProvider>().loadLayout(layout);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded layout: ${layout.name}')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading layouts: $e')),
      );
    }
  }

  void _exportStoryPackage() {
    // TODO: Implement story package export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export package feature coming soon')),
    );
  }

  void _importStoryPackage() {
    // TODO: Implement story package import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import package feature coming soon')),
    );
  }

  void _addGridPanel() {
    // This will be handled by the DynamicGridWidget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter edit mode in the grid to add panels')),
    );
  }

  void _showSettings() {
    // TODO: Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon')),
    );
  }
}