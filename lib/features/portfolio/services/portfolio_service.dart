import 'dart:async';
import '../../../shared/models/portfolio_item.dart'; // Corrected relative path again
import '../../../shared/models/song.dart'; // Corrected relative path again

class PortfolioService {
  // Renamed class
  // Singleton pattern
  static final PortfolioService _instance =
      PortfolioService._internal(); // Renamed class
  factory PortfolioService() => _instance; // Renamed class
  PortfolioService._internal(); // Renamed constructor

  // Stream controller for portfolio updates
  final _portfolioUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get portfolioUpdates =>
      _portfolioUpdateController.stream;

  // Timer for periodic updates
  Timer? _updateTimer;

  // Store the latest portfolio data
  List<PortfolioItem>? _latestPortfolio;
  List<Song>? _latestSongs;

  // Track price changes for visual indicators
  final Map<String, double> _previousPrices = {};

  // Initialize the service
  void initialize(List<PortfolioItem> portfolio, List<Song> songs) {
    _latestPortfolio = List.from(portfolio);
    _latestSongs = List.from(songs);

    // Store initial prices for change tracking
    _updatePreviousPrices();

    // Start periodic updates if not already running
    _startRealtimeUpdates();
  }

  // Store previous prices for change tracking
  void _updatePreviousPrices() {
    if (_latestPortfolio == null || _latestSongs == null) return;

    for (var item in _latestPortfolio!) {
      final song = _latestSongs!.firstWhere(
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

      _previousPrices[item.songId] = song.currentPrice;
    }
  }

  // Start real-time updates
  void _startRealtimeUpdates() {
    // Cancel any existing timer
    _updateTimer?.cancel();

    // Create a new timer that fires every 2 seconds for more responsive updates
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkForUpdates();
    });
  }

  // Update portfolio data
  void updatePortfolioData(List<PortfolioItem> portfolio, List<Song> songs) {
    _latestPortfolio = List.from(portfolio);
    _latestSongs = List.from(songs);

    // Check for updates immediately
    _checkForUpdates();
  }

  // Check for updates and notify listeners if there are changes
  void _checkForUpdates() {
    if (_latestPortfolio == null || _latestSongs == null) return;

    final updates = <String, Map<String, dynamic>>{};
    double totalValue = 0.0;

    for (var item in _latestPortfolio!) {
      final song = _latestSongs!.firstWhere(
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

      final currentPrice = song.currentPrice;
      final previousPrice = _previousPrices[item.songId] ?? currentPrice;
      final priceChange = currentPrice - previousPrice;
      final currentValue = item.quantity * currentPrice;

      totalValue += currentValue;

      // Only add to updates if price has changed
      if (currentPrice != previousPrice) {
        updates[item.songId] = {
          'currentPrice': currentPrice,
          'previousPrice': previousPrice,
          'priceChange': priceChange,
          'priceChangePercent': (priceChange / previousPrice) * 100,
          'currentValue': currentValue,
        };
      }
    }

    // If there are updates, notify listeners
    if (updates.isNotEmpty) {
      _portfolioUpdateController.add({
        'updates': updates,
        'totalValue': totalValue,
      });

      // Update previous prices for next comparison
      _updatePreviousPrices();
    }
  }

  // Get price change for a song (for UI indicators)
  PriceChange getPriceChange(String songId) {
    if (_latestSongs == null) return PriceChange.none;

    final song = _latestSongs!.firstWhere(
      (s) => s.id == songId,
      orElse:
          () => Song(
            id: songId,
            name: '',
            artist: '',
            genre: '',
            currentPrice: 0,
          ),
    );

    final previousPrice = _previousPrices[songId] ?? song.currentPrice;

    if (song.currentPrice > previousPrice) {
      return PriceChange.increase;
    } else if (song.currentPrice < previousPrice) {
      return PriceChange.decrease;
    } else {
      return PriceChange.none;
    }
  }

  // Force an immediate update check
  void forceUpdate() {
    _checkForUpdates();
  }

  // Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _portfolioUpdateController.close();
  }
}

// Enum for price change direction (for UI indicators)
enum PriceChange { increase, decrease, none }
