import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/song_service.dart';
import '../services/portfolio_update_service.dart';

class UserDataProvider with ChangeNotifier {
  UserProfile? _userProfile;
  List<PortfolioItem> _portfolio = [];
  List<Transaction> _transactions = [];
  final StorageService _storageService = StorageService();
  final SongService _songService = SongService();
  final _uuid = const Uuid();
  
  // Loading state
  bool _isLoading = false;
  
  // Subscriptions
  StreamSubscription? _songUpdateSubscription;
  StreamSubscription? _portfolioUpdateSubscription;
  
  // Portfolio update service
  final PortfolioUpdateService _portfolioUpdateService = PortfolioUpdateService();
  
  // Price change indicators
  final Map<String, PriceChange> _priceChangeIndicators = {};
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  List<PortfolioItem> get portfolio => _portfolio;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  
  // Calculate total portfolio value based on current song prices
  double get totalPortfolioValue {
    double total = 0.0;
    for (var item in _portfolio) {
      final song = _songService.getSongById(item.songId);
      if (song != null) {
        total += item.quantity * song.currentPrice;
      } else {
        // If song not found, use purchase price as fallback
        total += item.quantity * item.purchasePrice;
      }
    }
    return total;
  }
  
  // Calculate total balance (cash + portfolio value)
  double get totalBalance => (_userProfile?.cashBalance ?? 0.0) + totalPortfolioValue;
  
  // Get all available songs
  List<Song> get allSongs => _songService.getAllSongs();
  
  // Get top songs
  List<Song> get topSongs => _songService.getTopSongs();
  
  // Get top songs with custom limit
  List<Song> getTopSongs({int limit = 10}) => _songService.getTopSongs(limit: limit);
  
  // Get top movers
  List<Song> get topMovers => _songService.getTopMovers();
  
  // Get top movers with custom limit
  List<Song> getTopMovers({int limit = 10}) => _songService.getTopMovers(limit: limit);
  
  // Get rising artists
  List<String> get risingArtists => _songService.getRisingArtists();
  
  // Get songs by genre
  List<Song> getSongsByGenre(String genre) => _songService.getSongsByGenre(genre);
  
  // Get all genres
  List<String> get allGenres => _songService.getAllGenres();
  
  // Get songs by artist
  List<Song> getSongsByArtist(String artist) => _songService.getSongsByArtist(artist);

  UserDataProvider() {
    _loadData();
    _listenToSongUpdates();
    _listenToPortfolioUpdates();
  }
  
  // Listen to song updates from the SongService
  void _listenToSongUpdates() {
    _songUpdateSubscription = _songService.songUpdates.listen((songs) {
      // When songs are updated, update the portfolio service with new data
      _portfolioUpdateService.updatePortfolioData(_portfolio, songs);
      // Notify listeners to update the UI
      notifyListeners();
    });
  }
  
  // Listen to portfolio updates from the PortfolioUpdateService
  void _listenToPortfolioUpdates() {
    _portfolioUpdateSubscription = _portfolioUpdateService.portfolioUpdates.listen((data) {
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
    _portfolioUpdateService.dispose();
    super.dispose();
  }

  // Load user data from storage
  Future<void> _loadData() async {
    try {
      final data = await _storageService.loadUserData();
      _userProfile = data['profile'] as UserProfile?;
      _portfolio = (data['portfolio'] as List<PortfolioItem>?) ?? [];
      _transactions = (data['transactions'] as List<Transaction>?) ?? [];
      
      // Initialize with default data if nothing is loaded
      _userProfile ??= UserProfile(
        userId: 'defaultUser',
        cashBalance: 1000.0,
        displayName: 'New Investor',
      );
      
      // Initialize portfolio update service with loaded data
      _portfolioUpdateService.initialize(_portfolio, _songService.getAllSongs());
      
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
      
      // Initialize portfolio update service with default data
      _portfolioUpdateService.initialize(_portfolio, _songService.getAllSongs());
      
      notifyListeners();
    }
  }

  // Save user data to storage
  Future<void> _saveData() async {
    try {
      if (_userProfile != null) {
        await _storageService.saveUserData(_userProfile!, _portfolio, _transactions);
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
    final song = _songService.getSongById(songId);
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
    
    // Update portfolio service with new data
    _portfolioUpdateService.updatePortfolioData(_portfolio, _songService.getAllSongs());
    
    // Save data
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
    final song = _songService.getSongById(songId);
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
    
    // Update portfolio service with new data
    _portfolioUpdateService.updatePortfolioData(_portfolio, _songService.getAllSongs());
    
    // Save data
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
    
    // Clear saved data
    await _storageService.clearAllData();
    notifyListeners();
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
  
  // Get formatted stream count for a song
  String getSongStreamCount(String songId) {
    return _songService.getFormattedStreamCount(songId);
  }
  
  // Get total stream count for all songs in portfolio
  int getTotalPortfolioStreamCount() {
    int total = 0;
    for (var item in _portfolio) {
      total += _songService.getStreamCount(item.songId);
    }
    return total;
  }
  
  // Get formatted total stream count for all songs in portfolio
  String getFormattedTotalPortfolioStreamCount() {
    final count = getTotalPortfolioStreamCount();
    
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
  
  // Refresh data to update prices in real-time and reload portfolio data
  Future<void> refreshData() async {
    // Set loading state
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reload portfolio data from storage
      await _loadData();
      
      // Trigger a manual update of song prices
      _songService.triggerPriceUpdate();
      
      // Force portfolio update
      _portfolioUpdateService.forceUpdate();
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      // Clear loading state
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get price change indicator for a song
  PriceChange getPriceChangeIndicator(String songId) {
    return _priceChangeIndicators[songId] ?? PriceChange.none;
  }
}
