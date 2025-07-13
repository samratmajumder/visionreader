import 'package:flutter/material.dart';
import 'dart:async';

class AutoScrollController {
  final ScrollController _scrollController;
  Timer? _scrollTimer;
  double _currentSpeed = 1.0;
  bool _isScrolling = false;
  
  static const double _baseScrollIncrement = 1.0; // pixels per tick
  static const Duration _scrollInterval = Duration(milliseconds: 50);

  AutoScrollController(this._scrollController);

  bool get isScrolling => _isScrolling;
  double get currentSpeed => _currentSpeed;

  void startAutoScroll(double speed) {
    if (_isScrolling) {
      stopAutoScroll();
    }

    _currentSpeed = speed;
    _isScrolling = true;
    
    _scrollTimer = Timer.periodic(_scrollInterval, (timer) {
      if (!_scrollController.hasClients) {
        stopAutoScroll();
        return;
      }

      final currentPosition = _scrollController.position.pixels;
      final maxPosition = _scrollController.position.maxScrollExtent;
      
      // Check if we've reached the bottom
      if (currentPosition >= maxPosition) {
        stopAutoScroll();
        return;
      }

      final increment = _baseScrollIncrement * _currentSpeed;
      final newPosition = (currentPosition + increment).clamp(0.0, maxPosition);
      
      _scrollController.animateTo(
        newPosition,
        duration: _scrollInterval,
        curve: Curves.linear,
      );
    });
  }

  void stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _isScrolling = false;
  }

  void updateSpeed(double newSpeed) {
    _currentSpeed = newSpeed;
    
    // Restart scrolling with new speed if currently scrolling
    if (_isScrolling) {
      stopAutoScroll();
      startAutoScroll(newSpeed);
    }
  }

  void pauseResume() {
    if (_isScrolling) {
      stopAutoScroll();
    } else {
      startAutoScroll(_currentSpeed);
    }
  }

  void jumpToPosition(double position) {
    if (_scrollController.hasClients) {
      final clampedPosition = position.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(clampedPosition);
    }
  }

  void animateToPosition(double position, {Duration? duration}) {
    if (_scrollController.hasClients) {
      final clampedPosition = position.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clampedPosition,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Navigate by page (screen height)
  void nextPage() {
    if (_scrollController.hasClients) {
      final currentPosition = _scrollController.position.pixels;
      final viewportHeight = _scrollController.position.viewportDimension;
      final newPosition = currentPosition + viewportHeight * 0.8; // 80% overlap
      
      animateToPosition(newPosition);
    }
  }

  void previousPage() {
    if (_scrollController.hasClients) {
      final currentPosition = _scrollController.position.pixels;
      final viewportHeight = _scrollController.position.viewportDimension;
      final newPosition = currentPosition - viewportHeight * 0.8;
      
      animateToPosition(newPosition);
    }
  }

  // Get scroll progress as percentage
  double getScrollProgress() {
    if (!_scrollController.hasClients) return 0.0;
    
    final currentPosition = _scrollController.position.pixels;
    final maxPosition = _scrollController.position.maxScrollExtent;
    
    return maxPosition > 0 ? (currentPosition / maxPosition) : 0.0;
  }

  void dispose() {
    stopAutoScroll();
  }
}