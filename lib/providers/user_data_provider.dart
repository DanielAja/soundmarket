import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../services/storage_service.dart';

// Placeholder for managing user state
class UserDataProvider with ChangeNotifier {
  UserProfile? _userProfile;
  List<PortfolioItem> _portfolio = [];
  final StorageService _storageService = StorageService();

  UserProfile? get userProfile => _userProfile;
  List<PortfolioItem> get portfolio => _portfolio;
  double get totalPortfolioValue {
      // TODO: Calculate based on current song prices and quantities
      return 0.0;
  }
   double get totalBalance => (_userProfile?.cashBalance ?? 0.0) + totalPortfolioValue;


  UserDataProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Load data from StorageService
    // final data = await _storageService.loadUserData();
    // _userProfile = ...
    // _portfolio = ...
    _userProfile ??= UserProfile(userId: 'defaultUser'); // Initialize if no data
    notifyListeners();
  }

  Future<void> _saveData() async {
    // TODO: Save data using StorageService
    // await _storageService.saveUserData(_userProfile, _portfolio);
  }

  void buySong(String songId, int quantity, double price) {
    // TODO: Implement buy logic
    // Check balance, update portfolio, update balance
    // _saveData();
    notifyListeners();
  }

  void sellSong(String songId, int quantity, double price) {
    // TODO: Implement sell logic
    // Check holdings, update portfolio, update balance
    // _saveData();
    notifyListeners();
  }

   void resetData() {
     _userProfile = UserProfile(userId: 'defaultUser', cashBalance: 100.0);
     _portfolio = [];
     // TODO: Clear saved data using StorageService? Or just reset in memory?
     // _saveData(); // Decide if reset should persist
     notifyListeners();
   }
}
