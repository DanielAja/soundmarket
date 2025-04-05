import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/transaction.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _userProfileKey = 'user_profile';
  static const String _portfolioKey = 'portfolio';
  static const String _transactionsKey = 'transactions';
  
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
  
  // Save user profile, portfolio, and transactions
  Future<void> saveUserData(
    UserProfile profile, 
    List<PortfolioItem> portfolio,
    List<Transaction> transactions,
  ) async {
    await saveUserProfile(profile);
    await savePortfolio(portfolio);
    await saveTransactions(transactions);
  }
  
  // Load user profile, portfolio, and transactions
  Future<Map<String, dynamic>> loadUserData() async {
    final profile = await loadUserProfile();
    final portfolio = await loadPortfolio();
    final transactions = await loadTransactions();
    
    return {
      'profile': profile,
      'portfolio': portfolio,
      'transactions': transactions,
    };
  }
  
  // Clear all stored data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
    await prefs.remove(_portfolioKey);
    await prefs.remove(_transactionsKey);
  }
}
