import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../models/transaction.dart';
import '../models/portfolio_snapshot.dart'; // Import the snapshot model
import '../services/storage_service.dart';
import '../services/portfolio_background_service.dart'; // Import the background service
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
  final PortfolioService _portfolioService =
      PortfolioService(); // Renamed class and variable

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
  double get totalBalance =>
      (_userProfile?.cashBalance ?? 0.0) + totalPortfolioValue;

  // Get all available songs
  List<Song> get allSongs {
    // Get songs from the market service
    final songs = _marketService.getAllSongs();

    // Add any songs from searches that aren't already in the main collection
    final allSongIds = songs.map((s) => s.id).toSet();
    for (final song in _songsFromSearches) {
      if (!allSongIds.contains(song.id)) {
        songs.add(song);
      }
    }

    return songs;
  }

  // Get top songs
  List<Song> get topSongs => _marketService.getTopSongs(); // Renamed variable

  // Get top songs with custom limit
  List<Song> getTopSongs({int limit = 10}) =>
      _marketService.getTopSongs(limit: limit); // Renamed variable

  // Get top movers
  List<Song> get topMovers => _marketService.getTopMovers(); // Renamed variable

  // Get top movers with custom limit
  List<Song> getTopMovers({int limit = 10}) =>
      _marketService.getTopMovers(limit: limit); // Renamed variable

  // Get rising artists
  List<String> get risingArtists =>
      _marketService.getRisingArtists(); // Renamed variable

  // Get songs by genre
  List<Song> getSongsByGenre(String genre) =>
      _marketService.getSongsByGenre(genre); // Renamed variable

  // Get all genres
  List<String> get allGenres =>
      _marketService.getAllGenres(); // Renamed variable

  // Get songs by artist
  List<Song> getSongsByArtist(String artist) =>
      _marketService.getSongsByArtist(artist); // Renamed variable

  UserDataProvider() {
    _loadData();
    _listenToSongUpdates();
    _listenToPortfolioUpdates();
    _startSnapshotTimer(); // Start the snapshot timer
  }

  // Start the timer for periodic portfolio snapshots
  void _startSnapshotTimer() {
    _snapshotTimer?.cancel(); // Cancel existing timer if any
    // Increased frequency for more chart data points and faster price updates
    _snapshotTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Add a snapshot periodically, only if data is loaded
      if (_userProfile != null && !_isLoading) {
        _addPortfolioSnapshot();

        // Update any songs from search results that are in the portfolio
        _updateSearchSongPrices();

        // Force portfolio service to check for updates more aggressively
        // This ensures more frequent price updates when on the home screen
        _portfolioService.updatePortfolioData(_portfolio, [
          ..._marketService.getAllSongs(),
          ..._songsFromSearches,
        ]);
        _portfolioService.forceUpdate();

        // Update the background service with current portfolio data
        _updateBackgroundService();

        // We might notify listeners here if we want the graph to update
        // based *only* on new snapshots, but current logic updates on price changes anyway.
        // notifyListeners();
      }
    });
  }

  // Update the background service with current portfolio data
  void _updateBackgroundService() {
    // Only update if we have valid data
    if (_portfolio.isEmpty || _userProfile == null) return;

    // Calculate current portfolio value
    final portfolioValue = _calculatePortfolioValue();

    // Get all songs (both from market service and search)
    final allSongs = [..._marketService.getAllSongs(), ..._songsFromSearches];

    // Send data to the background service
    PortfolioBackgroundService.sendDataToBackground(
      portfolioValue: portfolioValue,
      portfolioItems: _portfolio,
      songs: allSongs,
    );
  }

  // Helper method to update prices of songs from search results that are in portfolio
  void _updateSearchSongPrices() {
    if (_songsFromSearches.isEmpty || _portfolio.isEmpty) return;

    // Find portfolio items that use songs from searches
    final searchSongIds = _songsFromSearches.map((s) => s.id).toSet();
    final portfolioSearchSongIds =
        _portfolio
            .where((item) => searchSongIds.contains(item.songId))
            .map((item) => item.songId)
            .toSet();

    // Skip if no portfolio items use search songs
    if (portfolioSearchSongIds.isEmpty) return;

    bool hasUpdates = false;

    // Update prices for search songs that are in the portfolio
    for (int i = 0; i < _songsFromSearches.length; i++) {
      final song = _songsFromSearches[i];
      if (portfolioSearchSongIds.contains(song.id)) {
        // Simulate a price update for the search song
        final randomFactor =
            0.98 + (0.04 * (DateTime.now().millisecondsSinceEpoch % 10) / 10);
        final updatedPrice = song.currentPrice * randomFactor;

        // Update the song with the new price
        _songsFromSearches[i] = song.copyWith(currentPrice: updatedPrice);
        hasUpdates = true;
      }
    }

    // Update the song stream to propagate changes to UI
    if (hasUpdates) {
      _updateSongStream();
      notifyListeners();
    }
  }

  // Listen to song updates from the MarketService (formerly SongService)
  void _listenToSongUpdates() {
    _songUpdateSubscription = _marketService.songUpdates.listen((songs) {
      // Create a combined song list that includes both market songs and search songs
      final combinedSongs = List<Song>.from(songs);

      // Add songs from searches to ensure they're included in updates
      for (final searchSong in _songsFromSearches) {
        // Skip if this song is already in the main catalog (avoid duplicates)
        if (!combinedSongs.any((s) => s.id == searchSong.id)) {
          combinedSongs.add(searchSong);
        }
      }

      // When songs are updated, update the portfolio service with the combined data
      _portfolioService.updatePortfolioData(_portfolio, combinedSongs);

      // Notify listeners to update the UI
      notifyListeners();
    });
  }

  // Listen to portfolio updates from the PortfolioService
  void _listenToPortfolioUpdates() {
    _portfolioUpdateSubscription = _portfolioService.portfolioUpdates.listen((
      data,
    ) {
      // Renamed variable
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
    _songStreamController?.close(); // Close stream controller
    _portfolioService.dispose();
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

      // Check for portfolio snapshots that were created while the app was closed
      await _loadBackgroundSnapshots();

      // Load songs related to user's existing portfolio
      if (_portfolio.isNotEmpty) {
        // Use a delayed call to avoid slowing down the initial loading
        Future.delayed(const Duration(milliseconds: 100), () {
          _marketService.loadRelatedSongsForPortfolio(_portfolio);
        });
      }

      // Update the background service with current portfolio data
      _updateBackgroundService();

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

  // Load portfolio snapshots created by the background service
  Future<void> _loadBackgroundSnapshots() async {
    try {
      if (_portfolio.isEmpty) return;

      // Get the timestamp of the most recent snapshot we created before app closure
      final lastSnapshot = await _getLatestPortfolioSnapshot();

      if (lastSnapshot != null) {
        // Find snapshots created after the last one we explicitly created
        final now = DateTime.now();
        final backgroundSnapshots = await _storageService
            .loadPortfolioHistoryRange(
              lastSnapshot.timestamp.add(const Duration(seconds: 1)),
              now,
            );

        if (backgroundSnapshots.isNotEmpty) {
          print(
            'Loaded ${backgroundSnapshots.length} snapshots created while app was closed',
          );

          // Update the portfolio with the latest background snapshot value
          // if it's significantly different
          final latestBackgroundSnapshot = backgroundSnapshots.last;
          final currentValue = _calculatePortfolioValue();

          // If the difference is more than 5%, update our local price data
          if ((latestBackgroundSnapshot.value - currentValue).abs() /
                  currentValue >
              0.05) {
            _updatePortfolioPricesFromSnapshot(latestBackgroundSnapshot.value);
          }
        }
      }
    } catch (e) {
      print('Error loading background snapshots: $e');
    }
  }

  // Get the most recent portfolio snapshot
  Future<PortfolioSnapshot?> _getLatestPortfolioSnapshot() async {
    // Get a date range from yesterday to now to find the most recent snapshot
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Get snapshots from the last day
    final snapshots = await _storageService.loadPortfolioHistoryRange(
      yesterday,
      now,
    );

    if (snapshots.isEmpty) {
      return null;
    }

    // Sort snapshots by timestamp (newest first)
    snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Return the most recent snapshot
    return snapshots.first;
  }

  // Update portfolio prices based on a snapshot value
  void _updatePortfolioPricesFromSnapshot(double snapshotValue) {
    if (_portfolio.isEmpty) return;

    // Calculate the current portfolio value
    final currentValue = _calculatePortfolioValue();

    // Calculate the ratio between the snapshot value and current value
    final ratio = snapshotValue / currentValue;

    // Only update if the change is significant
    if ((ratio - 1.0).abs() < 0.01) return;

    // Update song prices in the portfolio to match the snapshot value
    final songs = _marketService.getAllSongs();
    final songIds = _portfolio.map((item) => item.songId).toSet();

    // Create a map of song IDs to songs for faster lookup
    final songMap = {for (var song in songs) song.id: song};

    // Apply the ratio to each song in the portfolio
    for (final id in songIds) {
      final song = songMap[id];
      if (song != null) {
        // Find the song in the market service and update its price
        final index = songs.indexWhere((s) => s.id == id);
        if (index >= 0) {
          songs[index] = song.copyWith(
            previousPrice: song.currentPrice,
            currentPrice: song.currentPrice * ratio,
          );
        }
      }
    }

    // Also update search songs that are in the portfolio
    for (int i = 0; i < _songsFromSearches.length; i++) {
      final song = _songsFromSearches[i];
      if (songIds.contains(song.id)) {
        _songsFromSearches[i] = song.copyWith(
          previousPrice: song.currentPrice,
          currentPrice: song.currentPrice * ratio,
        );
      }
    }

    // Notify listeners to update UI with new prices
    notifyListeners();
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

        // Update the background service with the latest data
        _updateBackgroundService();
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
    // Get the song using our new helper method that checks both sources
    final song = getSongById(songId);
    if (song == null) return false;

    // Calculate total cost
    final totalCost = song.currentPrice * quantity;

    // Check if user has enough balance
    if ((_userProfile?.cashBalance ?? 0) < totalCost) return false;

    // Update user balance
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        cashBalance: _userProfile!.cashBalance - totalCost,
      );
    }

    // Check if user already owns this song
    final existingItemIndex = _portfolio.indexWhere(
      (item) => item.songId == songId,
    );

    if (existingItemIndex >= 0) {
      // Update existing portfolio item
      final existingItem = _portfolio[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newAvgPrice =
          ((existingItem.quantity * existingItem.purchasePrice) +
              (quantity * song.currentPrice)) /
          newQuantity;

      _portfolio[existingItemIndex] = existingItem.copyWith(
        quantity: newQuantity,
        purchasePrice: newAvgPrice,
      );
    } else {
      // Add new portfolio item
      _portfolio.add(
        PortfolioItem(
          songId: song.id,
          songName: song.name,
          artistName: song.artist,
          quantity: quantity,
          purchasePrice: song.currentPrice,
          albumArtUrl: song.albumArtUrl,
        ),
      );
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
    _portfolioService.updatePortfolioData(
      _portfolio,
      _marketService.getAllSongs(),
    );

    // When a user buys a new song, load related songs to that artist/genre in the background
    // This creates a more personalized experience as the catalog adapts to user preferences
    Future.delayed(const Duration(milliseconds: 500), () {
      // We're only interested in loading related songs for the artist of the just-purchased song
      final relevantPortfolio = [
        PortfolioItem(
          songId: song.id,
          songName: song.name,
          artistName: song.artist,
          quantity: quantity,
          purchasePrice: song.currentPrice,
          albumArtUrl: song.albumArtUrl,
        ),
      ];
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

    // Get the song using our new helper method that checks both sources
    final song = getSongById(songId);

    final currentPrice = song?.currentPrice ?? item.purchasePrice;

    // Calculate sale proceeds
    final proceeds = currentPrice * quantity;

    // Update user balance
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        cashBalance: _userProfile!.cashBalance + proceeds,
      );
    }

    // Update portfolio
    if (item.quantity == quantity) {
      // Remove item if selling all
      _portfolio.removeAt(itemIndex);
    } else {
      // Update quantity if selling partial
      _portfolio[itemIndex] = item.copyWith(quantity: item.quantity - quantity);
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
    _portfolioService.updatePortfolioData(
      _portfolio,
      _marketService.getAllSongs(),
    );

    // Save data (which now includes history)
    await _saveData();
    notifyListeners();
    return true;
  }

  // Add funds to user's account
  Future<bool> addFunds(double amount) async {
    if (_userProfile == null) return false;

    try {
      // Update user balance
      _userProfile = _userProfile!.copyWith(
        cashBalance: _userProfile!.cashBalance + amount,
      );

      // Save user data
      await _saveData();

      // Add a portfolio snapshot after adding funds
      await _addPortfolioSnapshot();

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
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
    final snapshot = PortfolioSnapshot(
      timestamp: now,
      value: currentPortfolioValue,
    );

    try {
      await _storageService.savePortfolioSnapshot(snapshot);
    } catch (e) {
      print('Error saving portfolio snapshot: $e');
    }
  }

  // Fetch portfolio history for a given date range
  Future<List<PortfolioSnapshot>> fetchPortfolioHistory(
    DateTime start,
    DateTime end,
  ) async {
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
    return _transactions
        .where(
          (t) =>
              t.timestamp.isAfter(start) &&
              t.timestamp.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
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

  // Calculate portfolio value based on provided songs and portfolio items
  double calculatePortfolioValue(
    List<Song> songs,
    List<PortfolioItem> portfolioItems,
  ) {
    double total = 0.0;

    // Create a map of song IDs to songs for faster lookup
    final songMap = {for (var song in songs) song.id: song};

    for (var item in portfolioItems) {
      final song = songMap[item.songId];
      if (song != null) {
        // If we have the song in our map, use its current price
        total += item.quantity * song.currentPrice;
      } else {
        // Fallback to using the purchase price if the song isn't in the provided list
        total += item.quantity * item.purchasePrice;
      }
    }

    return total;
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
      _marketService.triggerPriceUpdate();

      // Load songs related to the user's portfolio
      if (_portfolio.isNotEmpty) {
        await _marketService.loadRelatedSongsForPortfolio(_portfolio);
      }

      // Update any songs from search results that are in the portfolio
      _updateSearchSongPrices();

      // Force portfolio update with combined songs
      _portfolioService.updatePortfolioData(_portfolio, [
        ..._marketService.getAllSongs(),
        ..._songsFromSearches,
      ]);
      _portfolioService.forceUpdate();
    } catch (e) {
      // Error handling
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

  // Cached stream controller to avoid memory leaks
  StreamController<List<Song>>? _songStreamController;

  // Expose the song updates stream for real-time price updates
  // Creates a custom stream to include both market songs and search songs
  Stream<List<Song>> get songUpdatesStream {
    // Reuse existing controller if it exists and is not closed
    if (_songStreamController == null || _songStreamController!.isClosed) {
      // Create a StreamController to combine both sources
      _songStreamController = StreamController<List<Song>>.broadcast(
        onCancel: () {
          // Clean up and close when no listeners
          _songStreamController?.close();
          _songStreamController = null;
        },
      );

      // Set up the subscription to market service updates
      _marketService.songUpdates.listen((songs) {
        if (_songStreamController == null || _songStreamController!.isClosed)
          return;

        final combinedSongs = [...songs];

        // Add any songs from searches that aren't in the main list
        for (final searchSong in _songsFromSearches) {
          if (!combinedSongs.any((s) => s.id == searchSong.id)) {
            combinedSongs.add(searchSong);
          }
        }

        // Add to the stream controller
        _songStreamController!.add(combinedSongs);
      });
    }

    return _songStreamController!.stream;
  }

  // Manually add songs to the stream - can be called when search songs change
  void _updateSongStream() {
    if (_songStreamController == null || _songStreamController!.isClosed)
      return;

    final combinedSongs = [..._marketService.getAllSongs()];

    // Add any songs from searches that aren't in the main list
    for (final searchSong in _songsFromSearches) {
      if (!combinedSongs.any((s) => s.id == searchSong.id)) {
        combinedSongs.add(searchSong);
      }
    }

    // Add to the stream controller
    _songStreamController!.add(combinedSongs);
  }

  // Add songs to the song pool (used after searching to add new songs from API)
  void addSongsToPool(List<Song> songs) {
    if (songs.isEmpty) return;

    bool hasNewSongs = false;

    // Add the songs to the song list through the market service
    for (final song in songs) {
      // Find duplicates (e.g., if a song with this ID already exists)
      final existingSong = _marketService.getSongById(song.id);

      if (existingSong == null) {
        // Check if song already exists in search results
        final existingInSearches = _songsFromSearches.any(
          (s) => s.id == song.id,
        );

        if (!existingInSearches) {
          // This is a new song not yet in our pool, so we need to add it
          _songsFromSearches.add(song);
          hasNewSongs = true;
        } else {
          // Update existing search song with new data (like price updates)
          final index = _songsFromSearches.indexWhere((s) => s.id == song.id);
          if (index >= 0) {
            _songsFromSearches[index] = song;
            hasNewSongs = true;
          }
        }
      }
    }

    if (hasNewSongs) {
      // Make sure the portfolio service is updated with the new song data
      _portfolioService.updatePortfolioData(_portfolio, [
        ..._marketService.getAllSongs(),
        ..._songsFromSearches,
      ]);

      // Update the song stream to propagate changes to UI
      _updateSongStream();

      // Notify listeners to update the UI with the new songs
      notifyListeners();
    }
  }

  // Keep track of songs added from searches (not in the main catalog)
  final List<Song> _songsFromSearches = [];

  // Get a song by ID, checking both main catalog and search results
  Song? getSongById(String songId) {
    // First check the market service
    Song? song = _marketService.getSongById(songId);

    // If not found, check search results
    if (song == null) {
      try {
        song = _songsFromSearches.firstWhere((s) => s.id == songId);
      } catch (e) {
        // Song not found in search results either
        return null;
      }
    }

    return song;
  }
}

// Removed duplicate PriceChange enum definition from here
