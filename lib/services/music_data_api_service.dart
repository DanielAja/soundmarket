import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  
  // Price calculation factors
  final double _basePrice = 5.0;
  final double _streamMultiplier = 0.0001; // Price increase per stream
  final double _volatilityFactor = 0.05; // Random price fluctuation (5%)
  
  // Initialize the service
  void initialize(List<Song> songs) {
    // Initialize stream counts for songs
    for (var song in songs) {
      // Initial stream count (would come from API in real app)
      _songStreams[song.id] = _getInitialStreamCount(song);
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
  
  // Update prices based on stream counts
  void _updatePrices() {
    final random = Random();
    final updates = <String, double>{};
    
    // Calculate new price for each song
    _songStreams.forEach((songId, streamCount) {
      // Base price calculation
      final basePrice = _basePrice + (streamCount * _streamMultiplier);
      
      // Add volatility (random fluctuation)
      final volatility = basePrice * _volatilityFactor * (random.nextDouble() * 2 - 1);
      final newPrice = max(0.1, basePrice + volatility);
      
      // Add to updates
      updates[songId] = double.parse(newPrice.toStringAsFixed(2));
    });
    
    // Send updates through the stream
    if (updates.isNotEmpty) {
      _priceUpdateController.add(updates);
    }
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
