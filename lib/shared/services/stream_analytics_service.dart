import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class StreamAnalyticsService {
  static const String _streamHistoryKey = 'stream_analytics_history';
  static const Duration _analyticsWindow = Duration(hours: 24);
  static const int _maxHistoryEntries = 1000;

  final Map<String, List<StreamDataPoint>> _streamHistory = {};
  final Map<String, double> _popularityVelocity = {};

  static final StreamAnalyticsService _instance =
      StreamAnalyticsService._internal();
  factory StreamAnalyticsService() => _instance;
  StreamAnalyticsService._internal();

  Future<void> initialize() async {
    await _loadStreamHistory();
  }

  Future<void> _loadStreamHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_streamHistoryKey);

      if (historyJson != null) {
        final historyData = jsonDecode(historyJson) as Map<String, dynamic>;
        for (final entry in historyData.entries) {
          final songId = entry.key;
          final dataPoints =
              (entry.value as List<dynamic>)
                  .map((point) => StreamDataPoint.fromJson(point))
                  .toList();
          _streamHistory[songId] = dataPoints;
        }
      }
    } catch (e) {
      // Log error but continue
    }
  }

  Future<void> _saveStreamHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> historyData = {};
      for (final entry in _streamHistory.entries) {
        historyData[entry.key] =
            entry.value.map((point) => point.toJson()).toList();
      }
      await prefs.setString(_streamHistoryKey, jsonEncode(historyData));
    } catch (e) {
      // Log error but continue
    }
  }

  void recordStreamData(Song song) {
    final dataPoint = StreamDataPoint(
      timestamp: DateTime.now(),
      totalStreams: song.totalStreams,
      dailyStreams: song.dailyStreams,
      weeklyStreams: song.weeklyStreams,
      monthlyStreams: song.monthlyStreams,
      yearlyStreams: song.yearlyStreams,
      price: song.currentPrice,
    );

    if (!_streamHistory.containsKey(song.id)) {
      _streamHistory[song.id] = [];
    }

    _streamHistory[song.id]!.add(dataPoint);

    _cleanupOldData(song.id);
    _calculatePopularityVelocity(song.id);

    _saveStreamHistory();
  }

  void _cleanupOldData(String songId) {
    final history = _streamHistory[songId];
    if (history == null) return;

    final cutoffTime = DateTime.now().subtract(
      _analyticsWindow * 7,
    ); // Keep 7 days

    // Remove old entries
    history.removeWhere((point) => point.timestamp.isBefore(cutoffTime));

    // Limit total entries
    if (history.length > _maxHistoryEntries) {
      final excess = history.length - _maxHistoryEntries;
      history.removeRange(0, excess);
    }
  }

  void _calculatePopularityVelocity(String songId) {
    final history = _streamHistory[songId];
    if (history == null || history.length < 2) {
      _popularityVelocity[songId] = 0.0;
      return;
    }

    final now = DateTime.now();
    final recentPoints =
        history
            .where(
              (point) => now.difference(point.timestamp) <= _analyticsWindow,
            )
            .toList();

    if (recentPoints.length < 2) {
      _popularityVelocity[songId] = 0.0;
      return;
    }

    recentPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final oldest = recentPoints.first;
    final newest = recentPoints.last;

    final timeDiff = newest.timestamp.difference(oldest.timestamp).inHours;
    if (timeDiff == 0) {
      _popularityVelocity[songId] = 0.0;
      return;
    }

    final streamDiff = newest.dailyStreams - oldest.dailyStreams;
    final velocity = streamDiff / timeDiff.toDouble();

    _popularityVelocity[songId] = velocity;
  }

  double getPopularityVelocity(String songId) {
    return _popularityVelocity[songId] ?? 0.0;
  }

  bool isTrending(String songId, {double threshold = 1000.0}) {
    final velocity = getPopularityVelocity(songId);
    return velocity.abs() > threshold;
  }

  bool isRising(String songId, {double threshold = 100.0}) {
    final velocity = getPopularityVelocity(songId);
    return velocity > threshold;
  }

  bool isFalling(String songId, {double threshold = -100.0}) {
    final velocity = getPopularityVelocity(songId);
    return velocity < threshold;
  }

  List<StreamDataPoint> getStreamHistory(String songId) {
    return _streamHistory[songId] ?? [];
  }

  TrendAnalysis analyzeTrend(String songId) {
    final history = _streamHistory[songId];
    if (history == null || history.length < 3) {
      return TrendAnalysis(
        trend: TrendDirection.stable,
        confidence: 0.0,
        velocity: 0.0,
        acceleration: 0.0,
      );
    }

    final recentHistory =
        history
            .where(
              (point) =>
                  DateTime.now().difference(point.timestamp) <=
                  _analyticsWindow,
            )
            .toList();

    if (recentHistory.length < 3) {
      return TrendAnalysis(
        trend: TrendDirection.stable,
        confidence: 0.0,
        velocity: getPopularityVelocity(songId),
        acceleration: 0.0,
      );
    }

    recentHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate velocity changes (acceleration)
    final velocities = <double>[];
    for (int i = 1; i < recentHistory.length; i++) {
      final prev = recentHistory[i - 1];
      final curr = recentHistory[i];
      final timeDiff = curr.timestamp.difference(prev.timestamp).inHours;

      if (timeDiff > 0) {
        final streamDiff = curr.dailyStreams - prev.dailyStreams;
        velocities.add(streamDiff / timeDiff);
      }
    }

    if (velocities.isEmpty) {
      return TrendAnalysis(
        trend: TrendDirection.stable,
        confidence: 0.0,
        velocity: getPopularityVelocity(songId),
        acceleration: 0.0,
      );
    }

    final avgVelocity = velocities.reduce((a, b) => a + b) / velocities.length;

    // Calculate acceleration (change in velocity)
    double acceleration = 0.0;
    if (velocities.length >= 2) {
      final recentVelocities = velocities.skip(velocities.length ~/ 2).toList();
      final earlyVelocities = velocities.take(velocities.length ~/ 2).toList();

      final recentAvg =
          recentVelocities.reduce((a, b) => a + b) / recentVelocities.length;
      final earlyAvg =
          earlyVelocities.reduce((a, b) => a + b) / earlyVelocities.length;

      acceleration = recentAvg - earlyAvg;
    }

    // Determine trend direction
    TrendDirection trend;
    if (avgVelocity > 100) {
      trend = TrendDirection.rising;
    } else if (avgVelocity < -100) {
      trend = TrendDirection.falling;
    } else {
      trend = TrendDirection.stable;
    }

    // Calculate confidence based on consistency
    final velocityVariance = _calculateVariance(velocities);
    final confidence = max(0.0, min(1.0, 1.0 - (velocityVariance / 10000)));

    return TrendAnalysis(
      trend: trend,
      confidence: confidence,
      velocity: avgVelocity,
      acceleration: acceleration,
    );
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  List<String> getTopMovers({
    int limit = 20,
    bool ascending = false,
    double minConfidence = 0.3,
  }) {
    final movers = <String, double>{};

    for (final songId in _popularityVelocity.keys) {
      final analysis = analyzeTrend(songId);
      if (analysis.confidence >= minConfidence &&
          analysis.trend != TrendDirection.stable) {
        movers[songId] = analysis.velocity;
      }
    }

    final sortedMovers = movers.entries.toList();
    sortedMovers.sort(
      (a, b) =>
          ascending ? a.value.compareTo(b.value) : b.value.compareTo(a.value),
    );

    return sortedMovers.take(limit).map((entry) => entry.key).toList();
  }

  Future<void> clearAnalytics() async {
    _streamHistory.clear();
    _popularityVelocity.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_streamHistoryKey);
  }
}

class StreamDataPoint {
  final DateTime timestamp;
  final int totalStreams;
  final int dailyStreams;
  final int weeklyStreams;
  final int monthlyStreams;
  final int yearlyStreams;
  final double price;

  StreamDataPoint({
    required this.timestamp,
    required this.totalStreams,
    required this.dailyStreams,
    required this.weeklyStreams,
    required this.monthlyStreams,
    required this.yearlyStreams,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'totalStreams': totalStreams,
      'dailyStreams': dailyStreams,
      'weeklyStreams': weeklyStreams,
      'monthlyStreams': monthlyStreams,
      'yearlyStreams': yearlyStreams,
      'price': price,
    };
  }

  factory StreamDataPoint.fromJson(Map<String, dynamic> json) {
    return StreamDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      totalStreams: json['totalStreams'],
      dailyStreams: json['dailyStreams'],
      weeklyStreams: json['weeklyStreams'],
      monthlyStreams: json['monthlyStreams'],
      yearlyStreams: json['yearlyStreams'],
      price: json['price']?.toDouble() ?? 0.0,
    );
  }
}

enum TrendDirection { rising, falling, stable }

class TrendAnalysis {
  final TrendDirection trend;
  final double confidence;
  final double velocity;
  final double acceleration;

  TrendAnalysis({
    required this.trend,
    required this.confidence,
    required this.velocity,
    required this.acceleration,
  });

  bool get isSignificant => confidence > 0.5;
  bool get isRising => trend == TrendDirection.rising && isSignificant;
  bool get isFalling => trend == TrendDirection.falling && isSignificant;
  bool get isStable => trend == TrendDirection.stable || !isSignificant;
}
