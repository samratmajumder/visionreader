import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../../data/models/story_document.dart';
import 'sync_service.dart';

class DocumentParserService {
  final SyncService _syncService = SyncService();

  /// Parse a document file and return a StoryDocument
  Future<StoryDocument> parseDocument(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw DocumentParseException('File not found: $filePath');
    }

    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final lastModified = await file.lastModified();

    String content;
    String title = _extractTitleFromFileName(fileName);

    try {
      switch (extension) {
        case 'txt':
          content = await _parsePlainText(file);
          break;
        case 'html':
        case 'htm':
          final result = await _parseHtml(file);
          content = result.content;
          title = result.title.isNotEmpty ? result.title : title;
          break;
        case 'docx':
          content = await _parseDocx(file);
          break;
        case 'pdf':
          content = await _parsePdf(file);
          break;
        default:
          throw DocumentParseException('Unsupported file format: $extension');
      }

      // Parse sync markers from content
      final syncMarkers = _syncService.parseStoryContent(content);
      
      // Create clean content for display (without sync tags)
      final cleanContent = _syncService.createCleanContent(content);

      // Validate sync markers
      final validationErrors = _syncService.validateSyncMarkers(content);
      if (validationErrors.isNotEmpty) {
        print('Warning: Sync validation errors found:');
        for (final error in validationErrors) {
          print('  - ${error.message}');
        }
      }

      final document = StoryDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: filePath,
        fileType: extension,
        content: cleanContent,
        syncMarkers: syncMarkers,
        lastModified: lastModified,
        metadata: {
          'originalLength': content.length,
          'cleanLength': cleanContent.length,
          'syncMarkersCount': syncMarkers.length,
          'hasValidationErrors': validationErrors.isNotEmpty,
          'validationErrors': validationErrors.map((e) => e.message).toList(),
        },
      );

      return document;
    } catch (e) {
      throw DocumentParseException('Failed to parse document: $e');
    }
  }

  /// Parse plain text file
  Future<String> _parsePlainText(File file) async {
    return await file.readAsString();
  }

  /// Parse HTML file
  Future<HtmlParseResult> _parseHtml(File file) async {
    final htmlContent = await file.readAsString();
    final document = html_parser.parse(htmlContent);
    
    // Extract title
    String title = '';
    final titleElement = document.querySelector('title');
    if (titleElement != null) {
      title = titleElement.text.trim();
    }

    // Extract body content
    String content = '';
    final bodyElement = document.querySelector('body');
    if (bodyElement != null) {
      content = _extractTextFromHtml(bodyElement);
    } else {
      // Fallback to entire document if no body tag
      content = _extractTextFromHtml(document);
    }

    return HtmlParseResult(content: content, title: title);
  }

  /// Extract text content from HTML element, preserving sync tags
  String _extractTextFromHtml(html_dom.Element element) {
    final buffer = StringBuffer();
    
    for (final node in element.nodes) {
      if (node.nodeType == html_dom.Node.TEXT_NODE) {
        buffer.write(node.text);
      } else if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
        final elem = node as html_dom.Element;
        
        // Preserve sync tags
        if (elem.localName == 'sync-start' || elem.localName == 'sync-end') {
          buffer.write('<${elem.localName}');
          elem.attributes.forEach((key, value) {
            buffer.write(' $key="$value"');
          });
          buffer.write('>');
          if (elem.hasContent()) {
            buffer.write(_extractTextFromHtml(elem));
          }
          buffer.write('</${elem.localName}>');
        } else {
          // Add appropriate spacing for block elements
          if (_isBlockElement(elem.localName)) {
            buffer.write('\n');
          }
          
          buffer.write(_extractTextFromHtml(elem));
          
          if (_isBlockElement(elem.localName)) {
            buffer.write('\n');
          }
        }
      }
    }
    
    return buffer.toString();
  }

  /// Check if HTML element is a block element
  bool _isBlockElement(String? tagName) {
    const blockElements = {
      'div', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'blockquote', 'pre', 'ul', 'ol', 'li', 'section',
      'article', 'header', 'footer', 'nav', 'aside'
    };
    return blockElements.contains(tagName?.toLowerCase());
  }

  /// Parse DOCX file (placeholder implementation)
  Future<String> _parseDocx(File file) async {
    // TODO: Implement actual DOCX parsing using docx_to_text package
    // For now, return a placeholder
    throw DocumentParseException('DOCX parsing not yet implemented. Please convert to TXT or HTML format.');
  }

  /// Parse PDF file (placeholder implementation)
  Future<String> _parsePdf(File file) async {
    // TODO: Implement actual PDF parsing using pdf package
    // For now, return a placeholder
    throw DocumentParseException('PDF parsing not yet implemented. Please convert to TXT or HTML format.');
  }

  /// Extract title from filename
  String _extractTitleFromFileName(String fileName) {
    final nameWithoutExtension = fileName.split('.').first;
    
    // Replace underscores and hyphens with spaces
    String title = nameWithoutExtension.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Capitalize words
    title = title.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return title;
  }

  /// Get supported file extensions
  static List<String> getSupportedExtensions() {
    return ['txt', 'html', 'htm', 'docx', 'pdf'];
  }

  /// Check if file extension is supported
  static bool isSupported(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return getSupportedExtensions().contains(extension);
  }

  /// Get file type description
  static String getFileTypeDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'txt':
        return 'Plain Text';
      case 'html':
      case 'htm':
        return 'HTML Document';
      case 'docx':
        return 'Word Document';
      case 'pdf':
        return 'PDF Document';
      default:
        return 'Unknown Format';
    }
  }

  /// Estimate reading time for content
  static Duration estimateReadingTime(String content, {int wordsPerMinute = 200}) {
    final wordCount = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return Duration(minutes: minutes);
  }

  /// Get document statistics
  static Map<String, dynamic> getDocumentStatistics(String content) {
    final words = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final sentences = content.split(RegExp(r'[.!?]+\s*')).where((s) => s.trim().isNotEmpty).length;
    final paragraphs = content.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
    
    return {
      'characterCount': content.length,
      'wordCount': words.length,
      'sentenceCount': sentences,
      'paragraphCount': paragraphs,
      'averageWordsPerSentence': sentences > 0 ? (words.length / sentences).round() : 0,
      'averageSentencesPerParagraph': paragraphs > 0 ? (sentences / paragraphs).round() : 0,
      'estimatedReadingTime': estimateReadingTime(content),
    };
  }

  void dispose() {
    _syncService.dispose();
  }
}

/// Result of HTML parsing
class HtmlParseResult {
  final String content;
  final String title;

  const HtmlParseResult({
    required this.content,
    required this.title,
  });
}

/// Exception thrown during document parsing
class DocumentParseException implements Exception {
  final String message;
  
  const DocumentParseException(this.message);
  
  @override
  String toString() => 'DocumentParseException: $message';
}