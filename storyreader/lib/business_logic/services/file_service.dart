import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../../data/models/story_document.dart';
import '../../data/models/grid_layout.dart';
import '../../data/models/media_item.dart';

class FileService {
  static const String _storiesFolder = 'stories';
  static const String _layoutsFolder = 'layouts';
  static const String _mediaFolder = 'media';
  static const String _packagesFolder = 'packages';

  /// Get application documents directory
  Future<Directory> getAppDocumentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final storyReaderDir = Directory(path.join(appDocDir.path, 'StoryReader'));
    
    if (!await storyReaderDir.exists()) {
      await storyReaderDir.create(recursive: true);
    }
    
    return storyReaderDir;
  }

  /// Get or create subdirectory
  Future<Directory> getSubDirectory(String subPath) async {
    final appDir = await getAppDocumentsDirectory();
    final subDir = Directory(path.join(appDir.path, subPath));
    
    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }
    
    return subDir;
  }

  /// Save story document
  Future<File> saveStoryDocument(StoryDocument document) async {
    final storiesDir = await getSubDirectory(_storiesFolder);
    final fileName = '${document.id}.json';
    final file = File(path.join(storiesDir.path, fileName));
    
    final jsonContent = json.encode(document.toJson());
    await file.writeAsString(jsonContent);
    
    return file;
  }

  /// Load story document
  Future<StoryDocument?> loadStoryDocument(String documentId) async {
    try {
      final storiesDir = await getSubDirectory(_storiesFolder);
      final fileName = '$documentId.json';
      final file = File(path.join(storiesDir.path, fileName));
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonContent = await file.readAsString();
      final jsonData = json.decode(jsonContent) as Map<String, dynamic>;
      
      return StoryDocument.fromJson(jsonData);
    } catch (e) {
      print('Error loading story document: $e');
      return null;
    }
  }

  /// Get all saved story documents
  Future<List<StoryDocument>> getAllStoryDocuments() async {
    final documents = <StoryDocument>[];
    
    try {
      final storiesDir = await getSubDirectory(_storiesFolder);
      final files = storiesDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        try {
          final jsonContent = await file.readAsString();
          final jsonData = json.decode(jsonContent) as Map<String, dynamic>;
          final document = StoryDocument.fromJson(jsonData);
          documents.add(document);
        } catch (e) {
          print('Error loading document ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error getting story documents: $e');
    }
    
    // Sort by last modified date (newest first)
    documents.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    return documents;
  }

  /// Delete story document
  Future<bool> deleteStoryDocument(String documentId) async {
    try {
      final storiesDir = await getSubDirectory(_storiesFolder);
      final fileName = '$documentId.json';
      final file = File(path.join(storiesDir.path, fileName));
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting story document: $e');
      return false;
    }
  }

  /// Save grid layout
  Future<File> saveGridLayout(GridLayout layout) async {
    final layoutsDir = await getSubDirectory(_layoutsFolder);
    final fileName = '${layout.id}.json';
    final file = File(path.join(layoutsDir.path, fileName));
    
    final jsonContent = json.encode(layout.toJson());
    await file.writeAsString(jsonContent);
    
    return file;
  }

  /// Load grid layout
  Future<GridLayout?> loadGridLayout(String layoutId) async {
    try {
      final layoutsDir = await getSubDirectory(_layoutsFolder);
      final fileName = '$layoutId.json';
      final file = File(path.join(layoutsDir.path, fileName));
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonContent = await file.readAsString();
      final jsonData = json.decode(jsonContent) as Map<String, dynamic>;
      
      return GridLayout.fromJson(jsonData);
    } catch (e) {
      print('Error loading grid layout: $e');
      return null;
    }
  }

  /// Get all saved grid layouts
  Future<List<GridLayout>> getAllGridLayouts() async {
    final layouts = <GridLayout>[];
    
    try {
      final layoutsDir = await getSubDirectory(_layoutsFolder);
      final files = layoutsDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        try {
          final jsonContent = await file.readAsString();
          final jsonData = json.decode(jsonContent) as Map<String, dynamic>;
          final layout = GridLayout.fromJson(jsonData);
          layouts.add(layout);
        } catch (e) {
          print('Error loading layout ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error getting grid layouts: $e');
    }
    
    // Sort by last modified date (newest first)
    layouts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    return layouts;
  }

  /// Delete grid layout
  Future<bool> deleteGridLayout(String layoutId) async {
    try {
      final layoutsDir = await getSubDirectory(_layoutsFolder);
      final fileName = '$layoutId.json';
      final file = File(path.join(layoutsDir.path, fileName));
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting grid layout: $e');
      return false;
    }
  }

  /// Copy media file to app directory
  Future<File> copyMediaFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }
    
    final mediaDir = await getSubDirectory(_mediaFolder);
    final fileName = path.basename(sourcePath);
    final destinationPath = path.join(mediaDir.path, fileName);
    
    // If file already exists, create a unique name
    var finalPath = destinationPath;
    var counter = 1;
    while (await File(finalPath).exists()) {
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final extension = path.extension(fileName);
      finalPath = path.join(mediaDir.path, '${nameWithoutExt}_$counter$extension');
      counter++;
    }
    
    return await sourceFile.copy(finalPath);
  }

  /// Get media file info
  Future<Map<String, dynamic>> getMediaFileInfo(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final stat = await file.stat();
    final extension = path.extension(filePath).toLowerCase();
    
    MediaType? mediaType;
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      mediaType = MediaType.image;
    } else if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm'].contains(extension)) {
      mediaType = MediaType.video;
    }
    
    return {
      'fileName': path.basename(filePath),
      'filePath': filePath,
      'fileSize': stat.size,
      'lastModified': stat.modified,
      'mediaType': mediaType,
      'extension': extension,
    };
  }

  /// Create portable story package
  Future<File> createStoryPackage({
    required StoryDocument story,
    required GridLayout layout,
    required List<MediaItem> mediaItems,
    String? packageName,
  }) async {
    final packagesDir = await getSubDirectory(_packagesFolder);
    final finalPackageName = packageName ?? '${story.title}_${DateTime.now().millisecondsSinceEpoch}';
    final packageFile = File(path.join(packagesDir.path, '$finalPackageName.srp')); // StoryReader Package
    
    final archive = Archive();
    
    try {
      // Add story document
      final storyJson = json.encode(story.toJson());
      archive.addFile(ArchiveFile('story.json', storyJson.length, storyJson.codeUnits));
      
      // Add layout
      final layoutJson = json.encode(layout.toJson());
      archive.addFile(ArchiveFile('layout.json', layoutJson.length, layoutJson.codeUnits));
      
      // Add media files
      final mediaManifest = <Map<String, dynamic>>[];
      for (final mediaItem in mediaItems) {
        final mediaFile = File(mediaItem.filePath);
        if (await mediaFile.exists()) {
          final mediaBytes = await mediaFile.readAsBytes();
          final mediaFileName = 'media/${path.basename(mediaItem.filePath)}';
          
          archive.addFile(ArchiveFile(mediaFileName, mediaBytes.length, mediaBytes));
          
          // Add to manifest
          mediaManifest.add({
            'id': mediaItem.id,
            'originalPath': mediaItem.filePath,
            'packagePath': mediaFileName,
            'fileName': mediaItem.fileName,
            'type': mediaItem.type.name,
            'metadata': mediaItem.metadata,
          });
        }
      }
      
      // Add media manifest
      final manifestJson = json.encode({'mediaItems': mediaManifest});
      archive.addFile(ArchiveFile('manifest.json', manifestJson.length, manifestJson.codeUnits));
      
      // Add package info
      final packageInfo = {
        'name': finalPackageName,
        'createdAt': DateTime.now().toIso8601String(),
        'storyTitle': story.title,
        'layoutName': layout.name,
        'mediaCount': mediaItems.length,
        'version': '1.0',
      };
      final packageInfoJson = json.encode(packageInfo);
      archive.addFile(ArchiveFile('package.json', packageInfoJson.length, packageInfoJson.codeUnits));
      
      // Compress and save
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await packageFile.writeAsBytes(zipData);
      }
      
      return packageFile;
    } catch (e) {
      throw FileSystemException('Failed to create package: $e');
    }
  }

  /// Extract story package
  Future<StoryPackageContents> extractStoryPackage(String packagePath) async {
    final packageFile = File(packagePath);
    if (!await packageFile.exists()) {
      throw FileSystemException('Package file not found', packagePath);
    }
    
    try {
      final packageBytes = await packageFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(packageBytes);
      
      // Extract package info
      final packageInfoFile = archive.files.firstWhere((file) => file.name == 'package.json');
      final packageInfo = json.decode(String.fromCharCodes(packageInfoFile.content as List<int>)) as Map<String, dynamic>;
      
      // Extract story
      final storyFile = archive.files.firstWhere((file) => file.name == 'story.json');
      final storyData = json.decode(String.fromCharCodes(storyFile.content as List<int>)) as Map<String, dynamic>;
      final story = StoryDocument.fromJson(storyData);
      
      // Extract layout
      final layoutFile = archive.files.firstWhere((file) => file.name == 'layout.json');
      final layoutData = json.decode(String.fromCharCodes(layoutFile.content as List<int>)) as Map<String, dynamic>;
      final layout = GridLayout.fromJson(layoutData);
      
      // Extract media manifest
      final manifestFile = archive.files.firstWhere((file) => file.name == 'manifest.json');
      final manifestData = json.decode(String.fromCharCodes(manifestFile.content as List<int>)) as Map<String, dynamic>;
      final mediaManifest = manifestData['mediaItems'] as List;
      
      // Extract media files to temporary directory
      final tempDir = await getSubDirectory('temp/${DateTime.now().millisecondsSinceEpoch}');
      final mediaItems = <MediaItem>[];
      
      for (final mediaEntry in mediaManifest) {
        final packagePath = mediaEntry['packagePath'] as String;
        final mediaArchiveFile = archive.files.firstWhere((file) => file.name == packagePath);
        
        final tempMediaFile = File(path.join(tempDir.path, path.basename(packagePath)));
        await tempMediaFile.writeAsBytes(mediaArchiveFile.content as List<int>);
        
        final mediaItem = MediaItem(
          id: mediaEntry['id'],
          filePath: tempMediaFile.path,
          fileName: mediaEntry['fileName'],
          type: MediaType.values.firstWhere((type) => type.name == mediaEntry['type']),
          metadata: Map<String, dynamic>.from(mediaEntry['metadata'] ?? {}),
          lastModified: DateTime.now(),
        );
        
        mediaItems.add(mediaItem);
      }
      
      return StoryPackageContents(
        packageInfo: packageInfo,
        story: story,
        layout: layout,
        mediaItems: mediaItems,
        tempDirectory: tempDir,
      );
    } catch (e) {
      throw FileSystemException('Failed to extract package: $e');
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final tempDir = Directory(path.join(appDir.path, 'temp'));
      
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Check available disk space
  Future<int> getAvailableDiskSpace() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final stat = await appDir.stat();
      // This is a simplified implementation
      // In a real app, you might want to use platform-specific methods
      return 1024 * 1024 * 1024; // Return 1GB as placeholder
    } catch (e) {
      return 0;
    }
  }
}

/// Contents of an extracted story package
class StoryPackageContents {
  final Map<String, dynamic> packageInfo;
  final StoryDocument story;
  final GridLayout layout;
  final List<MediaItem> mediaItems;
  final Directory tempDirectory;

  const StoryPackageContents({
    required this.packageInfo,
    required this.story,
    required this.layout,
    required this.mediaItems,
    required this.tempDirectory,
  });
}