import 'dart:async';
import 'dart:math';
import 'dart:collection';
import '../models/song.dart';
import '../../core/config/environment_config.dart'; // Corrected path
import 'spotify_api_service.dart';
import 'country_detection_service.dart';

class MusicDataApiService {
  // Singleton pattern
  static final MusicDataApiService _instance = MusicDataApiService._internal();
  factory MusicDataApiService() => _instance;
  MusicDataApiService._internal();

  // Stream controller for real-time price updates
  final _priceUpdateController =
      StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceUpdates => _priceUpdateController.stream;

  // Timer for periodic updates
  Timer? _updateTimer;

  // Spotify API service
  final SpotifyApiService _spotifyApi = SpotifyApiService();

  // Cache of songs
  final Map<String, Song> _songsCache = {};

  // Store stream counts (simulated but based on real popularity)
  final Map<String, int> _songStreams = {};

  // Store recent prices for moving average calculation
  final Map<String, Queue<double>> _recentPrices = {};

  // Price calculation factors for $10-$1000 range with reduced volatility
  final double _basePrice = 10.0;
  final double _streamMultiplier = 0.0002; // Increased to match new price scale
  final double _volatilityFactor = 0.004; // Low volatility for stability
  final int _movingAveragePeriod = 10; // Smooth price changes
  final double _maxPriceChangePercent =
      0.4; // Low percentage change for stability

  // Initialize with real data
  Future<void> initialize(List<Song> initialSongs) async {
    try {
      // Check if Spotify credentials are set
      final clientId = EnvironmentConfig.settings['spotifyClientId'];
      final clientSecret = EnvironmentConfig.settings['spotifyClientSecret'];

      if (clientId.isEmpty || clientSecret.isEmpty) {
        // print('Warning: Spotify API credentials not set. Using fallback data.'); // Removed print
        throw Exception('Spotify API credentials not set');
      }

      // Fetch top tracks from Spotify
      final topTracks = await _spotifyApi.getTopTracks();

      if (topTracks.isEmpty) {
        // print('Warning: No tracks returned from Spotify API. Using fallback data.'); // Removed print
        throw Exception('No tracks returned from Spotify API');
      } else {
        // print('Successfully fetched ${topTracks.length} tracks from Spotify API'); // Removed print
      }

      // Initialize cache with fetched songs
      for (var song in topTracks) {
        _songsCache[song.id] = song;
        _songStreams[song.id] = _estimateStreamCount(song);

        // Initialize price history
        _recentPrices[song.id] = Queue<double>();
        _recentPrices[song.id]!.add(song.currentPrice);
      }

      // print('Successfully loaded ${topTracks.length} songs from Spotify API'); // Removed print

      // Start periodic updates
      _startRealtimeUpdates();
    } catch (e) {
      // print('Error initializing music data: $e'); // Removed print

      // Fallback to initial songs if API fails
      for (var song in initialSongs) {
        _songsCache[song.id] = song;
        _songStreams[song.id] = _estimateStreamCount(song);

        _recentPrices[song.id] = Queue<double>();
        _recentPrices[song.id]!.add(song.currentPrice);
      }

      // Start periodic updates even with fallback data
      _startRealtimeUpdates();

      // Rethrow the exception so the caller knows there was an error
      throw e;
    }
  }

  // Estimate stream count based on song price/popularity
  int _estimateStreamCount(Song song) {
    // Reverse-engineer stream count from current price
    final baseStreamCount =
        ((song.currentPrice - _basePrice) / _streamMultiplier).round();
    return max(1000, baseStreamCount);
  }

  // Start real-time updates with reduced frequency for stability
  void _startRealtimeUpdates() {
    // Cancel any existing timer
    _updateTimer?.cancel();

    // Create a new timer that fires periodically
    // Update less frequently (20 seconds instead of 2) for better price stability
    _updateTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _updateStreamCounts();
      _updatePrices();
    });
  }

  // Set whether the discover tab is active (kept for compatibility with existing code)
  void setDiscoverTabActive(bool isActive) {
    // This method is kept for compatibility but doesn't affect functionality anymore
    // as we're using real data and updates happen regardless of which tab is active
  }

  // Update stream counts (still simulated but based on real popularity)
  void _updateStreamCounts() {
    final random = Random();

    _songStreams.forEach((songId, streamCount) {
      // Reduced stream count increases for more stable prices
      final baseIncrease = max(
        5,
        (streamCount * 0.0005).round(),
      ); // Half the previous values
      final increase =
          (baseIncrease * (0.3 + random.nextDouble() * 0.5))
              .round(); // Reduced randomness

      _songStreams[songId] = streamCount + increase;
    });
  }

  // Update prices based on stream counts
  void _updatePrices() {
    final random = Random();
    final updates = <String, double>{};

    _songStreams.forEach((songId, streamCount) {
      if (_recentPrices.containsKey(songId)) {
        final currentPrice = _recentPrices[songId]!.last;

        final basePrice = _basePrice + (streamCount * _streamMultiplier);
        final trendBias = _calculateTrendBias(songId);
        final volatilityRange = basePrice * _volatilityFactor;
        final volatility =
            volatilityRange *
            ((random.nextDouble() * 1.5) - 0.5 + (trendBias * 0.5));

        var rawNewPrice = max(0.1, basePrice + volatility);

        _addToRecentPrices(songId, rawNewPrice);
        final smoothedPrice = _calculateMovingAverage(songId);

        final maxChange = currentPrice * (_maxPriceChangePercent / 100);
        final limitedPrice = _limitPriceChange(
          currentPrice,
          smoothedPrice,
          maxChange,
        );

        updates[songId] = double.parse(limitedPrice.toStringAsFixed(2));
      }
    });

    if (updates.isNotEmpty) {
      _priceUpdateController.add(updates);
    }
  }

  // The following methods remain largely unchanged from the original implementation
  void _addToRecentPrices(String songId, double price) {
    final queue = _recentPrices[songId]!;
    queue.add(price);
    while (queue.length > _movingAveragePeriod) {
      queue.removeFirst();
    }
  }

  double _calculateMovingAverage(String songId) {
    final queue = _recentPrices[songId]!;
    if (queue.isEmpty) return 0;
    final sum = queue.fold<double>(0, (sum, price) => sum + price);
    return sum / queue.length;
  }

  double _calculateTrendBias(String songId) {
    final queue = _recentPrices[songId]!;
    if (queue.length < 2) return 0;

    double totalChangePercent = 0;
    double prevPrice = queue.first;

    for (int i = 1; i < queue.length; i++) {
      final currentPrice = queue.elementAt(i);
      final changePercent = (currentPrice - prevPrice) / prevPrice;
      totalChangePercent += changePercent;
      prevPrice = currentPrice;
    }

    final avgChangePercent = totalChangePercent / (queue.length - 1);
    return avgChangePercent * 10;
  }

  double _limitPriceChange(
    double currentPrice,
    double newPrice,
    double maxChange,
  ) {
    if ((newPrice - currentPrice).abs() > maxChange) {
      return currentPrice + (newPrice > currentPrice ? maxChange : -maxChange);
    }
    return newPrice;
  }

  // Get current stream count for a song
  int getStreamCount(String songId) {
    return _songStreams[songId] ?? 0;
  }

  // Get formatted stream count
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

  // Search for songs
  Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    try {
      return await _spotifyApi.searchTracks(query, limit: limit);
    } catch (e) {
      // print('Error searching songs: $e'); // Removed print
      return [];
    }
  }

  // Get new releases with country filtering
  Future<List<Song>> getNewReleases({int limit = 20, String? market}) async {
    try {
      final country = market ?? await CountryDetectionService.getUserCountry();
      return await _spotifyApi.getNewReleases(limit: limit, market: country);
    } catch (e) {
      // print('Error getting new releases: $e'); // Removed print
      return [];
    }
  }

  // Get top tracks for specific country
  Future<List<Song>> getTopTracksForCountry({
    int limit = 50,
    String? market,
  }) async {
    try {
      final country = market ?? await CountryDetectionService.getUserCountry();
      return await _spotifyApi.getTopTracksForCountry(
        limit: limit,
        market: country,
      );
    } catch (e) {
      // print('Error getting top tracks for country: $e'); // Removed print
      return [];
    }
  }

  // Get trending tracks (tracks with rapid stream changes)
  Future<List<Song>> getTrendingTracks({int limit = 20, String? market}) async {
    try {
      final country = market ?? await CountryDetectionService.getUserCountry();

      // Get recently popular tracks that might be trending
      final charts = await _spotifyApi.getFeaturedPlaylists(
        limit: 5,
        market: country,
      );
      final trendingTracks = <Song>[];

      // Extract songs from featured playlists (proxy for trending)
      for (final playlist in charts) {
        final playlistTracks = await _spotifyApi.getPlaylistTracks(
          playlist['id'],
          limit: 10,
        );
        trendingTracks.addAll(playlistTracks);

        if (trendingTracks.length >= limit) break;
      }

      // Sort by simulated popularity velocity (proxy for stream changes)
      trendingTracks.shuffle(); // Randomize since we don't have real trend data
      return trendingTracks.take(limit).toList();
    } catch (e) {
      // print('Error getting trending tracks: $e'); // Removed print
      return [];
    }
  }

  // Trigger a manual update
  void triggerPriceUpdate() {
    _updateStreamCounts();
    _updatePrices();
  }

  // Refresh data from API
  Future<void> refreshData() async {
    try {
      final topTracks = await _spotifyApi.getTopTracks();

      // Update cache with new data
      for (var song in topTracks) {
        if (_songsCache.containsKey(song.id)) {
          // Store previous price
          song.previousPrice = _songsCache[song.id]!.currentPrice;
        }

        _songsCache[song.id] = song;

        // Update stream count if not already set
        if (!_songStreams.containsKey(song.id)) {
          _songStreams[song.id] = _estimateStreamCount(song);
        }

        // Initialize price history if not already set
        if (!_recentPrices.containsKey(song.id)) {
          _recentPrices[song.id] = Queue<double>();
          _recentPrices[song.id]!.add(song.currentPrice);
        }
      }
    } catch (e) {
      // print('Error refreshing data: $e'); // Removed print
    }
  }

  // Get all cached songs
  List<Song> getAllCachedSongs() {
    return _songsCache.values.toList();
  }

  // Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _priceUpdateController.close();
    _spotifyApi.dispose();
  }
}
