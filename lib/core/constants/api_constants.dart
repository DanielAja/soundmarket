/// API endpoints and keys
class ApiConstants {
  // Base API endpoints
  static const String baseUrl = '/api/v1';

  // Authentication endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // User endpoints
  static const String userProfile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/profile/update';

  // Song endpoints
  static const String songs = '$baseUrl/songs';
  static const String songDetails = '$baseUrl/songs/{id}';
  static const String songPriceHistory = '$baseUrl/songs/{id}/price-history';
  static const String topSongs = '$baseUrl/songs/top';
  static const String trendingSongs = '$baseUrl/songs/trending';

  // Portfolio endpoints
  static const String portfolio = '$baseUrl/portfolio';
  static const String portfolioPerformance = '$baseUrl/portfolio/performance';

  // Transaction endpoints
  static const String transactions = '$baseUrl/transactions';
  static const String buySong = '$baseUrl/transactions/buy';
  static const String sellSong = '$baseUrl/transactions/sell';

  // Market endpoints
  static const String market = '$baseUrl/market';
  static const String marketStats = '$baseUrl/market/stats';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';

  // Content types
  static const String jsonContentType = 'application/json';

  // Error codes
  static const int unauthorizedErrorCode = 401;
  static const int forbiddenErrorCode = 403;
  static const int notFoundErrorCode = 404;
  static const int serverErrorCode = 500;

  // Spotify API
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/api/token';
  static const String spotifySearch = '$spotifyBaseUrl/search';
  static const String spotifyTracks = '$spotifyBaseUrl/tracks';
  static const String spotifyArtists = '$spotifyBaseUrl/artists';
  static const String spotifyNewReleases =
      '$spotifyBaseUrl/browse/new-releases';
  static const String spotifyRecommendations =
      '$spotifyBaseUrl/recommendations';
  static const String spotifyCategories = '$spotifyBaseUrl/browse/categories';
  static const String spotifyFeaturedPlaylists =
      '$spotifyBaseUrl/browse/featured-playlists';
}
