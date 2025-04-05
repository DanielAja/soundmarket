import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/song_service.dart';

class UserDataProvider with ChangeNotifier {
  UserProfile? _userProfile;
  List<PortfolioItem> _portfolio = [];
  final StorageService _storageService = StorageService();
  final SongService _songService = SongService();
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  List<PortfolioItem> get portfolio => _portfolio;
  
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
  
  // Get top movers
  List<Song> get topMovers => _songService.getTopMovers();
  
  // Get rising artists
  List<String> get risingArtists => _songService.getRisingArtists();

  UserDataProvider() {
    _loadData();
  }

  // Load user data from storage
  Future<void> _loadData() async {
    try {
      final data = await _storageService.loadUserData();
      _userProfile = data['profile'] as UserProfile?;
      _portfolio = (data['portfolio'] as List<PortfolioItem>?) ?? [];
      
      // Initialize with default data if nothing is loaded
      _userProfile ??= UserProfile(
        userId: 'defaultUser',
        cashBalance: 1000.0,
        displayName: 'New Investor',
      );
      
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
      notifyListeners();
    }
  }

  // Save user data to storage
  Future<void> _saveData() async {
    try {
      if (_userProfile != null) {
        await _storageService.saveUserData(_userProfile!, _portfolio);
      }
    } catch (e) {
      print('Error saving data: $e');
    }
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
}
