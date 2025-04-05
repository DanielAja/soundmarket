import 'dart:async';
import '../models/song.dart';
import 'music_data_api_service.dart';

class SongService {
  // Singleton pattern
  static final SongService _instance = SongService._internal();
  factory SongService() => _instance;
  
  // Cached lists to maintain consistent order
  List<Song>? _cachedTopSongs;
  List<Song>? _cachedTopMovers;
  
  SongService._internal() {
    // Initialize the music data API service
    _initializeMusicDataApi();
    
    // Initialize the cached lists
    final topSongs = List<Song>.from(_songs);
    topSongs.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    _cachedTopSongs = topSongs.take(10).toList();
    
    final topMovers = List<Song>.from(_songs);
    topMovers.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()));
    _cachedTopMovers = topMovers.take(10).toList();
  }
  
  // Music data API service
  final MusicDataApiService _musicDataApi = MusicDataApiService();
  
  // Stream controller for song updates
  final _songUpdateController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get songUpdates => _songUpdateController.stream;
  
  // Subscription to price updates
  StreamSubscription? _priceUpdateSubscription;
  
  // Initialize the music data API service
  void _initializeMusicDataApi() {
    // Initialize the API with our songs
    _musicDataApi.initialize(_songs);
    
    // Listen for price updates
    _priceUpdateSubscription = _musicDataApi.priceUpdates.listen(_updateSongPrices);
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
      // Don't clear the cached lists - we want to maintain the same order
      // even when prices change
      _songUpdateController.add(List.from(_songs));
    }
  }
  
  // Get stream count for a song
  int getStreamCount(String songId) {
    return _musicDataApi.getStreamCount(songId);
  }
  
  // Get formatted stream count
  String getFormattedStreamCount(String songId) {
    return _musicDataApi.getFormattedStreamCount(songId);
  }
  
  // Dispose resources
  void dispose() {
    _priceUpdateSubscription?.cancel();
    _songUpdateController.close();
    _musicDataApi.dispose();
  }
  
  // Mock song data
  final List<Song> _songs = [
    Song(
      id: '1',
      name: 'Blinding Lights',
      artist: 'The Weeknd',
      genre: 'Pop',
      currentPrice: 45.0,
      previousPrice: 42.5,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '2',
      name: 'Levitating',
      artist: 'Dua Lipa',
      genre: 'Pop',
      currentPrice: 38.75,
      previousPrice: 40.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '3',
      name: 'Save Your Tears',
      artist: 'The Weeknd',
      genre: 'Pop',
      currentPrice: 32.5,
      previousPrice: 30.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '4',
      name: 'Montero (Call Me By Your Name)',
      artist: 'Lil Nas X',
      genre: 'Hip-Hop',
      currentPrice: 55.0,
      previousPrice: 48.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '5',
      name: 'Peaches',
      artist: 'Justin Bieber',
      genre: 'Pop',
      currentPrice: 28.5,
      previousPrice: 30.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '6',
      name: 'Leave The Door Open',
      artist: 'Silk Sonic',
      genre: 'R&B',
      currentPrice: 42.0,
      previousPrice: 38.5,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '7',
      name: 'Drivers License',
      artist: 'Olivia Rodrigo',
      genre: 'Pop',
      currentPrice: 60.0,
      previousPrice: 52.5,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '8',
      name: 'Good 4 U',
      artist: 'Olivia Rodrigo',
      genre: 'Pop Rock',
      currentPrice: 58.25,
      previousPrice: 55.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '9',
      name: 'Kiss Me More',
      artist: 'Doja Cat ft. SZA',
      genre: 'Pop',
      currentPrice: 35.75,
      previousPrice: 33.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '10',
      name: 'Astronaut In The Ocean',
      artist: 'Masked Wolf',
      genre: 'Hip-Hop',
      currentPrice: 25.0,
      previousPrice: 28.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '11',
      name: 'Butter',
      artist: 'BTS',
      genre: 'K-Pop',
      currentPrice: 65.0,
      previousPrice: 58.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '12',
      name: 'Mood',
      artist: '24kGoldn ft. iann dior',
      genre: 'Hip-Hop',
      currentPrice: 30.0,
      previousPrice: 32.5,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '13',
      name: 'Heartbreak Anniversary',
      artist: 'Giveon',
      genre: 'R&B',
      currentPrice: 40.0,
      previousPrice: 35.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '14',
      name: 'Deja Vu',
      artist: 'Olivia Rodrigo',
      genre: 'Pop',
      currentPrice: 48.0,
      previousPrice: 45.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
    Song(
      id: '15',
      name: 'Dynamite',
      artist: 'BTS',
      genre: 'K-Pop',
      currentPrice: 62.5,
      previousPrice: 60.0,
      albumArtUrl: null, // Using null instead of placeholder URL to avoid network errors
    ),
  ];

  // Get all songs
  List<Song> getAllSongs() {
    return List.from(_songs);
  }
  
  // Get song by ID
  Song? getSongById(String id) {
    try {
      return _songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get top songs (by price)
  List<Song> getTopSongs({int limit = 10}) {
    // If we already have a cached list, return it
    if (_cachedTopSongs != null) {
      return _cachedTopSongs!;
    }
    
    // Otherwise, create and cache a new sorted list
    final sortedSongs = List<Song>.from(_songs);
    sortedSongs.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    _cachedTopSongs = sortedSongs.take(limit).toList();
    return _cachedTopSongs!;
  }
  
  // Get top movers (by percentage change)
  List<Song> getTopMovers({int limit = 10}) {
    // If we already have a cached list, return it
    if (_cachedTopMovers != null) {
      return _cachedTopMovers!;
    }
    
    // Otherwise, create and cache a new sorted list
    final sortedSongs = List<Song>.from(_songs);
    sortedSongs.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()));
    _cachedTopMovers = sortedSongs.take(limit).toList();
    return _cachedTopMovers!;
  }
  
  // Get songs by genre
  List<Song> getSongsByGenre(String genre) {
    return _songs.where((song) => song.genre.toLowerCase() == genre.toLowerCase()).toList();
  }
  
  // Get all genres
  List<String> getAllGenres() {
    return _songs.map((song) => song.genre).toSet().toList();
  }
  
  // Get songs by artist
  List<Song> getSongsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }
  
  // Get unique artists
  List<String> getUniqueArtists() {
    final artists = _songs.map((song) => song.artist).toSet().toList();
    return artists;
  }
  
  // Get rising artists (artists with highest average price increase)
  List<String> getRisingArtists({int limit = 5}) {
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
      artistChanges[artist] = totalChange / songs.length;
    });
    
    // Sort artists by average price change
    final sortedArtists = artistChanges.keys.toList();
    sortedArtists.sort((a, b) => artistChanges[b]!.compareTo(artistChanges[a]!));
    
    return sortedArtists.take(limit).toList();
  }
}
