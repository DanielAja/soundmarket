import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';
import '../../core/config/environment_config.dart';

/// Analytics tracking service
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Flag to enable/disable analytics
  bool _enabled = AppConfig.enableAnalytics;

  // Queue of events to be sent
  final List<Map<String, dynamic>> _eventQueue = [];

  // Timer for batch sending
  Timer? _batchTimer;

  // Initialize analytics service
  Future<void> initialize() async {
    // In a real app, you would initialize your analytics SDK here
    debugPrint('Analytics service initialized');

    // Start batch timer if enabled
    if (_enabled) {
      _startBatchTimer();
    }
  }

  // Enable or disable analytics
  void setEnabled(bool enabled) {
    _enabled = enabled;

    if (_enabled) {
      _startBatchTimer();
    } else {
      _batchTimer?.cancel();
      _batchTimer = null;
    }
  }

  // Track screen view
  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    if (!_enabled) return;

    final event = {
      'event_type': 'screen_view',
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track user action
  void trackAction(String action, {Map<String, dynamic>? parameters}) {
    if (!_enabled) return;

    final event = {
      'event_type': 'action',
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track error
  void trackError(
    String errorType,
    String errorMessage, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_enabled) return;

    final event = {
      'event_type': 'error',
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track song view
  void trackSongView(
    String songId,
    String songName,
    String artist, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_enabled) return;

    final event = {
      'event_type': 'song_view',
      'song_id': songId,
      'song_name': songName,
      'artist': artist,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track song purchase
  void trackSongPurchase(
    String songId,
    String songName,
    String artist,
    int quantity,
    double price, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_enabled) return;

    final event = {
      'event_type': 'song_purchase',
      'song_id': songId,
      'song_name': songName,
      'artist': artist,
      'quantity': quantity,
      'price': price,
      'total_value': quantity * price,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track song sale
  void trackSongSale(
    String songId,
    String songName,
    String artist,
    int quantity,
    double price, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_enabled) return;

    final event = {
      'event_type': 'song_sale',
      'song_id': songId,
      'song_name': songName,
      'artist': artist,
      'quantity': quantity,
      'price': price,
      'total_value': quantity * price,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Track search
  void trackSearch(
    String query,
    int resultCount, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_enabled) return;

    final event = {
      'event_type': 'search',
      'query': query,
      'result_count': resultCount,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };

    _logEvent(event);
  }

  // Log event
  void _logEvent(Map<String, dynamic> event) {
    // Add environment info
    event['environment'] =
        EnvironmentConfig.environment.toString().split('.').last;

    // Add to queue
    _eventQueue.add(event);

    // Log in debug mode
    if (kDebugMode) {
      debugPrint('Analytics event: $event');
    }

    // Send immediately if queue is getting large
    if (_eventQueue.length >= 10) {
      _sendEvents();
    }
  }

  // Start batch timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_eventQueue.isNotEmpty) {
        _sendEvents();
      }
    });
  }

  // Send events to analytics service
  Future<void> _sendEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      // In a real app, you would send events to your analytics service here
      final events = List<Map<String, dynamic>>.from(_eventQueue);
      _eventQueue.clear();

      // Simulate sending events
      await Future.delayed(const Duration(milliseconds: 100));

      if (kDebugMode) {
        debugPrint('Sent ${events.length} events to analytics service');
      }
    } catch (e) {
      debugPrint('Error sending analytics events: $e');
    }
  }

  // Dispose
  void dispose() {
    _batchTimer?.cancel();
    _sendEvents();
  }
}
