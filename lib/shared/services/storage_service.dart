import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/transaction.dart';
import '../models/portfolio_snapshot.dart'; // Import the new model

class StorageService {
  // Keys for SharedPreferences
  static const String _userProfileKey = 'user_profile';
  static const String _portfolioKey = 'portfolio';
  static const String _transactionsKey = 'transactions';
  static const String _portfolioHistoryKey = 'portfolio_history'; // New key for snapshots

  // Save user profile to local storage
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toJson());
    await prefs.setString(_userProfileKey, profileJson);
  }
  
  // Load user profile from local storage
  Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    
    if (profileJson == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> profileMap = jsonDecode(profileJson);
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }
  
  // Save portfolio to local storage
  Future<void> savePortfolio(List<PortfolioItem> portfolio) async {
    final prefs = await SharedPreferences.getInstance();
    final portfolioJsonList = portfolio.map((item) => item.toJson()).toList();
    final portfolioJson = jsonEncode(portfolioJsonList);
    await prefs.setString(_portfolioKey, portfolioJson);
  }
  
  // Load portfolio from local storage
  Future<List<PortfolioItem>> loadPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final portfolioJson = prefs.getString(_portfolioKey);
    
    if (portfolioJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> portfolioList = jsonDecode(portfolioJson);
      return portfolioList
          .map((item) => PortfolioItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading portfolio: $e');
      return [];
    }
  }
  
  // Save transactions to local storage
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJsonList = transactions.map((item) => item.toJson()).toList();
    final transactionsJson = jsonEncode(transactionsJsonList);
    await prefs.setString(_transactionsKey, transactionsJson);
  }
  
  // Load transactions from local storage
  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString(_transactionsKey);
    
    if (transactionsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> transactionsList = jsonDecode(transactionsJson);
      return transactionsList
          .map((item) => Transaction.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  // Save portfolio history (snapshots) to local storage
  Future<void> savePortfolioHistory(List<PortfolioSnapshot> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonList = history.map((snapshot) => snapshot.toJson()).toList();
    final historyJson = jsonEncode(historyJsonList);
    await prefs.setString(_portfolioHistoryKey, historyJson);
  }

  // Load portfolio history (snapshots) from local storage
  Future<List<PortfolioSnapshot>> loadPortfolioHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_portfolioHistoryKey);

    if (historyJson == null) {
      return [];
    }

    try {
      final List<dynamic> historyList = jsonDecode(historyJson);
      // Ensure snapshots are sorted by timestamp after loading
      final snapshots = historyList
          .map((item) => PortfolioSnapshot.fromJson(item))
          .toList();
      snapshots.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return snapshots;
    } catch (e) {
      print('Error loading portfolio history: $e');
      return [];
    }
  }

  // Save user profile, portfolio, transactions, and history
  Future<void> saveUserData({
    required UserProfile profile,
    required List<PortfolioItem> portfolio,
    required List<Transaction> transactions,
    required List<PortfolioSnapshot> history,
  }) async {
    await saveUserProfile(profile);
    await savePortfolio(portfolio);
    await saveTransactions(transactions);
    await savePortfolioHistory(history); // Save history
  }
  
  // Load user profile, portfolio, and transactions
  Future<Map<String, dynamic>> loadUserData() async {
    final profile = await loadUserProfile();
    final portfolio = await loadPortfolio();
    final transactions = await loadTransactions();
    final history = await loadPortfolioHistory(); // Load history

    return {
      'profile': profile,
      'portfolio': portfolio,
      'transactions': transactions,
      'history': history, // Add history to the returned map
    };
  }
  
  // Clear all stored data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
    await prefs.remove(_portfolioKey);
    await prefs.remove(_transactionsKey);
    await prefs.remove(_portfolioHistoryKey); // Clear history
  }
}
