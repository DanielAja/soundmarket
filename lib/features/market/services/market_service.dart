import 'dart:async';
import 'dart:math'; // Import Random
import '../../../shared/models/song.dart';
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
  final _random = Random();

  MarketService._internal() {
    _initializeSpotifyApi();
  }

  // Initialize the Spotify API service and fetch initial data
  Future<void> _initializeSpotifyApi() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      print('Initializing MarketService with Spotify data...');
      // Fetch initial songs from Spotify
      final apiSongs = await _spotifyApi.getTopTracks(limit: 50); // Fetch 50 top tracks

      if (apiSongs.isNotEmpty) {
        _songs.clear();
        _songs.addAll(apiSongs);
        _updateCachedLists();
        _isInitialized = true; // Mark as initialized
        print('MarketService initialized successfully with ${apiSongs.length} songs.');
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

  // Start the price simulation timer
  void _startPriceSimulation() {
    _priceUpdateTimer?.cancel(); // Cancel existing timer
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulatePriceChanges();
    });
  }

  // Simulate price changes for all songs
  void _simulatePriceChanges() {
    if (_songs.isEmpty) return; // Don't simulate if no songs loaded

    bool hasUpdates = false;
    for (final song in _songs) {
      song.previousPrice = song.currentPrice; // Store previous price

      // Simulate a small price change (+/- up to 5% of current price)
      final changePercent = (_random.nextDouble() * 0.1) - 0.05; // -0.05 to +0.05
      final priceChange = song.currentPrice * changePercent;
      song.currentPrice += priceChange;

      // Ensure price doesn't go below a minimum (e.g., $1)
      if (song.currentPrice < 1.0) {
        song.currentPrice = 1.0;
      }
      hasUpdates = true;
    }

    if (hasUpdates) {
      _updateCachedLists();
      _songUpdateController.add(List.from(_songs));
    }
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

  // --- Stream Count methods removed as Spotify API doesn't provide this directly ---

  // Trigger a manual update of song prices (now just runs the simulation)
  void triggerPriceUpdate() {
    _simulatePriceChanges();
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

  // Dispose resources
  void dispose() {
    _priceUpdateTimer?.cancel(); // Cancel the timer
    _songUpdateController.close();
    // _spotifyApi.dispose(); // SpotifyApiService doesn't have a dispose method in the provided code
  }
}
