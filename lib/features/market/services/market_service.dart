import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
import '../../../shared/models/song.dart';
import '../../../shared/models/portfolio_item.dart'; // Import PortfolioItem
import '../../../shared/services/spotify_api_service.dart'; // Import SpotifyApiService
import '../../../shared/services/storage_service.dart'; // Import StorageService
import '../../../shared/services/pricing_engine.dart'; // Import PricingEngine
import '../../../shared/models/stream_history.dart'; // Import StreamHistory
import '../../../shared/models/pricing_metrics.dart'; // Import PricingMetrics

class MarketService {
  // Singleton pattern
  static final MarketService _instance = MarketService._internal();
  factory MarketService() => _instance;

  // Cached lists to maintain consistent order
  List<Song>? _cachedTopSongs;
  List<Song>? _cachedTopMovers;
  List<String>? _cachedRisingArtists;

  // Songs list (will be populated from Spotify API)
  final List<Song> _songs = [];
  bool _isInitialized = false; // Flag to track initialization

  // Services
  final SpotifyApiService _spotifyApi = SpotifyApiService();
  final StorageService _storageService = StorageService();

  // Stream controller for song updates
  final _songUpdateController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get songUpdates => _songUpdateController.stream;

  // Timer for price simulation
  Timer? _priceUpdateTimer;
  // Counter for periodic saving of stream updates
  int _streamUpdateSaveCounter = 0;
  // Random number generator no longer used since we rely solely on popularity data

  MarketService._internal() {
    _initialize();
    // Start continuous real-time price updates immediately
    startContinuousUpdates();
  }

  // Initialize the MarketService
  Future<void> _initialize() async {
    await _loadSavedSongsOrFetchNew();
  }

  // Try to load saved songs, or fetch new ones if there are none saved
  Future<void> _loadSavedSongsOrFetchNew() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      print(
        'Loading saved songs or initializing MarketService with Spotify data...',
      );

      // First try to load songs from storage
      final savedSongs = await _storageService.loadSongs();

      if (savedSongs.isNotEmpty) {
        // Check how many cached songs have preview URLs
        final playableSongs =
            savedSongs
                .where(
                  (song) =>
                      song.previewUrl != null && song.previewUrl!.isNotEmpty,
                )
                .toList();

        final playablePercentage =
            playableSongs.length / savedSongs.length * 100;
        print(
          'Loaded ${savedSongs.length} saved songs: ${playableSongs.length} playable (${playablePercentage.round()}%)',
        );

        // If less than 50% of cached songs are playable, refresh from API
        if (playablePercentage < 50) {
          print(
            '⚠️ Too few playable songs in cache (${playablePercentage.round()}%). Refreshing from API...',
          );
          await _fetchSongsFromSpotify();
        } else {
          _songs.clear();
          _songs.addAll(savedSongs);
          _updateCachedLists();
          _isInitialized = true;
          // Start the price simulation timer after loading saved songs
          _startPriceSimulation();
          // Notify listeners with loaded data
          _songUpdateController.add(List.from(_songs));
        }
      } else {
        // If no saved songs, fetch from Spotify API
        print('No saved songs found. Fetching from Spotify API...');
        await _fetchSongsFromSpotify();
      }
    } catch (e) {
      print('Error loading saved songs: $e');
      // Try to fetch from Spotify API if loading fails
      await _fetchSongsFromSpotify();
    }
  }

  // Initialize the Spotify API service and fetch initial data
  Future<void> _fetchSongsFromSpotify() async {
    try {
      print('Initializing MarketService with Spotify data...');

      // Clear any cached songs first to get fresh data
      await _storageService.clearSongs();

      // Fetch top popular tracks with preview URLs only
      final apiSongs = await _spotifyApi.getTopTracksWithPreviews(
        limit: 100,
      ); // Fetch 100 playable tracks

      if (apiSongs.isNotEmpty) {
        _songs.clear();
        _songs.addAll(apiSongs);

        // Fetch additional songs in various genres for better diversity
        await _enrichWithMoreGenres();

        _updateCachedLists();
        _isInitialized = true; // Mark as initialized
        print(
          'MarketService initialized successfully with ${_songs.length} songs.',
        );

        // Save only playable songs to storage
        await _storageService.savePlayableSongs(_songs);

        // Start the price simulation timer only after successful initialization
        _startPriceSimulation();
        // Notify listeners with initial data
        _songUpdateController.add(List.from(_songs));
      } else {
        print(
          'Warning: Spotify API returned no songs. MarketService not fully initialized.',
        );
        // Consider adding fallback logic here if needed, or rely on retries
      }
    } catch (e) {
      print('Error initializing MarketService with Spotify API: $e');
      // Handle initialization error (e.g., retry later, show error message)
    }
  }

  // Enriches the song collection with more diverse genres and related songs
  Future<void> _enrichWithMoreGenres() async {
    try {
      // Add trending songs from specific genres for diversity
      final genresToFetch = ['rock', 'electronic', 'hip-hop', 'indie', 'r&b'];

      for (final genre in genresToFetch) {
        final genreSongs = await _spotifyApi.searchTracks(
          'genre:$genre',
          limit: 20,
        );
        if (genreSongs.isNotEmpty) {
          print('Adding ${genreSongs.length} songs from $genre genre');
          _songs.addAll(genreSongs);
        }
      }

      // Add newest releases
      final newReleases = await _spotifyApi.getNewReleases(limit: 40);
      if (newReleases.isNotEmpty) {
        print('Adding ${newReleases.length} new releases');
        _songs.addAll(newReleases);
      }

      // Remove duplicates (in case the same song appears in multiple search results)
      final uniqueSongs = <String, Song>{};
      for (final song in _songs) {
        uniqueSongs[song.id] = song;
      }
      _songs.clear();
      _songs.addAll(uniqueSongs.values);

      print('Total songs after enrichment: ${_songs.length}');
    } catch (e) {
      print('Error enriching song catalog with additional genres: $e');
    }
  }

  // Start the price simulation timer with increased interval for stability
  void _startPriceSimulation() {
    _priceUpdateTimer?.cancel(); // Cancel existing timer
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 10), (
      timer,
    ) async {
      // Simulate price changes much less frequently (10 minutes instead of 3)
      // This significantly reduces how often popularity-based price updates occur
      await _simulatePriceChanges();
    });
  }

  // Update song prices based on Spotify popularity in batches to avoid rate limiting
  Future<void> _simulatePriceChanges() async {
    if (_songs.isEmpty) return; // Don't simulate if no songs loaded

    try {
      // Take a subset of songs to update (max 50 per batch)
      final songsToUpdate = _songs.length > 50 ? _songs.sublist(0, 50) : _songs;

      print('Updating prices for ${songsToUpdate.length} songs in batch');

      // Store previous prices
      for (final song in songsToUpdate) {
        song.previousPrice = song.currentPrice;
      }

      // Extract IDs for batch request
      final songIds = songsToUpdate.map((song) => song.id).toList();

      // Make batch request for all songs at once
      final batchDetails = await _spotifyApi.getTrackDetailsBatch(songIds);
      bool hasUpdates = false;

      // Process the results
      for (final song in songsToUpdate) {
        if (batchDetails.containsKey(song.id) &&
            batchDetails[song.id]!.containsKey('track') &&
            batchDetails[song.id]!['track'] != null) {
          final track = batchDetails[song.id]!['track'];
          final int popularity =
              track['popularity'] ?? 50; // Default to 50 if not available

          // Update stream counts based on popularity (simulating real-world stream changes)
          _updateStreamCounts(song, popularity);

          // Use PricingEngine to calculate new price based on weighted streaming algorithm
          final updatedSong = PricingEngine.updateSongPrice(song);
          song.currentPrice = updatedSong.currentPrice;
          song.basePricePerStream =
              updatedSong.basePricePerStream; // Update dynamic base price

          // Save pricing metrics for analysis
          _savePricingMetrics(song);

          // Apply consistent minimum price (using PricingEngine's minimum)
          if (song.currentPrice < 0.01) {
            song.currentPrice = 0.01;
          }

          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        _updateCachedLists();
        _songUpdateController.add(List.from(_songs));

        // Save updated songs to storage (only playable ones)
        try {
          await _storageService.savePlayableSongs(_songs);
        } catch (e) {
          print('Error saving updated song prices: $e');
        }
      }
    } catch (e) {
      print('Error updating song prices in batch: $e');
    }
  }

  // Continuous real-time price updates based on stream counts
  Timer? _continuousUpdateTimer;

  // Start continuous real-time price updates with reduced frequency for stability
  void startContinuousUpdates() {
    stopContinuousUpdates(); // Stop any existing timer

    // Update prices every 30 seconds (instead of 10) to improve price stability
    // This significantly reduces the frequency of price changes
    _continuousUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      await _updatePricesBasedOnStreams();
    });

    print(
      'Started stabilized price updates with reduced frequency for better price stability',
    );
  }

  // Stop continuous updates
  void stopContinuousUpdates() {
    _continuousUpdateTimer?.cancel();
    _continuousUpdateTimer = null;
  }

  // Update prices based on simulated stream counts with increased stability
  Future<void> _updatePricesBasedOnStreams() async {
    if (_songs.isEmpty) return; // Don't update if no songs loaded

    bool hasUpdates = false;

    // Update a smaller subset of songs (15% instead of 30%) to reduce volatility
    final songsToUpdate = (_songs.length * 0.15).ceil();
    final shuffledSongs = List<Song>.from(_songs)..shuffle();
    final songsSubset = shuffledSongs.take(songsToUpdate).toList();

    for (final song in songsSubset) {
      song.previousPrice = song.currentPrice; // Store previous price

      try {
        // Estimate popularity from current price using bell curve inverse mapping
        int estimatedPopularity = _estimatePopularityFromBellCurvePrice(
          song.currentPrice,
        );

        // Update stream counts based on popularity
        _updateStreamCounts(song, estimatedPopularity);

        // Use PricingEngine to calculate new price based on weighted streaming algorithm
        double newPrice = PricingEngine.calculatePrice(song);

        // Apply consistent minimum price for bell curve distribution
        if (newPrice < 0.10) {
          newPrice = 0.10;
        }

        // Dynamic threshold based on price range for bell curve distribution
        double threshold = _calculatePriceChangeThreshold(song.currentPrice);
        if ((newPrice - song.currentPrice).abs() > threshold) {
          song.currentPrice = newPrice;

          // Update dynamic base price per stream
          song.basePricePerStream =
              PricingEngine.calculateDynamicBasePricePerStream(
                song.allTimeStreams,
              );

          // Save pricing metrics for significant price changes
          _savePricingMetrics(song);

          hasUpdates = true;
        }
      } catch (e) {
        print('Error updating stream-based price for song ${song.name}: $e');
        // On error, maintain the current price
      }
    }

    if (hasUpdates) {
      _updateCachedLists();
      _songUpdateController.add(List.from(_songs));

      // Save updated songs to storage periodically (every 10 updates instead of 5)
      // This reduces the frequency of storage operations
      _streamUpdateSaveCounter++;
      if (_streamUpdateSaveCounter >= 10) {
        _streamUpdateSaveCounter = 0;
        try {
          await _storageService.savePlayableSongs(_songs);
        } catch (e) {
          print('Error saving stream-updated song prices: $e');
        }
      }
    }
  }

  // Dispose resources
  void dispose() {
    stopContinuousUpdates(); // Ensure timer is stopped
    _priceUpdateTimer?.cancel(); // Cancel the timer
    _songUpdateController.close();
  }

  // Update cached lists
  void _updateCachedLists() {
    if (_songs.isEmpty) {
      _cachedTopSongs = [];
      _cachedTopMovers = [];
      _cachedRisingArtists = [];
      return;
    }
    // Update top songs
    final topSongs = List<Song>.from(_songs);
    topSongs.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    _cachedTopSongs = topSongs;

    // Update top movers
    final topMovers = List<Song>.from(_songs);
    topMovers.sort(
      (a, b) =>
          b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()),
    );
    _cachedTopMovers = topMovers;

    // Update rising artists
    _cachedRisingArtists = _calculateRisingArtists();
  }

  // Refresh data from Spotify API
  Future<void> refreshData() async {
    // Re-initialize to fetch fresh data
    _isInitialized = false; // Allow re-initialization
    await _fetchSongsFromSpotify();
  }

  // Load songs similar to a user's portfolio
  Future<void> loadRelatedSongsForPortfolio(
    List<PortfolioItem> portfolio,
  ) async {
    if (portfolio.isEmpty)
      return; // No portfolio items to find related songs for

    try {
      print('Loading songs related to user portfolio...');
      final artistsInPortfolio =
          portfolio.map((item) => item.artistName).toSet().toList();
      final songsInPortfolio =
          portfolio.map((item) => item.songId).toSet().toList();

      // Limit to top 5 artists to avoid too many API calls
      final topArtists = artistsInPortfolio.take(5).toList();

      // Create a map to avoid duplicates
      final Map<String, Song> newSongs = {};

      // For each artist in portfolio, find their popular songs
      for (final artist in topArtists) {
        final artistSongs = await _spotifyApi.searchTracks(
          'artist:"$artist"',
          limit: 10,
        );
        for (final song in artistSongs) {
          // Skip songs already in portfolio
          if (!songsInPortfolio.contains(song.id)) {
            newSongs[song.id] = song;
          }
        }
      }

      // Add similar genres based on portfolio
      final genresInPortfolio =
          portfolio
              .map((item) {
                final song = _songs.firstWhere(
                  (s) => s.id == item.songId,
                  orElse:
                      () => Song(
                        id: item.songId,
                        name: item.songName,
                        artist: item.artistName,
                        genre: 'Unknown',
                        currentPrice: item.purchasePrice,
                      ),
                );
                return song.genre;
              })
              .where((genre) => genre != 'Unknown')
              .toSet()
              .toList();

      // For each genre in portfolio, find popular songs
      for (final genre in genresInPortfolio) {
        final genreSongs = await _spotifyApi.searchTracks(
          'genre:"$genre"',
          limit: 10,
        );
        for (final song in genreSongs) {
          if (!songsInPortfolio.contains(song.id)) {
            newSongs[song.id] = song;
          }
        }
      }

      // Add the new songs to our collection if they're not already there
      if (newSongs.isNotEmpty) {
        print('Adding ${newSongs.length} songs related to user portfolio');
        final uniqueIds = _songs.map((s) => s.id).toSet();
        final newSongsToAdd =
            newSongs.values.where((s) => !uniqueIds.contains(s.id)).toList();

        if (newSongsToAdd.isNotEmpty) {
          _songs.addAll(newSongsToAdd);
          _updateCachedLists();
          _songUpdateController.add(List.from(_songs));
        }
      }
    } catch (e) {
      print('Error loading portfolio-related songs: $e');
    }
  }

  // --- Stream Count methods removed as Spotify API doesn't provide this directly ---

  // Trigger a manual update of song prices
  Future<void> triggerPriceUpdate() async {
    await _simulatePriceChanges();
  }

  // Search for songs using Spotify API
  Future<List<Song>> searchSongs(String query) async {
    // Ensure service is initialized before searching
    if (!_isInitialized) await _loadSavedSongsOrFetchNew();
    return await _spotifyApi.searchTracks(query);
  }

  // Get new releases using Spotify API
  Future<List<Song>> getNewReleases() async {
    // Ensure service is initialized before fetching
    if (!_isInitialized) await _loadSavedSongsOrFetchNew();
    return await _spotifyApi.getNewReleases();
  }

  // Get all songs (returns the currently loaded list)
  List<Song> getAllSongs() {
    // Ensure service is initialized before returning songs
    // Consider adding a loading state if initialization is ongoing
    // if (!_isInitialized) await _initializeSpotifyApi(); // Could await here, but might block UI
    return List.from(_songs);
  }

  // Get song by ID
  Song? getSongById(String id) {
    // Ensure service is initialized before getting song
    // if (!_isInitialized) await _initializeSpotifyApi();
    try {
      return _songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  // Get top songs (by price)
  List<Song> getTopSongs({int limit = 10}) {
    // Ensure service is initialized before getting songs
    // if (!_isInitialized) await _initializeSpotifyApi();
    if (_cachedTopSongs == null || _cachedTopSongs!.isEmpty) {
      return [];
    }
    return _cachedTopSongs!.take(limit).toList();
  }

  // Get top movers (by percentage change)
  List<Song> getTopMovers({int limit = 10}) {
    // Ensure service is initialized before getting songs
    // if (!_isInitialized) await _initializeSpotifyApi();
    if (_cachedTopMovers == null || _cachedTopMovers!.isEmpty) {
      return [];
    }
    return _cachedTopMovers!.take(limit).toList();
  }

  // Get songs by genre
  List<Song> getSongsByGenre(String genre) {
    // Ensure service is initialized before getting songs
    // if (!_isInitialized) await _initializeSpotifyApi();
    return _songs
        .where((song) => song.genre.toLowerCase() == genre.toLowerCase())
        .toList();
  }

  // Get all genres
  List<String> getAllGenres() {
    // Ensure service is initialized before getting genres
    // if (!_isInitialized) await _initializeSpotifyApi();
    return _songs
        .map((song) => song.genre)
        .whereType<String>()
        .toSet()
        .toList();
  }

  // Get songs by artist
  List<Song> getSongsByArtist(String artist) {
    // Ensure service is initialized before getting songs
    // if (!_isInitialized) await _initializeSpotifyApi();
    return _songs.where((song) => song.artist == artist).toList();
  }

  // Get unique artists
  List<String> getUniqueArtists() {
    // Ensure service is initialized before getting artists
    // if (!_isInitialized) await _initializeSpotifyApi();
    final artists =
        _songs.map((song) => song.artist).whereType<String>().toSet().toList();
    return artists;
  }

  // Legacy pricing method removed - replaced by bell curve pricing in PricingEngine

  // Legacy stream scoring method removed - replaced by bell curve pricing

  // Calculate rising artists (helper method)
  List<String> _calculateRisingArtists() {
    if (_songs.isEmpty) return [];

    final artistMap = <String, List<Song>>{};

    // Group songs by artist
    for (final song in _songs) {
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = [];
      }
      artistMap[song.artist]!.add(song);
    }

    // Calculate average price change for each artist
    final artistChanges = <String, double>{};
    artistMap.forEach((artist, songs) {
      double totalChange = 0;
      for (final song in songs) {
        totalChange += song.priceChangePercent;
      }
      artistChanges[artist] =
          songs.isNotEmpty ? totalChange / songs.length : 0.0;
    });

    // Sort artists by average price change
    final sortedArtists = artistChanges.keys.toList();
    sortedArtists.sort(
      (a, b) => artistChanges[b]!.compareTo(artistChanges[a]!),
    );

    return sortedArtists;
  }

  // Get rising artists (artists with highest average price increase)
  List<String> getRisingArtists({int limit = 5}) {
    // Ensure service is initialized before getting artists
    // if (!_isInitialized) await _initializeSpotifyApi();
    if (_cachedRisingArtists == null || _cachedRisingArtists!.isEmpty) {
      return [];
    }
    return _cachedRisingArtists!.take(limit).toList();
  }

  // Helper method to update stream counts with realistic patterns
  void _updateStreamCounts(Song song, int popularity) {
    final random = Random();

    // Initialize realistic stream counts if they're zero or too low
    if (song.allTimeStreams == 0 || song.allTimeStreams < 1000) {
      _initializeRealisticStreamCounts(song, popularity);
    }

    // Calculate growth/decline rates based on popularity with more realistic patterns
    double baseGrowthFactor = _calculateRealisticGrowthFactor(
      popularity,
      random,
    );

    // Add market sentiment and volatility
    double sentimentFactor = _calculateMarketSentiment(song, random);
    double growthFactor = baseGrowthFactor * sentimentFactor;

    // Update streams with realistic decay patterns
    _updateDailyStreams(song, growthFactor, random);
    _updateWeeklyStreams(song, growthFactor, random);
    _updateMonthlyStreams(song, growthFactor, random);
    _updateYearlyStreams(song, growthFactor, random);
    _updateLongTermStreams(song, growthFactor, random);

    // Ensure logical consistency between time periods
    _ensureStreamConsistency(song);

    // Update total streams for backward compatibility
    song.totalStreams = song.allTimeStreams;

    // Save stream history for analytics (every 10th update to avoid excessive data)
    if (random.nextInt(10) == 0) {
      _saveStreamHistoryEntry(song);
    }
  }

  // Save stream history entry asynchronously
  void _saveStreamHistoryEntry(Song song) {
    // Don't await this to avoid blocking the price update process
    _storageService
        .saveStreamHistory(
          StreamHistory(
            songId: song.id,
            timestamp: DateTime.now(),
            streamCount: song.dailyStreams,
            period: 'daily',
          ),
        )
        .catchError((error) {
          print('Error saving stream history for ${song.name}: $error');
        });
  }

  // Save pricing metrics entry asynchronously
  void _savePricingMetrics(Song song) {
    // Don't await this to avoid blocking the price update process
    try {
      final breakdown = PricingEngine.getPricingBreakdown(song);
      final metrics = PricingMetrics.fromBreakdown(
        breakdown,
        song.previousPrice,
        0.0, // Volatility score calculation would go here
      );

      _storageService.savePricingMetrics(metrics).catchError((error) {
        print('Error saving pricing metrics for ${song.name}: $error');
      });
    } catch (error) {
      print('Error creating pricing metrics for ${song.name}: $error');
    }
  }

  // Initialize realistic stream counts based on popularity
  void _initializeRealisticStreamCounts(Song song, int popularity) {
    final random = Random();

    // Base stream counts on realistic Spotify distribution
    int baseAllTimeStreams;
    if (popularity >= 90) {
      // Ultra-viral tracks: 50M-500M+ streams
      baseAllTimeStreams = 50000000 + random.nextInt(450000000);
    } else if (popularity >= 80) {
      // Very popular: 10M-50M streams
      baseAllTimeStreams = 10000000 + random.nextInt(40000000);
    } else if (popularity >= 70) {
      // Popular: 1M-10M streams
      baseAllTimeStreams = 1000000 + random.nextInt(9000000);
    } else if (popularity >= 50) {
      // Moderate: 100K-1M streams
      baseAllTimeStreams = 100000 + random.nextInt(900000);
    } else if (popularity >= 30) {
      // Emerging: 10K-100K streams
      baseAllTimeStreams = 10000 + random.nextInt(90000);
    } else {
      // Niche: 1K-10K streams
      baseAllTimeStreams = 1000 + random.nextInt(9000);
    }

    song.allTimeStreams = baseAllTimeStreams;
    song.lastFiveYearsStreams = (baseAllTimeStreams * 0.85).round();
    song.yearlyStreams = (baseAllTimeStreams * 0.15).round();
    song.monthlyStreams = (song.yearlyStreams * 0.1).round();
    song.weeklyStreams = (song.monthlyStreams * 0.3).round();
    song.dailyStreams = (song.weeklyStreams * 0.2).round();
  }

  // Calculate realistic growth factor based on popularity
  double _calculateRealisticGrowthFactor(int popularity, Random random) {
    if (popularity >= 85) {
      // Viral tracks: high but volatile growth
      return 1.0 + (0.005 + (random.nextDouble() * 0.02 - 0.01));
    } else if (popularity >= 70) {
      // Popular tracks: steady growth
      return 1.0 + (0.002 + (random.nextDouble() * 0.008 - 0.004));
    } else if (popularity >= 50) {
      // Moderate tracks: slight growth or decline
      return 1.0 + (random.nextDouble() * 0.006 - 0.003);
    } else if (popularity >= 30) {
      // Emerging tracks: can have growth spurts
      return 1.0 + (random.nextDouble() * 0.01 - 0.005);
    } else {
      // Niche tracks: mostly stable or declining
      return 1.0 + (random.nextDouble() * 0.004 - 0.004);
    }
  }

  // Calculate market sentiment factor
  double _calculateMarketSentiment(Song song, Random random) {
    // Add genre-based momentum
    double genreFactor = 1.0;
    switch (song.genre.toLowerCase()) {
      case 'pop':
      case 'hip-hop':
      case 'rap':
        genreFactor = 1.0 + (random.nextDouble() * 0.004 - 0.002);
        break;
      case 'rock':
      case 'alternative':
        genreFactor = 1.0 + (random.nextDouble() * 0.002 - 0.001);
        break;
      case 'electronic':
      case 'dance':
        genreFactor = 1.0 + (random.nextDouble() * 0.006 - 0.003);
        break;
      default:
        genreFactor = 1.0 + (random.nextDouble() * 0.002 - 0.001);
    }

    // Add time-based cycles (weekends vs weekdays, etc.)
    double timeFactor = 1.0;
    final hour = DateTime.now().hour;
    if (hour >= 17 && hour <= 23) {
      // Peak listening hours
      timeFactor = 1.0 + (random.nextDouble() * 0.002);
    }

    return genreFactor * timeFactor;
  }

  // Update daily streams with volatility
  void _updateDailyStreams(Song song, double growthFactor, Random random) {
    double volatility = 0.15; // Higher volatility for daily
    double factor =
        growthFactor + (random.nextDouble() * volatility - volatility / 2);
    int newDailyStreams = (song.dailyStreams * factor).round();
    song.dailyStreams = math.max(0, newDailyStreams);
  }

  // Update weekly streams with moderate volatility
  void _updateWeeklyStreams(Song song, double growthFactor, Random random) {
    double volatility = 0.08;
    double factor =
        growthFactor + (random.nextDouble() * volatility - volatility / 2);
    int newWeeklyStreams = (song.weeklyStreams * factor).round();
    song.weeklyStreams = math.max(song.dailyStreams, newWeeklyStreams);
  }

  // Update monthly streams with low volatility
  void _updateMonthlyStreams(Song song, double growthFactor, Random random) {
    double volatility = 0.04;
    double factor =
        growthFactor + (random.nextDouble() * volatility - volatility / 2);
    int newMonthlyStreams = (song.monthlyStreams * factor).round();
    song.monthlyStreams = math.max(song.weeklyStreams, newMonthlyStreams);
  }

  // Update yearly streams with very low volatility
  void _updateYearlyStreams(Song song, double growthFactor, Random random) {
    double volatility = 0.02;
    double factor =
        growthFactor + (random.nextDouble() * volatility - volatility / 2);
    int newYearlyStreams = (song.yearlyStreams * factor).round();
    song.yearlyStreams = math.max(song.monthlyStreams * 4, newYearlyStreams);
  }

  // Update long-term streams (5 years and all-time)
  void _updateLongTermStreams(Song song, double growthFactor, Random random) {
    double volatility = 0.01;
    double factor =
        growthFactor + (random.nextDouble() * volatility - volatility / 2);

    // Five years streams
    int newFiveYearStreams = (song.lastFiveYearsStreams * factor).round();
    song.lastFiveYearsStreams = math.max(
      song.yearlyStreams,
      newFiveYearStreams,
    );

    // All-time streams (accumulative)
    int dailyGrowth = math.max(
      0,
      song.dailyStreams - (song.allTimeStreams * 0.000001).round(),
    ); // Very small daily addition
    song.allTimeStreams = math.max(
      song.lastFiveYearsStreams,
      song.allTimeStreams + dailyGrowth,
    );
  }

  // Ensure logical consistency between time periods
  void _ensureStreamConsistency(Song song) {
    // Ensure hierarchy: daily <= weekly <= monthly <= yearly <= 5years <= allTime
    song.weeklyStreams = math.max(song.dailyStreams, song.weeklyStreams);
    song.monthlyStreams = math.max(song.weeklyStreams, song.monthlyStreams);
    song.yearlyStreams = math.max(song.monthlyStreams, song.yearlyStreams);
    song.lastFiveYearsStreams = math.max(
      song.yearlyStreams,
      song.lastFiveYearsStreams,
    );
    song.allTimeStreams = math.max(
      song.lastFiveYearsStreams,
      song.allTimeStreams,
    );
  }

  /// Calculate dynamic price change threshold based on current price
  /// Higher priced songs need larger changes to be significant
  double _calculatePriceChangeThreshold(double currentPrice) {
    if (currentPrice >= 1000) {
      // High-priced songs: 1-2% change threshold
      return currentPrice * 0.015; // 1.5%
    } else if (currentPrice >= 100) {
      // Mid-priced songs: 2-3% change threshold
      return currentPrice * 0.025; // 2.5%
    } else if (currentPrice >= 20) {
      // Low-mid priced songs: 3-5% change threshold
      return currentPrice * 0.04; // 4%
    } else {
      // Very low priced songs: minimum absolute threshold
      return math.max(currentPrice * 0.05, 0.50); // 5% or $0.50 minimum
    }
  }

  /// Estimate popularity from bell curve price using inverse mapping
  /// Maps price ranges back to estimated Spotify popularity scores
  int _estimatePopularityFromBellCurvePrice(double currentPrice) {
    // Bell curve inverse mapping for new price distribution
    // Mean: $500, Std Dev: $800

    if (currentPrice >= 2500) {
      // Very high prices: 90-100 popularity (viral hits)
      double factor = math.min((currentPrice - 2500) / 2500, 1.0);
      return (90 + factor * 10).round().clamp(90, 100);
    } else if (currentPrice >= 1000) {
      // High prices: 75-89 popularity (very popular)
      double factor = (currentPrice - 1000) / 1500;
      return (75 + factor * 14).round().clamp(75, 89);
    } else if (currentPrice >= 300) {
      // Mid-high prices: 55-74 popularity (popular)
      double factor = (currentPrice - 300) / 700;
      return (55 + factor * 19).round().clamp(55, 74);
    } else if (currentPrice >= 100) {
      // Mid prices: 35-54 popularity (moderate)
      double factor = (currentPrice - 100) / 200;
      return (35 + factor * 19).round().clamp(35, 54);
    } else if (currentPrice >= 20) {
      // Low-mid prices: 15-34 popularity (emerging)
      double factor = (currentPrice - 20) / 80;
      return (15 + factor * 19).round().clamp(15, 34);
    } else {
      // Low prices: 0-14 popularity (niche)
      double factor = math.max(currentPrice / 20, 0.0);
      return (factor * 14).round().clamp(0, 14);
    }
  }

  // This previous dispose method is now replaced by the enhanced version above
  // that also handles continuous updates timer
}
