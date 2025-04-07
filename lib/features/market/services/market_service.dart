import 'dart:async';
import '../../../shared/models/song.dart'; // Corrected relative path again
import '../../../shared/services/music_data_api_service.dart'; // Corrected relative path again

class MarketService { // Renamed class
  // Singleton pattern
  static final MarketService _instance = MarketService._internal(); // Renamed class
  factory MarketService() => _instance; // Renamed class
  
  // Cached lists to maintain consistent order
  List<Song>? _cachedTopSongs;
  List<Song>? _cachedTopMovers;
  List<String>? _cachedRisingArtists;
  
  // Songs list (will be populated from API)
  final List<Song> _songs = [];
  
  // Music data API service
  final MusicDataApiService _musicDataApi = MusicDataApiService();
  
  // Stream controller for song updates
  final _songUpdateController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get songUpdates => _songUpdateController.stream;
  
  // Subscription to price updates
  StreamSubscription? _priceUpdateSubscription;
  
  MarketService._internal() { // Renamed constructor
    // Initialize with fallback data first
    _initializeFallbackData();
    
    // Then try to initialize the music data API service
    _initializeMusicDataApi();
  }
  
  // Initialize with fallback data in case API fails
  void _initializeFallbackData() {
    // Add some fallback songs if the list is empty
    if (_songs.isEmpty) {
      _songs.addAll(_getFallbackSongs());
      _updateCachedLists();
    }
  }
  
  // Initialize the music data API service
  Future<void> _initializeMusicDataApi() async {
    try {
      // Initialize the API with empty list (it will fetch data from Spotify)
      await _musicDataApi.initialize([]);
      
      // Get initial songs from API
      final apiSongs = _musicDataApi.getAllCachedSongs();
      
      // Only replace fallback data if we got songs from the API
      if (apiSongs.isNotEmpty) {
        _songs.clear();
        _songs.addAll(apiSongs);
        _updateCachedLists();
      }
      
      // Listen for price updates
      _priceUpdateSubscription = _musicDataApi.priceUpdates.listen(_updateSongPrices);
    } catch (e) {
      // print('Error initializing music data API: $e'); // Removed print
      // Fallback data is already loaded, so we don't need to do anything else
    }
  }
  
  // Get fallback songs in case API fails
  List<Song> _getFallbackSongs() {
    return [
      Song(
        id: '1',
        name: 'Blinding Lights',
        artist: 'The Weeknd',
        genre: 'Pop',
        currentPrice: 45.0,
        previousPrice: 42.5,
        albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273b5d374b3c8617f0c6c410daf',
      ),
      Song(
        id: '2',
        name: 'Levitating',
        artist: 'Dua Lipa',
        genre: 'Pop',
        currentPrice: 38.75,
        previousPrice: 40.0,
        albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273d4daf28d55fe4197ede848be',
      ),
      Song(
        id: '3',
        name: 'Save Your Tears',
        artist: 'The Weeknd',
        genre: 'Pop',
        currentPrice: 32.5,
        previousPrice: 30.0,
        albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273c6af5ffa661a365b77df6ef6',
      ),
      Song(
        id: '4',
        name: 'Montero (Call Me By Your Name)',
        artist: 'Lil Nas X',
        genre: 'Hip-Hop',
        currentPrice: 55.0,
        previousPrice: 48.0,
        albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273be82673b5f79d9658ec0a9fd',
      ),
      Song(
        id: '5',
        name: 'Peaches',
        artist: 'Justin Bieber',
        genre: 'Pop',
        currentPrice: 28.5,
        previousPrice: 30.0,
        albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273e6f407c7f3a0ec98845e4431',
      ),
    ];
  }
  
  // Update cached lists
  void _updateCachedLists() {
    // Update top songs
    final topSongs = List<Song>.from(_songs);
    // Add null checks for sorting potentially null values if necessary, though compareTo handles it.
    topSongs.sort((a, b) => (b.currentPrice ?? 0.0).compareTo(a.currentPrice ?? 0.0));
    _cachedTopSongs = topSongs;
    
    // Update top movers
    final topMovers = List<Song>.from(_songs);
    // Removed null checks as analyzer suggests they are unnecessary
    topMovers.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs())); 
    _cachedTopMovers = topMovers;
    
    // Update rising artists
    _cachedRisingArtists = _calculateRisingArtists();
  }
  
  // Update song prices based on API data
  void _updateSongPrices(Map<String, double> priceUpdates) {
    bool hasUpdates = false;
    
    // Update each song's price
    for (final song in _songs) {
      if (priceUpdates.containsKey(song.id)) {
        // Store previous price
        song.previousPrice = song.currentPrice;
        
        // Update current price
        song.currentPrice = priceUpdates[song.id]!;
        
        hasUpdates = true;
      }
    }
    
    // Notify listeners if there were updates
    if (hasUpdates) {
      _updateCachedLists();
      _songUpdateController.add(List.from(_songs));
    }
  }
  
  // Refresh data from API
  Future<void> refreshData() async {
    await _musicDataApi.refreshData();
    
    // Clear and repopulate songs list
    _songs.clear();
    _songs.addAll(_musicDataApi.getAllCachedSongs());
    
    // Update cached lists
    _updateCachedLists();
    
    // Notify listeners
    _songUpdateController.add(List.from(_songs));
  }
  
  // Get stream count for a song
  int getStreamCount(String songId) {
    return _musicDataApi.getStreamCount(songId);
  }
  
  // Get formatted stream count
  String getFormattedStreamCount(String songId) {
    return _musicDataApi.getFormattedStreamCount(songId);
  }
  
  // Trigger a manual update of song prices
  void triggerPriceUpdate() {
    _musicDataApi.triggerPriceUpdate();
  }
  
  // Search for songs
  Future<List<Song>> searchSongs(String query) async {
    return await _musicDataApi.searchSongs(query);
  }
  
  // Get new releases
  Future<List<Song>> getNewReleases() async {
    return await _musicDataApi.getNewReleases();
  }
  
  // Get all songs
  List<Song> getAllSongs() {
    return List.from(_songs);
  }
  
  // Get song by ID
  Song? getSongById(String id) {
    try {
      // Use firstWhereOrNull for better null safety if using collection package, otherwise keep try-catch
      return _songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null; // Return null if not found
    }
  }
  
  // Get top songs (by price)
  List<Song> getTopSongs({int limit = 10}) {
    if (_cachedTopSongs == null || _cachedTopSongs!.isEmpty) {
      return [];
    }
    
    return _cachedTopSongs!.take(limit).toList();
  }
  
  // Get top movers (by percentage change)
  List<Song> getTopMovers({int limit = 10}) {
    if (_cachedTopMovers == null || _cachedTopMovers!.isEmpty) {
      return [];
    }
    
    return _cachedTopMovers!.take(limit).toList();
  }
  
  // Get songs by genre
  List<Song> getSongsByGenre(String genre) {
    // Removed null check as analyzer suggests it's unnecessary
    return _songs.where((song) => song.genre.toLowerCase() == genre.toLowerCase()).toList(); 
  }
  
  // Get all genres
  List<String> getAllGenres() {
    // Filter out potential null genres before creating the set
    return _songs.map((song) => song.genre).whereType<String>().toSet().toList();
  }
  
  // Get songs by artist
  List<Song> getSongsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList(); // Assuming artist is non-null based on model
  }
  
  // Get unique artists
  List<String> getUniqueArtists() {
    // Filter out potential null artists before creating the set
    final artists = _songs.map((song) => song.artist).whereType<String>().toSet().toList();
    return artists;
  }
  
  // Calculate rising artists (helper method)
  List<String> _calculateRisingArtists() {
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
        // Removed null check as analyzer suggests it's unnecessary
        totalChange += song.priceChangePercent; 
      }
      // Avoid division by zero if songs list is empty for an artist (shouldn't happen with current logic)
      artistChanges[artist] = songs.isNotEmpty ? totalChange / songs.length : 0.0;
    });
    
    // Sort artists by average price change
    final sortedArtists = artistChanges.keys.toList();
    sortedArtists.sort((a, b) => artistChanges[b]!.compareTo(artistChanges[a]!));
    
    return sortedArtists;
  }
  
  // Get rising artists (artists with highest average price increase)
  List<String> getRisingArtists({int limit = 5}) {
    if (_cachedRisingArtists == null || _cachedRisingArtists!.isEmpty) {
      return [];
    }
    
    return _cachedRisingArtists!.take(limit).toList();
  }
  
  // Dispose resources
  void dispose() {
    _priceUpdateSubscription?.cancel();
    _songUpdateController.close();
    _musicDataApi.dispose();
  }
}
