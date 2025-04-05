import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:collection';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicDataApiService {
  // Singleton pattern
  static final MusicDataApiService _instance = MusicDataApiService._internal();
  factory MusicDataApiService() => _instance;
  MusicDataApiService._internal();

  // Stream controller for real-time price updates
  final _priceUpdateController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceUpdates => _priceUpdateController.stream;

  // Timer for simulating real-time updates
  Timer? _updateTimer;
  
  // Flag to control updates based on active tab
  bool _isDiscoverTabActive = false;
  
  // Mock data for streams (in a real app, this would come from an actual API)
  final Map<String, int> _songStreams = {};
  
  // Store recent prices for moving average calculation
  final Map<String, Queue<double>> _recentPrices = {};
  
  // Price calculation factors
  final double _basePrice = 5.0;
  final double _streamMultiplier = 0.0001; // Price increase per stream
  final double _volatilityFactor = 0.02; // Reduced volatility (2% instead of 5%)
  final int _movingAveragePeriod = 5; // Number of periods for moving average
  final double _maxPriceChangePercent = 2.0; // Maximum price change per update (2%)
  
  // Initialize the service
  void initialize(List<Song> songs) {
    // Initialize stream counts and price history for songs
    for (var song in songs) {
      // Initial stream count (would come from API in real app)
      _songStreams[song.id] = _getInitialStreamCount(song);
      
      // Initialize price history with current price
      _recentPrices[song.id] = Queue<double>();
      _recentPrices[song.id]!.add(song.currentPrice);
    }
    
    // Start the update timer, but updates will only happen when discover tab is active
    _startRealtimeUpdates();
  }
  
  // Set whether the discover tab is active
  void setDiscoverTabActive(bool isActive) {
    _isDiscoverTabActive = isActive;
  }
  
  // Get initial stream count based on song price
  int _getInitialStreamCount(Song song) {
    // Reverse-engineer stream count from current price
    final baseStreamCount = ((song.currentPrice - _basePrice) / _streamMultiplier).round();
    return max(0, baseStreamCount);
  }
  
  // Start real-time updates
  void _startRealtimeUpdates() {
    // Cancel any existing timer
    _updateTimer?.cancel();
    
    // Create a new timer that fires every 5 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Only update if discover tab is active
      if (_isDiscoverTabActive) {
        _updateStreamCounts();
        _updatePrices();
      }
    });
  }
  
  // Update stream counts (simulated)
  void _updateStreamCounts() {
    final random = Random();
    
    // Update each song's stream count
    _songStreams.forEach((songId, streamCount) {
      // Simulate stream count increase (more popular songs get more streams)
      final popularity = streamCount / 1000000; // Normalize to 0-1 range
      final baseIncrease = max(10, (streamCount * 0.001).round()); // 0.1% base increase
      
      // Calculate stream increase with some randomness
      final increase = (baseIncrease * (0.5 + random.nextDouble())).round();
      
      // Update stream count
      _songStreams[songId] = streamCount + increase;
    });
  }
  
  // Update prices based on stream counts with improved stability
  void _updatePrices() {
    final random = Random();
    final updates = <String, double>{};
    
    // Calculate new price for each song
    _songStreams.forEach((songId, streamCount) {
      // Get current price (last price in the queue)
      final currentPrice = _recentPrices[songId]!.last;
      
      // Base price calculation
      final basePrice = _basePrice + (streamCount * _streamMultiplier);
      
      // Add reduced volatility with trend bias
      // This creates a more stable random component that's biased by recent trends
      final trendBias = _calculateTrendBias(songId);
      final volatilityRange = basePrice * _volatilityFactor;
      final volatility = volatilityRange * ((random.nextDouble() * 1.5) - 0.5 + (trendBias * 0.5));
      
      // Calculate raw new price
      var rawNewPrice = max(0.1, basePrice + volatility);
      
      // Apply moving average to smooth out price changes
      _addToRecentPrices(songId, rawNewPrice);
      final smoothedPrice = _calculateMovingAverage(songId);
      
      // Limit maximum price change to prevent extreme fluctuations
      final maxChange = currentPrice * (_maxPriceChangePercent / 100);
      final limitedPrice = _limitPriceChange(currentPrice, smoothedPrice, maxChange);
      
      // Add to updates with 2 decimal precision
      updates[songId] = double.parse(limitedPrice.toStringAsFixed(2));
    });
    
    // Send updates through the stream
    if (updates.isNotEmpty) {
      _priceUpdateController.add(updates);
    }
  }
  
  // Add a price to the recent prices queue
  void _addToRecentPrices(String songId, double price) {
    final queue = _recentPrices[songId]!;
    
    // Add the new price
    queue.add(price);
    
    // Keep only the most recent prices based on moving average period
    while (queue.length > _movingAveragePeriod) {
      queue.removeFirst();
    }
  }
  
  // Calculate moving average of recent prices
  double _calculateMovingAverage(String songId) {
    final queue = _recentPrices[songId]!;
    
    if (queue.isEmpty) return 0;
    
    final sum = queue.fold<double>(0, (sum, price) => sum + price);
    return sum / queue.length;
  }
  
  // Calculate trend bias (-1 to 1) based on recent price movements
  double _calculateTrendBias(String songId) {
    final queue = _recentPrices[songId]!;
    
    if (queue.length < 2) return 0;
    
    // Calculate average price change over recent periods
    double totalChangePercent = 0;
    double prevPrice = queue.first;
    
    for (int i = 1; i < queue.length; i++) {
      final currentPrice = queue.elementAt(i);
      final changePercent = (currentPrice - prevPrice) / prevPrice;
      totalChangePercent += changePercent;
      prevPrice = currentPrice;
    }
    
    // Return normalized trend (-1 to 1 range)
    final avgChangePercent = totalChangePercent / (queue.length - 1);
    return avgChangePercent * 10; // Scale to make small changes more significant
  }
  
  // Limit price change to prevent extreme fluctuations
  double _limitPriceChange(double currentPrice, double newPrice, double maxChange) {
    if ((newPrice - currentPrice).abs() > maxChange) {
      // Limit the change to maxChange in the appropriate direction
      return currentPrice + (newPrice > currentPrice ? maxChange : -maxChange);
    }
    return newPrice;
  }
  
  // Get current stream count for a song
  int getStreamCount(String songId) {
    return _songStreams[songId] ?? 0;
  }
  
  // Get formatted stream count (e.g., "1.2M")
  String getFormattedStreamCount(String songId) {
    final count = getStreamCount(songId);
    
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
  
  // Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _priceUpdateController.close();
  }
}
