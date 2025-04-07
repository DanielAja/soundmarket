import 'dart:async';
// Removed duplicate import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/environment_config.dart'; // Corrected path
import '../../core/constants/api_constants.dart'; // Corrected path
import '../models/song.dart';

class SpotifyApiService {
  // Singleton pattern
  static final SpotifyApiService _instance = SpotifyApiService._internal();
  factory SpotifyApiService() => _instance;
  SpotifyApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();
  
  // Authentication token
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Get access token
  Future<String> _getAccessToken() async {
    try {
      // Check if token is still valid
      if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        return _accessToken!;
      }
      
      // Get client credentials from environment config
      final clientId = EnvironmentConfig.settings['spotifyClientId'];
      final clientSecret = EnvironmentConfig.settings['spotifyClientSecret'];
      
      // Check if credentials are set
      if (clientId.isEmpty || clientSecret.isEmpty) {
        throw Exception('Spotify API credentials not set in EnvironmentConfig');
      }
      
      // Encode credentials
      final credentials = base64.encode(utf8.encode('$clientId:$clientSecret'));
      
      // Request token
      final response = await _client.post(
        Uri.parse(ApiConstants.spotifyAuthUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        return _accessToken!;
      } else {
        print('Failed to get Spotify access token. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to get Spotify access token: ${response.body}');
      }
    } catch (e) {
      print('Error getting Spotify access token: $e');
      rethrow;
    }
  }
  
  // Make authenticated request to Spotify API
  Future<dynamic> _makeRequest(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final token = await _getAccessToken();
      
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Spotify API error. Status: ${response.statusCode}, Endpoint: $endpoint, Body: ${response.body}');
        throw Exception('Spotify API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error making Spotify API request to $endpoint: $e');
      rethrow;
    }
  }
  
  // Get top tracks using search API with a simpler approach
  Future<List<Song>> getTopTracks({int limit = 50}) async {
    try {
      // Use a simple search for popular music instead of artist-specific search
      print('Using simplified search API to get top tracks...');
      
      // Search for popular tracks using a generic term
      final searchData = await _makeRequest(
        ApiConstants.spotifySearch,
        queryParams: {
          'q': 'year:2023-2024', // Recent tracks
          'type': 'track',
          'limit': limit.toString(),
        },
      );
      
      // If we get no results, try a different approach
      if (searchData['tracks']['items'].isEmpty) {
        print('No tracks found with year search, trying popular term...');
        final fallbackData = await _makeRequest(
          ApiConstants.spotifySearch,
          queryParams: {
            'q': 'popular', // Generic term that should return results
            'type': 'track',
            'limit': limit.toString(),
          },
        );
        
        return _processTrackResults(fallbackData);
      }
      
      return _processTrackResults(searchData);
    } catch (e) {
      print('Error fetching top tracks: $e');
      
      // Try an even simpler approach as last resort
      try {
        print('Trying last resort approach to get tracks...');
        final lastResortData = await _makeRequest(
          ApiConstants.spotifySearch,
          queryParams: {
            'q': 'a', // Very generic search that should return something
            'type': 'track',
            'limit': limit.toString(),
          },
        );
        
        return _processTrackResults(lastResortData);
      } catch (finalError) {
        print('All approaches failed: $finalError');
        return [];
      }
    }
  }
  
  // Helper method to process track results
  List<Song> _processTrackResults(Map<String, dynamic> data) {
    final List<dynamic> items = data['tracks']['items'];
    
    if (items.isEmpty) {
      print('Warning: Received empty items list from Spotify API');
      return [];
    }
    
    print('Successfully retrieved ${items.length} tracks from Spotify API');
    
    return items.map((track) => Song(
      id: track['id'],
      name: track['name'],
      artist: track['artists'][0]['name'],
      genre: _getGenreFromPopularity(track['popularity']),
      currentPrice: _calculatePrice(track['popularity']),
      previousPrice: 0.0,
      albumArtUrl: track['album']['images'][0]['url'],
    )).toList();
  }
  
  // Search for tracks
  Future<List<Song>> searchTracks(String query, {int limit = 20}) async {
    try {
      final data = await _makeRequest(
        ApiConstants.spotifySearch,
        queryParams: {
          'q': query,
          'type': 'track',
          'limit': limit.toString(),
        },
      );
      
      return _processTrackResults(data);
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }
  
  // Get new releases
  Future<List<Song>> getNewReleases({int limit = 20}) async {
    try {
      final data = await _makeRequest(
        ApiConstants.spotifyNewReleases,
        queryParams: {
          'limit': limit.toString(),
        },
      );
      
      final List<dynamic> albums = data['albums']['items'];
      final List<Song> songs = [];
      
      for (var album in albums) {
        // For each album, get its tracks
        final albumData = await _makeRequest('${album['href']}');
        final List<dynamic> tracks = albumData['tracks']['items'];
        
        if (tracks.isNotEmpty) {
          final track = tracks[0]; // Get the first track from the album
          
          // Get artist details to estimate popularity if album popularity is not available
          final popularity = album['popularity'] ?? 
              await _getArtistPopularity(album['artists'][0]['id']) ?? 
              50; // Default to 50 if not available
          
          songs.add(Song(
            id: track['id'],
            name: track['name'],
            artist: album['artists'][0]['name'],
            genre: _getGenreFromPopularity(popularity),
            currentPrice: _calculatePrice(popularity),
            previousPrice: 0.0,
            albumArtUrl: album['images'][0]['url'],
          ));
        }
      }
      
      return songs;
    } catch (e) {
      print('Error getting new releases: $e');
      return [];
    }
  }
  
  // Get artist popularity
  Future<int?> _getArtistPopularity(String artistId) async {
    try {
      final data = await _makeRequest('${ApiConstants.spotifyArtists}/$artistId');
      return data['popularity'];
    } catch (e) {
      print('Error getting artist popularity: $e');
      return null;
    }
  }
  
  // Calculate price based on popularity
  double _calculatePrice(int popularity) {
    // Convert popularity (0-100) to a price between $10 and $100
    return 10.0 + (popularity * 0.9);
  }
  
  // Assign genre based on popularity (since Spotify doesn't provide genre per track)
  String _getGenreFromPopularity(int popularity) {
    if (popularity >= 80) {
      return 'Pop';
    } else if (popularity >= 70) {
      return 'Hip-Hop';
    } else if (popularity >= 60) {
      return 'R&B';
    } else if (popularity >= 50) {
      return 'Rock';
    } else if (popularity >= 40) {
      return 'Electronic';
    } else if (popularity >= 30) {
      return 'Indie';
    } else if (popularity >= 20) {
      return 'Jazz';
    } else {
      return 'Classical';
    }
  }
  
  // Get track details including audio features
  Future<Map<String, dynamic>> getTrackDetails(String trackId) async {
    try {
      final trackData = await _makeRequest('${ApiConstants.spotifyTracks}/$trackId');
      final audioFeatures = await _makeRequest('${ApiConstants.spotifyBaseUrl}/audio-features/$trackId');
      
      return {
        'track': trackData,
        'audioFeatures': audioFeatures,
      };
    } catch (e) {
      print('Error getting track details: $e');
      return {};
    }
  }
  
  // Dispose resources
  void dispose() {
    _client.close();
  }
}
