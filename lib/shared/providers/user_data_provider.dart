import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../models/transaction.dart';
import '../models/portfolio_snapshot.dart'; // Import the snapshot model
import '../services/storage_service.dart';
import '../../features/market/services/market_service.dart';
// Import the new portfolio service to potentially use its PriceChange enum if needed elsewhere
import '../../features/portfolio/services/portfolio_service.dart';


class UserDataProvider with ChangeNotifier {
  UserProfile? _userProfile;
  List<PortfolioItem> _portfolio = [];
  List<Transaction> _transactions = [];
  // List<PortfolioSnapshot> _portfolioHistory = []; // Removed: History is now in SQLite
  final StorageService _storageService = StorageService();
  final MarketService _marketService = MarketService();
  final _uuid = const Uuid();

  // Loading state
  bool _isLoading = false;
  // Removed _portfolioValueAtSessionStart as it's replaced by history

  // Subscriptions
  StreamSubscription? _songUpdateSubscription;
  StreamSubscription? _portfolioUpdateSubscription;

  // Timer for periodic history snapshots
  Timer? _snapshotTimer;

  // Portfolio service (renamed from PortfolioUpdateService)
  final PortfolioService _portfolioService = PortfolioService(); // Renamed class and variable

  // Price change indicators
  final Map<String, PriceChange> _priceChangeIndicators = {};

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<PortfolioItem> get portfolio => _portfolio;
  List<Transaction> get transactions => _transactions;
  // List<PortfolioSnapshot> get portfolioHistory => _portfolioHistory; // Removed getter
  bool get isLoading => _isLoading;

  // Helper to calculate portfolio value
  double _calculatePortfolioValue() {
    double total = 0.0;
    for (var item in _portfolio) {
      final song = _marketService.getSongById(item.songId);
      if (song != null) {
        total += item.quantity * song.currentPrice;
      } else {
        // If song not found, use purchase price as fallback
        total += item.quantity * item.purchasePrice;
      }
    }
    return total;
  }

  // Calculate total portfolio value based on current song prices
  double get totalPortfolioValue {
    // Use the helper method
    return _calculatePortfolioValue();
  }

  // Calculate total balance (cash + portfolio value)
  double get totalBalance => (_userProfile?.cashBalance ?? 0.0) + totalPortfolioValue;

  // Get all available songs
  List<Song> get allSongs => _marketService.getAllSongs(); // Renamed variable

  // Get top songs
  List<Song> get topSongs => _marketService.getTopSongs(); // Renamed variable

  // Get top songs with custom limit
  List<Song> getTopSongs({int limit = 10}) => _marketService.getTopSongs(limit: limit); // Renamed variable

  // Get top movers
  List<Song> get topMovers => _marketService.getTopMovers(); // Renamed variable

  // Get top movers with custom limit
  List<Song> getTopMovers({int limit = 10}) => _marketService.getTopMovers(limit: limit); // Renamed variable

  // Get rising artists
  List<String> get risingArtists => _marketService.getRisingArtists(); // Renamed variable

  // Get songs by genre
  List<Song> getSongsByGenre(String genre) => _marketService.getSongsByGenre(genre); // Renamed variable

  // Get all genres
  List<String> get allGenres => _marketService.getAllGenres(); // Renamed variable

  // Get songs by artist
  List<Song> getSongsByArtist(String artist) => _marketService.getSongsByArtist(artist); // Renamed variable

  UserDataProvider() {
    _loadData();
    _listenToSongUpdates();
    _listenToPortfolioUpdates();
    _startSnapshotTimer(); // Start the snapshot timer
  }

  // Start the timer for periodic portfolio snapshots
  void _startSnapshotTimer() {
    _snapshotTimer?.cancel(); // Cancel existing timer if any
    // Increased frequency for more chart data points
    _snapshotTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Add a snapshot periodically, only if data is loaded
      if (_userProfile != null && !_isLoading) {
         _addPortfolioSnapshot();
         // We might notify listeners here if we want the graph to update
         // based *only* on new snapshots, but current logic updates on price changes anyway.
         // notifyListeners();
      }
    });
  }

  // Listen to song updates from the MarketService (formerly SongService)
  void _listenToSongUpdates() {
    _songUpdateSubscription = _marketService.songUpdates.listen((songs) { // Renamed variable
      // When songs are updated, update the portfolio service with new data
      _portfolioService.updatePortfolioData(_portfolio, songs); // Renamed variable
      // Notify listeners to update the UI
      notifyListeners();
    });
  }

  // Listen to portfolio updates from the PortfolioService
  void _listenToPortfolioUpdates() {
    _portfolioUpdateSubscription = _portfolioService.portfolioUpdates.listen((data) { // Renamed variable
      // Update price change indicators
      final updates = data['updates'] as Map<String, Map<String, dynamic>>;

      updates.forEach((songId, update) {
        final priceChange = update['priceChange'] as double;
        if (priceChange > 0) {
          _priceChangeIndicators[songId] = PriceChange.increase;
        } else if (priceChange < 0) {
          _priceChangeIndicators[songId] = PriceChange.decrease;
        }
      });

      // Notify listeners to update the UI
      notifyListeners();

      // Clear indicators after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _priceChangeIndicators.clear();
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    // Cancel subscriptions when the provider is disposed
    _songUpdateSubscription?.cancel();
    _portfolioUpdateSubscription?.cancel();
    _snapshotTimer?.cancel(); // Cancel the snapshot timer
    _portfolioService.dispose(); // Renamed variable
    super.dispose();
  }

  // Load user data from storage
  Future<void> _loadData() async {
    try {
      final data = await _storageService.loadUserData();
      _userProfile = data['profile'] as UserProfile?;
      _portfolio = (data['portfolio'] as List<PortfolioItem>?) ?? [];
      _transactions = (data['transactions'] as List<Transaction>?) ?? [];
      // _portfolioHistory = (data['history'] as List<PortfolioSnapshot>?) ?? []; // Removed history loading

      // Initialize with default data if nothing is loaded
      _userProfile ??= UserProfile(
        userId: 'defaultUser',
        cashBalance: 1000.0,
        displayName: 'New Investor',
      );

      // Wait for a bit to ensure market service has loaded its songs
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Initialize portfolio service with loaded data
      _portfolioService.initialize(_portfolio, _marketService.getAllSongs());
      
      // Load songs related to user's existing portfolio
      if (_portfolio.isNotEmpty) {
        // Use a delayed call to avoid slowing down the initial loading
        Future.delayed(const Duration(milliseconds: 100), () {
          _marketService.loadRelatedSongsForPortfolio(_portfolio);
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      // Initialize with default data on error
      _userProfile = UserProfile(
        userId: 'defaultUser',
        cashBalance: 1000.0,
        displayName: 'New Investor',
      );
      _portfolio = [];
      _transactions = [];
      // _portfolioHistory = []; // Removed history reset

      // Initialize portfolio service with default data
      _portfolioService.initialize(_portfolio, _marketService.getAllSongs());

      notifyListeners();
    }
  }

  // Save user data to storage
  Future<void> _saveData() async {
    try {
      if (_userProfile != null) {
        // Save profile, portfolio, transactions, and songs
        await _storageService.saveUserData(
          profile: _userProfile!,
          portfolio: _portfolio,
          transactions: _transactions,
          songs: _marketService.getAllSongs(), // Save current song prices
          // history: _portfolioHistory, // Removed: History is saved via savePortfolioSnapshot
        );
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // Add a transaction to history
  void _addTransaction(
    String songId,
    String songName,
    String artistName,
    TransactionType type,
    int quantity,
    double price,
    String? albumArtUrl,
  ) {
    final transaction = Transaction(
      id: _uuid.v4(),
      songId: songId,
      songName: songName,
      artistName: artistName,
      type: type,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
      albumArtUrl: albumArtUrl,
    );

    _transactions.add(transaction);

    // Sort transactions by timestamp (newest first)
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Buy a song
  Future<bool> buySong(String songId, int quantity) async {
    // Get the song
    final song = _marketService.getSongById(songId); // Renamed variable
    if (song == null) return false;

    // Calculate total cost
    final totalCost = song.currentPrice * quantity;

    // Check if user has enough balance
    if ((_userProfile?.cashBalance ?? 0) < totalCost) return false;

    // Update user balance
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        cashBalance: _userProfile!.cashBalance - totalCost
      );
    }

    // Check if user already owns this song
    final existingItemIndex = _portfolio.indexWhere((item) => item.songId == songId);

    if (existingItemIndex >= 0) {
      // Update existing portfolio item
      final existingItem = _portfolio[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newAvgPrice = ((existingItem.quantity * existingItem.purchasePrice) +
                          (quantity * song.currentPrice)) / newQuantity;

      _portfolio[existingItemIndex] = existingItem.copyWith(
        quantity: newQuantity,
        purchasePrice: newAvgPrice
      );
    } else {
      // Add new portfolio item
      _portfolio.add(PortfolioItem(
        songId: song.id,
        songName: song.name,
        artistName: song.artist,
        quantity: quantity,
        purchasePrice: song.currentPrice,
        albumArtUrl: song.albumArtUrl,
      ));
    }

    // Add transaction to history
    _addTransaction(
      song.id,
      song.name,
      song.artist,
      TransactionType.buy,
      quantity,
      song.currentPrice,
      song.albumArtUrl,
    );

    // Add a snapshot of the portfolio value *after* the transaction
    _addPortfolioSnapshot();

    // Update portfolio service with new data
    _portfolioService.updatePortfolioData(_portfolio, _marketService.getAllSongs());
    
    // When a user buys a new song, load related songs to that artist/genre in the background
    // This creates a more personalized experience as the catalog adapts to user preferences
    Future.delayed(const Duration(milliseconds: 500), () {
      // We're only interested in loading related songs for the artist of the just-purchased song
      final relevantPortfolio = [PortfolioItem(
        songId: song.id,
        songName: song.name,
        artistName: song.artist,
        quantity: quantity,
        purchasePrice: song.currentPrice,
        albumArtUrl: song.albumArtUrl,
      )];
      _marketService.loadRelatedSongsForPortfolio(relevantPortfolio);
    });

    // Save data (which now includes history)
    await _saveData();
    notifyListeners();
    return true;
  }

  // Sell a song
  Future<bool> sellSong(String songId, int quantity) async {
    // Find the portfolio item
    final itemIndex = _portfolio.indexWhere((item) => item.songId == songId);
    if (itemIndex < 0) return false;

    final item = _portfolio[itemIndex];

    // Check if user has enough quantity to sell
    if (item.quantity < quantity) return false;

    // Get current song price
    final song = _marketService.getSongById(songId); // Renamed variable
    final currentPrice = song?.currentPrice ?? item.purchasePrice;

    // Calculate sale proceeds
    final proceeds = currentPrice * quantity;

    // Update user balance
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        cashBalance: _userProfile!.cashBalance + proceeds
      );
    }

    // Update portfolio
    if (item.quantity == quantity) {
      // Remove item if selling all
      _portfolio.removeAt(itemIndex);
    } else {
      // Update quantity if selling partial
      _portfolio[itemIndex] = item.copyWith(
        quantity: item.quantity - quantity
      );
    }

    // Add transaction to history
    _addTransaction(
      item.songId,
      item.songName,
      item.artistName,
      TransactionType.sell,
      quantity,
      currentPrice,
      item.albumArtUrl,
    );

    // Add a snapshot of the portfolio value *after* the transaction
    _addPortfolioSnapshot();

    // Update portfolio service with new data
    _portfolioService.updatePortfolioData(_portfolio, _marketService.getAllSongs());

    // Save data (which now includes history)
    await _saveData();
    notifyListeners();
    return true;
  }

  // Reset user data (for demo purposes)
  Future<void> resetData() async {
    _userProfile = UserProfile(
      userId: 'defaultUser',
      cashBalance: 1000.0,
      displayName: 'New Investor',
    );
    _portfolio = [];
    _transactions = [];
    // _portfolioHistory = []; // Removed history clearing

    // Clear saved data (including SQLite table)
    await _storageService.clearAllData();
    notifyListeners();
  }

  // Helper method to add a portfolio snapshot to the database
  Future<void> _addPortfolioSnapshot() async {
    final currentPortfolioValue = _calculatePortfolioValue();
    final now = DateTime.now();
    final snapshot = PortfolioSnapshot(timestamp: now, value: currentPortfolioValue);

    try {
      await _storageService.savePortfolioSnapshot(snapshot);
    } catch (e) {
      print('Error saving portfolio snapshot: $e');
    }
  }

  // Fetch portfolio history for a given date range
  Future<List<PortfolioSnapshot>> fetchPortfolioHistory(DateTime start, DateTime end) async {
    try {
      return await _storageService.loadPortfolioHistoryRange(start, end);
    } catch (e) {
      print('Error fetching portfolio history range: $e');
      return [];
    }
  }

  // Get the earliest timestamp available in history
  Future<DateTime?> getEarliestTimestamp() async {
     try {
      return await _storageService.getEarliestTimestamp();
    } catch (e) {
      print('Error fetching earliest timestamp: $e');
      return null;
    }
  }


  // Get portfolio item by song ID
  PortfolioItem? getPortfolioItemBySongId(String songId) {
    try {
      return _portfolio.firstWhere((item) => item.songId == songId);
    } catch (e) {
      return null;
    }
  }

  // Check if user owns a song
  bool ownsSong(String songId) {
    return _portfolio.any((item) => item.songId == songId && item.quantity > 0);
  }

  // Get quantity owned of a song
  int getQuantityOwned(String songId) {
    final item = getPortfolioItemBySongId(songId);
    return item?.quantity ?? 0;
  }

  // Get transactions for a specific song
  List<Transaction> getTransactionsForSong(String songId) {
    return _transactions.where((t) => t.songId == songId).toList();
  }

  // Get transactions by type (buy or sell)
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Get transactions within a date range
  List<Transaction> getTransactionsInDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) =>
      t.timestamp.isAfter(start) &&
      t.timestamp.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // Calculate total spent on purchases
  double getTotalSpent() {
    return _transactions
        .where((t) => t.type == TransactionType.buy)
        .fold(0.0, (sum, t) => sum + t.totalValue);
  }

  // Calculate total earned from sales
  double getTotalEarned() {
    return _transactions
        .where((t) => t.type == TransactionType.sell)
        .fold(0.0, (sum, t) => sum + t.totalValue);
  }

  // --- Stream Count methods removed as Spotify API doesn't provide this easily ---

  // Refresh data to update prices in real-time and reload portfolio data
  Future<void> refreshData() async {
    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Reload portfolio data from storage
      await _loadData();

      // Trigger a manual update of song prices
      _marketService.triggerPriceUpdate(); // Renamed variable
      
      // Load songs related to the user's portfolio
      if (_portfolio.isNotEmpty) {
        await _marketService.loadRelatedSongsForPortfolio(_portfolio);
      }

      // Force portfolio update
      _portfolioService.forceUpdate(); // Renamed variable
    } catch (e) {
      // print('Error refreshing data: $e'); // Removed print
    } finally {
      // Clear loading state
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get price change indicator for a song
  // Note: This now relies on the PriceChange enum defined in PortfolioService
  // If PortfolioService is not directly used here, consider moving the enum to a shared location
  // or importing PortfolioService just for the enum type.
  // For now, assuming the type check works due to the import above.
  PriceChange getPriceChangeIndicator(String songId) {
    return _priceChangeIndicators[songId] ?? PriceChange.none;
  }
  
  // Expose the song updates stream for real-time price updates
  Stream<List<Song>> get songUpdatesStream => _marketService.songUpdates;
}

// Removed duplicate PriceChange enum definition from here
