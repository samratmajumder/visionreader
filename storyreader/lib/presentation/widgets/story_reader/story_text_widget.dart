import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/providers/settings_provider.dart';
import '../../../business_logic/providers/story_provider.dart';
import 'auto_scroll_controller.dart';

class StoryTextWidget extends StatefulWidget {
  const StoryTextWidget({super.key});

  @override
  State<StoryTextWidget> createState() => _StoryTextWidgetState();
}

class _StoryTextWidgetState extends State<StoryTextWidget> {
  late ScrollController _scrollController;
  late AutoScrollController _autoScrollController;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoScrollController = AutoScrollController(_scrollController);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _isAutoScrolling = settings.isAutoScrollEnabled;
      if (_isAutoScrolling) {
        _autoScrollController.startAutoScroll(settings.autoScrollSpeed);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, StoryProvider>(
      builder: (context, settings, story, child) {
        return Column(
          children: [
            _buildControlBar(settings, story),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: settings.backgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: story.hasStory
                    ? _buildStoryContent(settings, story)
                    : _buildWelcomeMessage(settings),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlBar(SettingsProvider settings, StoryProvider story) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        children: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoScroll,
            tooltip: _isAutoScrolling ? 'Pause Auto-scroll' : 'Start Auto-scroll',
          ),
          
          // Speed control
          if (_isAutoScrolling) ...[
            const SizedBox(width: 8),
            const Text('Speed:', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              child: Slider(
                value: settings.autoScrollSpeed,
                min: 0.1,
                max: 5.0,
                divisions: 49,
                onChanged: (value) {
                  settings.setAutoScrollSpeed(value);
                  _autoScrollController.updateSpeed(value);
                },
              ),
            ),
            Text(
              '${settings.autoScrollSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          
          const Spacer(),
          
          // Progress indicator
          if (story.hasStory) ...[
            Text(
              '${story.currentPosition + 1} / ${story.currentStory!.content.length}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
          
          // Reading time estimate
          if (story.hasStory) ...[
            Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _formatDuration(story.currentStory!.estimatedReadingTime),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryContent(SettingsProvider settings, StoryProvider story) {
    return GestureDetector(
      onTap: () {
        if (_isAutoScrolling) {
          _toggleAutoScroll();
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          story.currentStory!.content,
          style: TextStyle(
            fontSize: settings.fontSize,
            color: settings.textColor,
            fontFamily: settings.fontFamily,
            height: 1.6,
            letterSpacing: 0.3,
          ),
          onSelectionChanged: (selection, cause) {
            if (selection.isValid) {
              story.setPosition(selection.start);
            }
          },
        ),
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
            color: settings.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to StoryReader',
            style: TextStyle(
              fontSize: settings.fontSize * 1.8,
              color: settings.textColor,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Open a story file to begin your immersive reading experience',
            style: TextStyle(
              fontSize: settings.fontSize * 1.1,
              color: settings.textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Story File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });

    final settings = context.read<SettingsProvider>();
    settings.setAutoScrollEnabled(_isAutoScrolling);

    if (_isAutoScrolling) {
      _autoScrollController.startAutoScroll(settings.autoScrollSpeed);
    } else {
      _autoScrollController.stopAutoScroll();
    }
  }

  void _openFile(BuildContext context) {
    // TODO: Implement file picker integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker integration coming soon')),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}