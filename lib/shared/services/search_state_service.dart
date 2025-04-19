import 'package:flutter/material.dart';

// A singleton service to maintain search state across the app
class SearchStateService extends ChangeNotifier {
  // Singleton pattern
  static final SearchStateService _instance = SearchStateService._internal();
  factory SearchStateService() => _instance;
  SearchStateService._internal();

  // The current search query
  String _currentQuery = '';
  
  // Getter for the current query
  String get currentQuery => _currentQuery;
  
  // Update the query and notify listeners
  void updateQuery(String query) {
    if (_currentQuery != query) {
      _currentQuery = query;
      notifyListeners();
    }
  }
}