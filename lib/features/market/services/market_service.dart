import 'dart:async';
import 'dart:math';
import '../../../shared/models/song.dart';
import '../../../shared/models/portfolio_item.dart'; // Import PortfolioItem
import '../../../shared/services/spotify_api_service.dart'; // Import SpotifyApiService

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

  // Spotify API service
  final SpotifyApiService _spotifyApi = SpotifyApiService();

  // Stream controller for song updates
  final _songUpdateController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get songUpdates => _songUpdateController.stream;

  // Timer for price simulation
  Timer? _priceUpdateTimer;
  // Random number generator no longer used since we rely solely on popularity data

  MarketService._internal() {
    _initializeSpotifyApi();
    // Start continuous real-time price updates immediately
    startContinuousUpdates();
  }

  // Initialize the Spotify API service and fetch initial data
  Future<void> _initializeSpotifyApi() async {
    if (_isInitialized) return; // Prevent multiple initializations

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

  // Start the price simulation timer
  void _startPriceSimulation() {
    _priceUpdateTimer?.cancel(); // Cancel existing timer
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _simulatePriceChanges();
    });
  }

  // Update song prices based on Spotify popularity and stream counts
  Future<void> _simulatePriceChanges() async {
    if (_songs.isEmpty) return; // Don't simulate if no songs loaded

    bool hasUpdates = false;
    for (final song in _songs) {
      song.previousPrice = song.currentPrice; // Store previous price

      try {
        // Get updated track details from Spotify including popularity
        final details = await _spotifyApi.getTrackDetails(song.id);
        if (details.isNotEmpty && details['track'] != null) {
          final track = details['track'];
          final int popularity = track['popularity'] ?? 50; // Default to 50 if not available
          
          // Calculate new price based directly on popularity with no random fluctuation
          song.currentPrice = _calculatePriceFromPopularity(popularity);
          
          // Ensure price doesn't go below a minimum (e.g., $1)
          if (song.currentPrice < 1.0) {
            song.currentPrice = 1.0;
          }
          
          hasUpdates = true;
        } else {
          // If we couldn't get updated data, maintain the current price
          // No random fluctuations, keep price stable until we can get updated popularity data
          hasUpdates = false;
        }
      } catch (e) {
        print('Error updating price for song ${song.name}: $e');
        // On error, maintain the current price
        // No random fluctuations, keep price stable until we can get updated popularity data
        hasUpdates = false;
      }
    }

    if (hasUpdates) {
      _updateCachedLists();
      _songUpdateController.add(List.from(_songs));
    }
  }
  
  // Continuous real-time price updates based on stream counts
  Timer? _continuousUpdateTimer;
  
  // Start continuous real-time price updates
  void startContinuousUpdates() {
    stopContinuousUpdates(); // Stop any existing timer
    
    // Update prices every 3 seconds to simulate real-time stream count changes
    _continuousUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _updatePricesBasedOnStreams();
    });
    
    print('Started continuous real-time price updates based on stream counts');
  }
  
  // Stop continuous updates
  void stopContinuousUpdates() {
    _continuousUpdateTimer?.cancel();
    _continuousUpdateTimer = null;
  }
  
  // Update prices based on simulated stream counts
  Future<void> _updatePricesBasedOnStreams() async {
    if (_songs.isEmpty) return; // Don't update if no songs loaded
    
    bool hasUpdates = false;
    
    // Update a random subset of songs (30%) to avoid updating all songs at once
    final songsToUpdate = (_songs.length * 0.3).ceil();
    final shuffledSongs = List<Song>.from(_songs)..shuffle();
    final songsSubset = shuffledSongs.take(songsToUpdate).toList();
    
    for (final song in songsSubset) {
      song.previousPrice = song.currentPrice; // Store previous price
      
      try {
        // Simulate stream count change based on song popularity
        // More popular songs get more streams on average
        final basePopularity = song.currentPrice > 50 ? 2.0 : 1.0;
        
        // Calculate stream impact (small random change based on popularity)
        // Range: -2% to +3% for popular songs, -1% to +2% for less popular songs
        final random = Random();
        final streamChange = basePopularity * (random.nextDouble() * 5 - 2) / 100;
        
        // Apply change to current price
        double newPrice = song.currentPrice * (1 + streamChange);
        
        // Ensure price doesn't drop below minimum
        if (newPrice < 1.0) {
          newPrice = 1.0;
        }
        
        // Apply price change if it's different
        if ((newPrice - song.currentPrice).abs() > 0.001) {
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
    await _initializeSpotifyApi();
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
    if (!_isInitialized) await _initializeSpotifyApi();
    return await _spotifyApi.searchTracks(query);
  }

  // Get new releases using Spotify API
  Future<List<Song>> getNewReleases() async {
     // Ensure service is initialized before fetching
    if (!_isInitialized) await _initializeSpotifyApi();
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

  // Helper method to calculate price based on popularity (similar to SpotifyApiService._calculatePrice)
  double _calculatePriceFromPopularity(int popularity) {
    // Convert popularity (0-100) to a price between $10 and $100
    // Formula: base price ($10) + scaling factor based on popularity
    // Popular songs (80-100): $82-$100
    // Mid-tier songs (40-79): $28-$81.1
    // Niche songs (0-39): $10-$27.1
    
    if (popularity >= 80) {
      // High popularity - premium pricing
      return 10.0 + (popularity * 1.1); // $82-$100 for popular songs
    } else if (popularity >= 40) {
      // Medium popularity - standard pricing
      return 10.0 + (popularity * 0.9); // $28-$81.1 for mid-tier songs
    } else {
      // Lower popularity - value pricing
      return 10.0 + (popularity * 0.7); // $10-$27.1 for niche songs
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
