import 'dart:async';
import 'dart:math';
import '../../../shared/models/song.dart';
import '../../../shared/models/portfolio_item.dart'; // Import PortfolioItem
import '../../../shared/services/spotify_api_service.dart'; // Import SpotifyApiService
import '../../../shared/services/storage_service.dart'; // Import StorageService

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
      print('Loading saved songs or initializing MarketService with Spotify data...');
      
      // First try to load songs from storage
      final savedSongs = await _storageService.loadSongs();
      
      if (savedSongs.isNotEmpty) {
        print('Loaded ${savedSongs.length} saved songs from storage.');
        _songs.clear();
        _songs.addAll(savedSongs);
        _updateCachedLists();
        _isInitialized = true;
        // Start the price simulation timer after loading saved songs
        _startPriceSimulation();
        // Notify listeners with loaded data
        _songUpdateController.add(List.from(_songs));
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
      // Fetch top popular tracks based on current trends
      final apiSongs = await _spotifyApi.getTopTracks(limit: 100); // Fetch 100 top tracks

      if (apiSongs.isNotEmpty) {
        _songs.clear();
        _songs.addAll(apiSongs);

        // Fetch additional songs in various genres for better diversity
        await _enrichWithMoreGenres();
        
        _updateCachedLists();
        _isInitialized = true; // Mark as initialized
        print('MarketService initialized successfully with ${_songs.length} songs.');
        
        // Save songs to storage
        await _storageService.saveSongs(_songs);
        print('Saved ${_songs.length} songs to storage.');
        
        // Start the price simulation timer only after successful initialization
        _startPriceSimulation();
        // Notify listeners with initial data
        _songUpdateController.add(List.from(_songs));
      } else {
        print('Warning: Spotify API returned no songs. MarketService not fully initialized.');
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
        final genreSongs = await _spotifyApi.searchTracks('genre:$genre', limit: 20);
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
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
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
      final songsToUpdate = _songs.length > 50 ? 
          _songs.sublist(0, 50) : 
          _songs;
      
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
          final int popularity = track['popularity'] ?? 50; // Default to 50 if not available
          
          // Calculate new price based directly on popularity with no random fluctuation
          song.currentPrice = _calculatePriceFromPopularity(popularity);
          
          // Ensure price doesn't go below a minimum (e.g., $1)
          if (song.currentPrice < 1.0) {
            song.currentPrice = 1.0;
          }
          
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        _updateCachedLists();
        _songUpdateController.add(List.from(_songs));
        
        // Save updated songs to storage
        try {
          await _storageService.saveSongs(_songs);
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
    _continuousUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updatePricesBasedOnStreams();
    });
    
    print('Started stabilized price updates with reduced frequency for better price stability');
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
        // Simulate stream count change based on song popularity
        // More popular songs get more streams on average but with reduced volatility
        final basePopularity = song.currentPrice > 50 ? 1.5 : 1.0;
        
        // Calculate stream impact (significantly smaller random change)
        // Range: -0.75% to +1.25% for popular songs, -0.5% to +1% for less popular songs
        final random = Random();
        final streamChange = basePopularity * (random.nextDouble() * 2 - 0.75) / 100;
        
        // Apply change to current price with dampening factor (0.8) to further reduce volatility
        double newPrice = song.currentPrice * (1 + (streamChange * 0.8));
        
        // Ensure price doesn't drop below minimum
        if (newPrice < 5.0) {
          newPrice = 5.0;
        }
        
        // Only apply price change if it exceeds minimum threshold (0.005 instead of 0.001)
        // This will ignore very small changes, further stabilizing prices
        if ((newPrice - song.currentPrice).abs() > 0.005) {
          song.currentPrice = newPrice;
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
          await _storageService.saveSongs(_songs);
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
    topMovers.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()));
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
  Future<void> loadRelatedSongsForPortfolio(List<PortfolioItem> portfolio) async {
    if (portfolio.isEmpty) return; // No portfolio items to find related songs for
    
    try {
      print('Loading songs related to user portfolio...');
      final artistsInPortfolio = portfolio.map((item) => item.artistName).toSet().toList();
      final songsInPortfolio = portfolio.map((item) => item.songId).toSet().toList();
      
      // Limit to top 5 artists to avoid too many API calls
      final topArtists = artistsInPortfolio.take(5).toList();
      
      // Create a map to avoid duplicates
      final Map<String, Song> newSongs = {};
      
      // For each artist in portfolio, find their popular songs
      for (final artist in topArtists) {
        final artistSongs = await _spotifyApi.searchTracks('artist:"$artist"', limit: 10);
        for (final song in artistSongs) {
          // Skip songs already in portfolio
          if (!songsInPortfolio.contains(song.id)) {
            newSongs[song.id] = song;
          }
        }
      }
      
      // Add similar genres based on portfolio
      final genresInPortfolio = portfolio
          .map((item) {
            final song = _songs.firstWhere(
              (s) => s.id == item.songId,
              orElse: () => Song(
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
        final genreSongs = await _spotifyApi.searchTracks('genre:"$genre"', limit: 10);
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
        final newSongsToAdd = newSongs.values.where((s) => !uniqueIds.contains(s.id)).toList();
        
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
    return _songs.where((song) => song.genre.toLowerCase() == genre.toLowerCase()).toList();
  }

  // Get all genres
  List<String> getAllGenres() {
     // Ensure service is initialized before getting genres
    // if (!_isInitialized) await _initializeSpotifyApi();
    return _songs.map((song) => song.genre).whereType<String>().toSet().toList();
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
    final artists = _songs.map((song) => song.artist).whereType<String>().toSet().toList();
    return artists;
  }

  // Helper method to calculate price based on popularity with more stability
  double _calculatePriceFromPopularity(int popularity) {
    // Convert popularity (0-100) to a price between $10 and $100
    // Formula: base price ($15) + compressed scaling factor based on popularity
    // Popular songs (80-100): $65-$75
    // Mid-tier songs (40-79): $35-$64
    // Niche songs (0-39): $15-$34
    
    if (popularity >= 80) {
      // High popularity - premium pricing with compressed range
      return 15.0 + (popularity * 0.6); // $65-$75 for popular songs
    } else if (popularity >= 40) {
      // Medium popularity - standard pricing with compressed range
      return 15.0 + (popularity * 0.5); // $35-$64 for mid-tier songs
    } else {
      // Lower popularity - value pricing with compressed range
      return 15.0 + (popularity * 0.4); // $15-$34 for niche songs
    }
  }
  
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
      artistChanges[artist] = songs.isNotEmpty ? totalChange / songs.length : 0.0;
    });

    // Sort artists by average price change
    final sortedArtists = artistChanges.keys.toList();
    sortedArtists.sort((a, b) => artistChanges[b]!.compareTo(artistChanges[a]!));

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

  // This previous dispose method is now replaced by the enhanced version above
  // that also handles continuous updates timer
}
