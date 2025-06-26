import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/environment_config.dart'; // Corrected path
import '../../core/constants/api_constants.dart'; // Corrected path
import '../models/song.dart';

// Batch request class for handling multiple track requests
class _BatchRequest {
  final String trackId;
  final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();
  final DateTime createdAt = DateTime.now();

  _BatchRequest(this.trackId);
}

class SpotifyApiService {
  // Singleton pattern
  static final SpotifyApiService _instance = SpotifyApiService._internal();
  factory SpotifyApiService() => _instance;

  // HTTP client
  final http.Client _client = http.Client();

  // Authentication token
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Rate limiting
  final int _maxRequestsPerSecond =
      2; // Spotify allows ~100 requests per 30 seconds, being conservative
  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  final int _retryAfterMs = 1000; // Wait 1 second before retrying
  final int _maxRetries = 3; // Maximum number of retries for a request

  // Batch request cache
  final Map<String, Map<String, dynamic>> _trackDetailsCache = {};
  final Duration _cacheDuration = Duration(
    minutes: 30,
  ); // Cache track details for 30 mins

  // Request queue for batch processing
  final List<_BatchRequest> _batchQueue = [];
  Timer? _batchTimer;
  bool _processingBatch = false;

  SpotifyApiService._internal() {
    // Start the batch processor
    _startBatchProcessor();
  }

  // Start the batch processor timer
  void _startBatchProcessor() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _processBatchQueue();
    });
  }

  // Get access token
  Future<String> _getAccessToken() async {
    try {
      // Check if token is still valid
      if (_accessToken != null &&
          _tokenExpiry != null &&
          _tokenExpiry!.isAfter(DateTime.now())) {
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
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in']),
        );
        return _accessToken!;
      } else {
        print(
          'Failed to get Spotify access token. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to get Spotify access token: ${response.body}');
      }
    } catch (e) {
      print('Error getting Spotify access token: $e');
      rethrow;
    }
  }

  // Check if we can make a request based on rate limits
  Future<bool> _canMakeRequest() async {
    final now = DateTime.now();

    // Remove timestamps older than 1 second
    while (_requestTimestamps.isNotEmpty &&
        now.difference(_requestTimestamps.first).inMilliseconds > 1000) {
      _requestTimestamps.removeFirst();
    }

    // Check if we've reached the limit
    return _requestTimestamps.length < _maxRequestsPerSecond;
  }

  // Wait until we can make a request
  Future<void> _waitForRateLimit() async {
    int attempts = 0;
    while (!(await _canMakeRequest())) {
      attempts++;
      if (attempts > 10) {
        // Avoid infinite loop
        print(
          'Rate limit wait timed out after 10 attempts. Proceeding anyway.',
        );
        break;
      }
      await Future.delayed(Duration(milliseconds: _retryAfterMs));
    }

    // Record this timestamp
    _requestTimestamps.add(DateTime.now());
  }

  // Make authenticated request to Spotify API with rate limiting and retries
  Future<dynamic> _makeRequest(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    int retryCount = 0,
  }) async {
    try {
      // Wait for rate limit before making request
      await _waitForRateLimit();

      final token = await _getAccessToken();
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 429 && retryCount < _maxRetries) {
        // Handle rate limiting - extract Retry-After header if available
        final retryAfter = response.headers['retry-after'];
        int waitTime =
            retryAfter != null
                ? int.parse(retryAfter) * 1000
                : _retryAfterMs * (retryCount + 1);

        print(
          'Rate limited (429). Waiting ${waitTime}ms before retry ${retryCount + 1}/${_maxRetries}',
        );
        await Future.delayed(Duration(milliseconds: waitTime));

        // Retry the request with incremented retry count
        return _makeRequest(
          endpoint,
          queryParams: queryParams,
          retryCount: retryCount + 1,
        );
      } else {
        print(
          'Spotify API error. Status: ${response.statusCode}, Endpoint: $endpoint, Body: ${response.body}',
        );
        throw Exception(
          'Spotify API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error making Spotify API request to $endpoint: $e');
      if (e.toString().contains('429') && retryCount < _maxRetries) {
        // Additional retry for general 429 errors
        print('Retrying due to rate limit error...');
        await Future.delayed(
          Duration(milliseconds: _retryAfterMs * (retryCount + 1)),
        );
        return _makeRequest(
          endpoint,
          queryParams: queryParams,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  // The batch request object is now defined outside the class

  // Process batched requests
  Future<void> _processBatchQueue() async {
    if (_batchQueue.isEmpty || _processingBatch) return;

    _processingBatch = true;

    try {
      // Process up to 10 requests at a time
      final batch = _batchQueue.take(10).toList();
      _batchQueue.removeRange(
        0,
        batch.length > _batchQueue.length ? _batchQueue.length : batch.length,
      );

      print('Processing batch of ${batch.length} track requests');

      // Group by batch of 5 to avoid overwhelming the API
      for (int i = 0; i < batch.length; i += 5) {
        final end = i + 5 > batch.length ? batch.length : i + 5;
        final currentBatch = batch.sublist(i, end);

        await Future.wait(
          currentBatch.map((request) async {
            try {
              // Check cache first
              if (_trackDetailsCache.containsKey(request.trackId)) {
                final cachedData = _trackDetailsCache[request.trackId];
                final cacheTime = cachedData!['cacheTime'] as DateTime;

                if (DateTime.now().difference(cacheTime) < _cacheDuration) {
                  // Cache is fresh, use it
                  request.completer.complete(cachedData);
                  return;
                } else {
                  // Cache expired, remove it
                  _trackDetailsCache.remove(request.trackId);
                }
              }

              // Fetch from API
              final data = await _makeRequest(
                '${ApiConstants.spotifyTracks}/${request.trackId}',
              );

              final result = {'track': data, 'cacheTime': DateTime.now()};

              // Cache the result
              _trackDetailsCache[request.trackId] = result;

              // Complete the request
              request.completer.complete(result);
            } catch (e) {
              print(
                'Error processing batch request for track ${request.trackId}: $e',
              );
              request.completer.completeError(e);
            }
          }),
        );

        // Small delay between batch groups to avoid rate limiting
        if (end < batch.length) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } finally {
      _processingBatch = false;
    }
  }

  // Get top tracks with preview URLs only
  Future<List<Song>> getTopTracksWithPreviews({int limit = 50}) async {
    try {
      // Fetch more tracks than needed to account for filtering
      final allTracks = await getTopTracks(limit: limit * 3);

      // Filter only tracks with preview URLs
      final tracksWithPreviews =
          allTracks
              .where(
                (song) =>
                    song.previewUrl != null && song.previewUrl!.isNotEmpty,
              )
              .toList();

      // Return up to the requested limit
      final result = tracksWithPreviews.take(limit).toList();
      print(
        '🎵 Filtered ${result.length} playable tracks from ${allTracks.length} total tracks',
      );

      return result;
    } catch (e) {
      print('Error fetching tracks with previews: $e');
      return [];
    }
  }

  // Get top tracks using search API with a more comprehensive approach
  Future<List<Song>> getTopTracks({int limit = 50}) async {
    try {
      // Use a more comprehensive approach to get a diverse set of popular tracks
      print('Using enhanced search API to get diverse top tracks...');

      // Search parameters for diversity
      final searchParams = [
        'year:2023-2024', // Recent tracks
        'tag:new', // New releases
        'tag:hipster', // Less mainstream tracks for diversity
      ];

      final songs = <Song>[];
      final trackIds = <String>{}; // Set to avoid duplicates

      // Determine how many tracks to fetch per query to reach the limit
      final perQueryLimit = (limit / searchParams.length).ceil();

      // Make multiple requests with different search parameters for diversity
      for (final param in searchParams) {
        try {
          final searchData = await _makeRequest(
            ApiConstants.spotifySearch,
            queryParams: {
              'q': param,
              'type': 'track',
              'limit': perQueryLimit.toString(),
            },
          );

          if (searchData['tracks'] != null &&
              searchData['tracks']['items'].isNotEmpty) {
            final paramSongs = _processTrackResults(searchData);
            for (final song in paramSongs) {
              if (!trackIds.contains(song.id)) {
                songs.add(song);
                trackIds.add(song.id);
              }
            }
          }
        } catch (queryError) {
          print('Error with query "$param": $queryError');
          // Continue with other queries even if one fails
        }
      }

      // If we still need more tracks to reach the limit, use more generic searches
      if (songs.length < limit) {
        print(
          'Not enough tracks found with specific queries, trying generic search...',
        );
        try {
          // Use term searches for popular genres to fill remaining slots
          final popularGenres = ['pop', 'hip hop', 'rock', 'electronic', 'r&b'];
          final remainingLimit = limit - songs.length;
          final perGenreLimit = (remainingLimit / popularGenres.length).ceil();

          for (final genre in popularGenres) {
            try {
              final genreData = await _makeRequest(
                ApiConstants.spotifySearch,
                queryParams: {
                  'q': 'genre:$genre',
                  'type': 'track',
                  'limit': perGenreLimit.toString(),
                },
              );

              if (genreData['tracks'] != null &&
                  genreData['tracks']['items'].isNotEmpty) {
                final genreSongs = _processTrackResults(genreData);
                for (final song in genreSongs) {
                  if (!trackIds.contains(song.id)) {
                    songs.add(song);
                    trackIds.add(song.id);
                    // Break early if we've reached the limit
                    if (songs.length >= limit) break;
                  }
                }
              }

              // Break outer loop if we've reached the limit
              if (songs.length >= limit) break;
            } catch (genreError) {
              print('Error with genre "$genre": $genreError');
              // Continue with other genres even if one fails
            }
          }
        } catch (fallbackError) {
          print('Error in genre-based fallback: $fallbackError');
        }
      }

      // Last resort: If we still don't have enough tracks, use a very generic search
      if (songs.isEmpty) {
        print(
          'No tracks found with any specific search, trying generic term...',
        );
        final lastResortData = await _makeRequest(
          ApiConstants.spotifySearch,
          queryParams: {
            'q': 'popular', // Very generic search that should return something
            'type': 'track',
            'limit': limit.toString(),
          },
        );

        return _processTrackResults(lastResortData);
      }

      print('Successfully fetched ${songs.length} diverse tracks');
      return songs;
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

    // Debug: Count tracks with preview URLs
    int tracksWithPreview = 0;
    int tracksWithoutPreview = 0;

    final songs =
        items.map((track) {
          final int popularity = track['popularity'] ?? 50;
          final String? previewUrl = track['preview_url'];

          // Debug: Count preview URLs
          if (previewUrl != null && previewUrl.isNotEmpty) {
            tracksWithPreview++;
          } else {
            tracksWithoutPreview++;
          }

          // Simulate stream counts based on popularity
          // Using popularity as a base and adding some randomness
          final random = math.Random();

          // Total streams: For very popular songs (80+), millions of streams, for less popular, thousands
          final baseStreams =
              popularity >= 80
                  ? 10000000
                  : (popularity >= 50 ? 1000000 : 100000);
          final totalStreams =
              (baseStreams * (0.5 + random.nextDouble())).round();

          // Yearly streams: 60-80% of total streams
          final yearlyStreams =
              (totalStreams * (0.6 + (random.nextDouble() * 0.2))).round();

          // Monthly streams: 5-15% of total streams
          final monthlyStreams =
              (totalStreams * (0.05 + (random.nextDouble() * 0.1))).round();

          // Weekly streams: 1-3% of total streams
          final weeklyStreams =
              (totalStreams * (0.01 + (random.nextDouble() * 0.02))).round();

          // Daily streams: 0.1-0.5% of total streams
          final dailyStreams =
              (totalStreams * (0.001 + (random.nextDouble() * 0.004))).round();

          return Song(
            id: track['id'],
            name: track['name'],
            artist: track['artists'][0]['name'],
            genre: _getGenreFromPopularity(popularity),
            currentPrice: _calculatePrice(popularity),
            previousPrice: 0.0,
            albumArtUrl:
                track['album']['images'].isNotEmpty
                    ? track['album']['images'][0]['url']
                    : null,
            previewUrl: previewUrl,
            spotifyExternalUrl: track['external_urls']?['spotify'],
            totalStreams: totalStreams,
            yearlyStreams: yearlyStreams,
            monthlyStreams: monthlyStreams,
            weeklyStreams: weeklyStreams,
            dailyStreams: dailyStreams,
          );
        }).toList();

    // Debug: Log preview URL statistics
    print(
      'Preview URL Stats: $tracksWithPreview with preview, $tracksWithoutPreview without preview',
    );
    final percentage =
        tracksWithPreview > 0
            ? (tracksWithPreview /
                    (tracksWithPreview + tracksWithoutPreview) *
                    100)
                .round()
            : 0;
    print(
      'Preview availability: $percentage% of tracks have playable previews',
    );

    // Filter and prioritize songs with preview URLs
    final songsWithPreview =
        songs
            .where(
              (song) => song.previewUrl != null && song.previewUrl!.isNotEmpty,
            )
            .toList();

    final songsWithoutPreview =
        songs
            .where(
              (song) => song.previewUrl == null || song.previewUrl!.isEmpty,
            )
            .toList();

    // Return songs with preview URLs first, then others if needed
    final prioritizedSongs = [...songsWithPreview, ...songsWithoutPreview];

    print(
      '🎵 Returning ${songsWithPreview.length} playable songs first, ${songsWithoutPreview.length} non-playable songs after',
    );

    return prioritizedSongs;
  }

  // Search for tracks
  Future<List<Song>> searchTracks(String query, {int limit = 20}) async {
    try {
      final data = await _makeRequest(
        ApiConstants.spotifySearch,
        queryParams: {'q': query, 'type': 'track', 'limit': limit.toString()},
      );

      return _processTrackResults(data);
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }

  // Get new releases with market support
  Future<List<Song>> getNewReleases({int limit = 20, String? market}) async {
    try {
      final queryParams = {'limit': limit.toString()};
      if (market != null) {
        queryParams['market'] = market;
      }

      final data = await _makeRequest(
        ApiConstants.spotifyNewReleases,
        queryParams: queryParams,
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
          final popularity =
              album['popularity'] ??
              await _getArtistPopularity(album['artists'][0]['id']) ??
              50; // Default to 50 if not available

          // Simulate stream counts based on popularity
          final random = math.Random();

          // Total streams: For very popular songs (80+), millions of streams, for less popular, thousands
          final baseStreams =
              popularity >= 80
                  ? 10000000
                  : (popularity >= 50 ? 1000000 : 100000);
          final totalStreams =
              (baseStreams * (0.5 + random.nextDouble())).round();

          // Yearly streams: 60-80% of total streams
          final yearlyStreams =
              (totalStreams * (0.6 + (random.nextDouble() * 0.2))).round();

          // Monthly streams: 5-15% of total streams
          final monthlyStreams =
              (totalStreams * (0.05 + (random.nextDouble() * 0.1))).round();

          // Weekly streams: 1-3% of total streams
          final weeklyStreams =
              (totalStreams * (0.01 + (random.nextDouble() * 0.02))).round();

          // Daily streams: 0.1-0.5% of total streams
          final dailyStreams =
              (totalStreams * (0.001 + (random.nextDouble() * 0.004))).round();

          songs.add(
            Song(
              id: track['id'],
              name: track['name'],
              artist: album['artists'][0]['name'],
              genre: _getGenreFromPopularity(popularity),
              currentPrice: _calculatePrice(popularity),
              previousPrice: 0.0,
              albumArtUrl: album['images'][0]['url'],
              previewUrl: track['preview_url'],
              spotifyExternalUrl: track['external_urls']?['spotify'],
              totalStreams: totalStreams,
              yearlyStreams: yearlyStreams,
              monthlyStreams: monthlyStreams,
              weeklyStreams: weeklyStreams,
              dailyStreams: dailyStreams,
            ),
          );
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
      final data = await _makeRequest(
        '${ApiConstants.spotifyArtists}/$artistId',
      );
      return data['popularity'];
    } catch (e) {
      print('Error getting artist popularity: $e');
      return null;
    }
  }

  // Calculate price based on popularity with new range $10-$1000
  double _calculatePrice(int popularity) {
    // Convert popularity (0-100) to a price between $10 and $1000
    // Formula: base price ($10) + exponential scaling factor based on popularity
    // Popular songs (80-100): $500-$1000
    // Mid-tier songs (40-79): $50-$400
    // Niche songs (0-39): $10-$45

    if (popularity >= 80) {
      // High popularity - premium pricing with higher range
      // Exponential formula for top tier: starts at ~$500 and scales up to $1000
      return 10.0 +
          (math.pow(popularity - 79, 2) * 0.5); // $500-$1000 for popular songs
    } else if (popularity >= 40) {
      // Medium popularity - standard pricing
      return 10.0 +
          (popularity * popularity * 0.12); // $50-$400 for mid-tier songs
    } else {
      // Lower popularity - value pricing
      return 10.0 + (popularity * 0.9); // $10-$45 for niche songs
    }
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

  // Get track details using batch processing system
  Future<Map<String, dynamic>> getTrackDetails(String trackId) async {
    try {
      // Check cache first to avoid even queueing the request
      if (_trackDetailsCache.containsKey(trackId)) {
        final cachedData = _trackDetailsCache[trackId]!;
        final cacheTime = cachedData['cacheTime'] as DateTime;

        if (DateTime.now().difference(cacheTime) < _cacheDuration) {
          // Return cached data if it's still fresh
          return cachedData;
        } else {
          // Remove expired data from cache
          _trackDetailsCache.remove(trackId);
        }
      }

      // Create a new batch request
      final request = _BatchRequest(trackId);
      _batchQueue.add(request);

      // Process batch immediately if there are many pending requests
      if (_batchQueue.length >= 10 && !_processingBatch) {
        _processBatchQueue();
      }

      // Wait for the request to complete
      final result = await request.completer.future;
      return result;
    } catch (e) {
      print('Error getting track details: $e');
      return {};
    }
  }

  // Get track details for multiple tracks at once
  Future<Map<String, Map<String, dynamic>>> getTrackDetailsBatch(
    List<String> trackIds,
  ) async {
    final results = <String, Map<String, dynamic>>{};
    final futures = <Future>[];

    // Process all track IDs
    for (final trackId in trackIds) {
      futures.add(
        getTrackDetails(trackId).then((result) {
          if (result.isNotEmpty) {
            results[trackId] = result;
          }
        }),
      );
    }

    // Wait for all requests to complete
    await Future.wait(futures);
    return results;
  }

  // Get top tracks for specific country using charts/top lists
  Future<List<Song>> getTopTracksForCountry({
    int limit = 50,
    String? market,
  }) async {
    try {
      // Since Spotify doesn't provide country-specific top tracks directly,
      // we'll use search with market parameter and sort by popularity
      final queryParams = {
        'q': 'year:2023-2024', // Recent popular tracks
        'type': 'track',
        'limit': limit.toString(),
      };

      if (market != null) {
        queryParams['market'] = market;
      }

      final data = await _makeRequest(
        ApiConstants.spotifySearch,
        queryParams: queryParams,
      );

      final tracks = _processTrackResults(data);

      // Sort by popularity (descending)
      tracks.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));

      return tracks.take(limit).toList();
    } catch (e) {
      print('Error getting top tracks for country: $e');
      return [];
    }
  }

  // Get featured playlists for country (proxy for trending content)
  Future<List<Map<String, dynamic>>> getFeaturedPlaylists({
    int limit = 5,
    String? market,
  }) async {
    try {
      final queryParams = {'limit': limit.toString()};
      if (market != null) {
        queryParams['market'] = market;
      }

      final data = await _makeRequest(
        ApiConstants.spotifyFeaturedPlaylists,
        queryParams: queryParams,
      );

      final List<dynamic> playlists = data['playlists']['items'];
      return playlists
          .map(
            (playlist) => {
              'id': playlist['id'],
              'name': playlist['name'],
              'description': playlist['description'],
              'image':
                  playlist['images'].isNotEmpty
                      ? playlist['images'][0]['url']
                      : null,
            },
          )
          .toList();
    } catch (e) {
      print('Error getting featured playlists: $e');
      return [];
    }
  }

  // Get tracks from a specific playlist
  Future<List<Song>> getPlaylistTracks(
    String playlistId, {
    int limit = 10,
  }) async {
    try {
      final data = await _makeRequest(
        '${ApiConstants.spotifyBaseUrl}/playlists/$playlistId/tracks',
        queryParams: {'limit': limit.toString()},
      );

      final List<dynamic> items = data['items'];
      final songs = <Song>[];

      for (var item in items) {
        final track = item['track'];
        if (track == null || track['id'] == null) continue;

        final int popularity = track['popularity'] ?? 50;
        final random = math.Random();

        // Simulate stream counts based on popularity
        final baseStreams =
            popularity >= 80 ? 10000000 : (popularity >= 50 ? 1000000 : 100000);
        final totalStreams =
            (baseStreams * (0.5 + random.nextDouble())).round();
        final yearlyStreams =
            (totalStreams * (0.6 + (random.nextDouble() * 0.2))).round();
        final monthlyStreams =
            (totalStreams * (0.05 + (random.nextDouble() * 0.1))).round();
        final weeklyStreams =
            (totalStreams * (0.01 + (random.nextDouble() * 0.02))).round();
        final dailyStreams =
            (totalStreams * (0.001 + (random.nextDouble() * 0.004))).round();

        songs.add(
          Song(
            id: track['id'],
            name: track['name'],
            artist: track['artists'][0]['name'],
            genre: _getGenreFromPopularity(popularity),
            currentPrice: _calculatePrice(popularity),
            previousPrice: 0.0,
            albumArtUrl:
                track['album']['images'].isNotEmpty
                    ? track['album']['images'][0]['url']
                    : null,
            previewUrl: track['preview_url'],
            spotifyExternalUrl: track['external_urls']?['spotify'],
            totalStreams: totalStreams,
            yearlyStreams: yearlyStreams,
            monthlyStreams: monthlyStreams,
            weeklyStreams: weeklyStreams,
            dailyStreams: dailyStreams,
          ),
        );
      }

      return songs;
    } catch (e) {
      print('Error getting playlist tracks: $e');
      return [];
    }
  }

  // Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _client.close();

    // Complete any pending requests with empty results
    for (final request in _batchQueue) {
      if (!request.completer.isCompleted) {
        request.completer.complete({});
      }
    }
    _batchQueue.clear();
  }
}
