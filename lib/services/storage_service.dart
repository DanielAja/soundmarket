import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _userProfileKey = 'user_profile';
  static const String _portfolioKey = 'portfolio';
  
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
  
  // Save both user profile and portfolio
  Future<void> saveUserData(UserProfile profile, List<PortfolioItem> portfolio) async {
    await saveUserProfile(profile);
    await savePortfolio(portfolio);
  }
  
  // Load both user profile and portfolio
  Future<Map<String, dynamic>> loadUserData() async {
    final profile = await loadUserProfile();
    final portfolio = await loadPortfolio();
    
    return {
      'profile': profile,
      'portfolio': portfolio,
    };
  }
  
  // Clear all stored data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
    await prefs.remove(_portfolioKey);
  }
}
