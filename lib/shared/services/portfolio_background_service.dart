import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_snapshot.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import 'storage_service.dart';

// Shared preferences keys
const String _lastPortfolioValueKey = 'last_portfolio_value';
const String _lastUpdateTimeKey = 'last_update_time';
const String _songPricesKey = 'song_prices';
const String _portfolioItemsKey = 'portfolio_items';
const String _lastTrackUpdateKey = 'last_track_update';

/// Background service for portfolio updates
/// This service will simulate portfolio value changes while the app is closed
@pragma('vm:entry-point')
class PortfolioBackgroundService {
  static FlutterBackgroundService? _service;
  static bool _isInitialized = false;

  /// Initialize the service
  static Future<void> init() async {
    if (_isInitialized) return;

    _service = FlutterBackgroundService();

    // Configure the background service
    await _service!.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'portfolio_updates',
        initialNotificationTitle: 'Sound Market',
        initialNotificationContent: 'Monitoring portfolio performance',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    _isInitialized = true;
  }

  /// Start the background service
  static Future<bool> startService() async {
    if (!_isInitialized) await init();
    return await _service?.startService() ?? false;
  }

  /// Send data to the background service for use when the app is closed
  static void sendDataToBackground({
    required double portfolioValue,
    required List<PortfolioItem> portfolioItems,
    required List<Song> songs,
  }) {
    if (_service == null) return;

    try {
      // Create a map of song IDs to prices
      final songPrices = <String, double>{};
      for (final song in songs) {
        songPrices[song.id] = song.currentPrice;
      }

      // Convert portfolio items to a serializable format
      final portfolioItemsJson =
          portfolioItems.map((item) => item.toJson()).toList();

      // Send the data to the background service with explicit type casting
      _service!.invoke('update_data', {
        'portfolio_value': portfolioValue.toDouble(), // Ensure it's a double
        'update_time':
            DateTime.now().millisecondsSinceEpoch, // This is already an int
        'song_prices': songPrices,
        'portfolio_items': portfolioItemsJson,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending data to background service: $e');
      }
    }
  }
}

/// Background service entry point for Android
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // For debugging
  if (kDebugMode) {
    print('Starting portfolio background service');
  }

  // Create a storage service for saving snapshots
  final storageService = StorageService();

  // Initialize data from shared preferences
  final prefs = await SharedPreferences.getInstance();
  double lastPortfolioValue = prefs.getDouble(_lastPortfolioValueKey) ?? 0.0;
  int lastUpdateTime = prefs.getInt(_lastUpdateTimeKey) ?? 0;
  String? songPricesJson = prefs.getString(_songPricesKey);
  // Parse saved song prices
  Map<String, double> savedSongPrices = {};
  if (songPricesJson != null && songPricesJson.isNotEmpty) {
    try {
      final Map<String, dynamic> parsed = Map<String, dynamic>.from(
        // Note: In a real implementation, you'd use json.decode here
        // For now, we'll initialize empty and let the service populate it
        <String, dynamic>{},
      );
      savedSongPrices = parsed.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing saved song prices: $e');
      }
    }
  }

  // Set as foreground service for Android
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Listen for data updates from the main app
  service.on('update_data').listen((event) async {
    if (event == null) return;

    try {
      // Update values from the main app with proper type casting
      final portfolioValueData = event['portfolio_value'];
      if (portfolioValueData != null) {
        lastPortfolioValue =
            portfolioValueData is double
                ? portfolioValueData
                : (portfolioValueData as num).toDouble();
      }

      final updateTimeData = event['update_time'];
      if (updateTimeData != null) {
        lastUpdateTime =
            updateTimeData is int
                ? updateTimeData
                : (updateTimeData as num).toInt();
      }

      // Save song prices if provided
      final songPricesData = event['song_prices'];
      if (songPricesData != null && songPricesData is Map) {
        savedSongPrices = Map<String, double>.from(
          songPricesData.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ),
        );
        // Convert to JSON string for storage
        // Note: In a real implementation, you'd use json.encode here
        await prefs.setString(_songPricesKey, savedSongPrices.toString());
      }

      // Save values to shared preferences
      await prefs.setDouble(_lastPortfolioValueKey, lastPortfolioValue);
      await prefs.setInt(_lastUpdateTimeKey, lastUpdateTime);
      await prefs.setInt(
        _lastTrackUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing background service data: $e');
      }
    }
  });

  // Listen for stop request
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Update portfolio and individual track prices periodically
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    try {
      if (lastPortfolioValue > 0) {
        final now = DateTime.now();
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
        final minutesSinceLastUpdate = now.difference(lastUpdate).inMinutes;

        if (minutesSinceLastUpdate >= 5) {
          // Simulate price changes - usually we'd get this from an API,
          // but here we'll simulate based on time passed
          final random = Random();

          // Calculate a simulated new portfolio value with up to 3% change
          final maxChange = lastPortfolioValue * 0.03;
          final change = (random.nextDouble() * maxChange * 2) - maxChange;
          final newPortfolioValue = max(1.0, lastPortfolioValue + change);

          // Create a new portfolio snapshot
          final snapshot = PortfolioSnapshot(
            timestamp: now,
            value: newPortfolioValue,
          );

          // Save the snapshot to the database
          await storageService.savePortfolioSnapshot(snapshot);

          // Update the last portfolio value and update time
          lastPortfolioValue = newPortfolioValue;
          lastUpdateTime = now.millisecondsSinceEpoch;

          // Simulate individual track price changes
          final updatedSongPrices = _simulateTrackPriceChanges(
            savedSongPrices,
            random,
          );
          if (updatedSongPrices.isNotEmpty) {
            savedSongPrices = updatedSongPrices;
            // Save updated track prices
            await prefs.setString(_songPricesKey, savedSongPrices.toString());
          }

          // Save to shared preferences
          await prefs.setDouble(_lastPortfolioValueKey, lastPortfolioValue);
          await prefs.setInt(_lastUpdateTimeKey, lastUpdateTime);
          await prefs.setInt(_lastTrackUpdateKey, now.millisecondsSinceEpoch);

          // Update notification for Android
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Sound Market',
              content:
                  'Portfolio value: \$${newPortfolioValue.toStringAsFixed(2)}',
            );
          }

          if (kDebugMode) {
            print(
              'Background update: Portfolio value updated to \$${newPortfolioValue.toStringAsFixed(2)}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in background portfolio update: $e');
      }
    }
  });
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // For debugging
  if (kDebugMode) {
    print('iOS background service started');
  }

  // Get shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Create a storage service
  final storageService = StorageService();

  // Get values from shared preferences
  final lastPortfolioValue = prefs.getDouble(_lastPortfolioValueKey) ?? 0.0;
  final lastUpdateTime = prefs.getInt(_lastUpdateTimeKey) ?? 0;
  String? songPricesJson = prefs.getString(_songPricesKey);

  // Parse saved song prices
  Map<String, double> savedSongPrices = {};
  if (songPricesJson != null && songPricesJson.isNotEmpty) {
    try {
      // Note: In a real implementation, you'd use json.decode here
      // For now, we'll simulate with empty map
      savedSongPrices = <String, double>{};
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing saved song prices in iOS: $e');
      }
    }
  }

  // Simulate a portfolio update if needed
  final now = DateTime.now();
  final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
  final minutesSinceLastUpdate = now.difference(lastUpdate).inMinutes;

  if (minutesSinceLastUpdate >= 5 && lastPortfolioValue > 0) {
    try {
      // iOS has limited background execution time, so we just do a simple update
      final random = Random();
      final change = (random.nextDouble() * 0.06) - 0.03; // -3% to +3%
      final newPortfolioValue = lastPortfolioValue * (1 + change);

      // Create a new portfolio snapshot
      final snapshot = PortfolioSnapshot(
        timestamp: now,
        value: newPortfolioValue,
      );

      // Save the snapshot to the database
      await storageService.savePortfolioSnapshot(snapshot);

      // Simulate track price changes for iOS
      final randomGen = Random();
      final updatedSongPrices = _simulateTrackPriceChanges(
        savedSongPrices,
        randomGen,
      );
      if (updatedSongPrices.isNotEmpty) {
        await prefs.setString(_songPricesKey, updatedSongPrices.toString());
      }

      // Update shared preferences
      await prefs.setDouble(_lastPortfolioValueKey, newPortfolioValue);
      await prefs.setInt(_lastUpdateTimeKey, now.millisecondsSinceEpoch);
      await prefs.setInt(_lastTrackUpdateKey, now.millisecondsSinceEpoch);

      if (kDebugMode) {
        print(
          'iOS background update: Portfolio value updated to \$${newPortfolioValue.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in iOS background update: $e');
      }
    }
  }

  return true;
}

/// Helper function to simulate individual track price changes
Map<String, double> _simulateTrackPriceChanges(
  Map<String, double> currentPrices,
  Random random,
) {
  if (currentPrices.isEmpty) return currentPrices;

  final updatedPrices = <String, double>{};

  // Apply small random changes to each track price
  currentPrices.forEach((trackId, currentPrice) {
    // Calculate change factor: -2% to +2% with most changes being small
    double changeFactor = 1.0 + ((random.nextDouble() - 0.5) * 0.04);

    double newPrice = currentPrice * changeFactor;

    // Ensure price stays within reasonable bounds
    newPrice = newPrice.clamp(0.01, 15000.0);

    updatedPrices[trackId] = double.parse(newPrice.toStringAsFixed(4));
  });

  return updatedPrices;
}
