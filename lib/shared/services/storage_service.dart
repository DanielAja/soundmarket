import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite; // Add prefix
import 'package:path/path.dart'; // Import path package
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/transaction.dart';
import '../models/portfolio_snapshot.dart';
import '../models/song.dart'; // Import Song model

class StorageService {
  // Keys for SharedPreferences (Profile, Portfolio, Transactions, Songs)
  static const String _userProfileKey = 'user_profile';
  static const String _portfolioKey = 'portfolio';
  static const String _transactionsKey = 'transactions';
  static const String _songsKey = 'songs'; // Add key for songs

  // Database instance
  static sqflite.Database? _database; // Use prefix
  static const String _dbName = 'soundmarket.db';
  static const String _snapshotsTable = 'portfolio_snapshots';

  // Getter for the database instance
  Future<sqflite.Database> get database async {
    // Use prefix
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<sqflite.Database> _initDatabase() async {
    // Use prefix
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await sqflite.openDatabase(
      // Use prefix
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create database table
  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Use prefix
    await db.execute('''
      CREATE TABLE $_snapshotsTable (
        timestamp INTEGER PRIMARY KEY,
        value REAL NOT NULL
      )
    ''');
    // Add index for faster range queries
    await db.execute(
      'CREATE INDEX idx_timestamp ON $_snapshotsTable (timestamp)',
    );
  }

  // --- User Profile, Portfolio, Transactions (using SharedPreferences) ---

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
      return portfolioList.map((item) => PortfolioItem.fromJson(item)).toList();
    } catch (e) {
      print('Error loading portfolio: $e');
      return [];
    }
  }

  // Save transactions to local storage
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJsonList =
        transactions.map((item) => item.toJson()).toList();
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

  // --- Portfolio History (Snapshots using SQLite) ---

  // Save a single portfolio snapshot to the database
  Future<void> savePortfolioSnapshot(PortfolioSnapshot snapshot) async {
    final db = await database;
    await db.insert(
      _snapshotsTable,
      {
        'timestamp': snapshot.timestamp.millisecondsSinceEpoch,
        'value': snapshot.value,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace, // Use prefix
    );
  }

  // Load portfolio history snapshots within a specific date range
  Future<List<PortfolioSnapshot>> loadPortfolioHistoryRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startMillis = start.millisecondsSinceEpoch;
    // Ensure end time includes the whole day
    final endMillis = end.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      _snapshotsTable,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startMillis, endMillis],
      orderBy: 'timestamp ASC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return PortfolioSnapshot(
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        value: maps[i]['value'],
      );
    });
  }

  // Get the timestamp of the earliest snapshot
  Future<DateTime?> getEarliestTimestamp() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      _snapshotsTable,
      columns: ['MIN(timestamp) as min_timestamp'],
    );

    if (result.isNotEmpty && result.first['min_timestamp'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(result.first['min_timestamp']);
    }
    return null;
  }

  // --- Save and Load Songs ---

  // Save songs to local storage
  Future<void> saveSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final songsJsonList = songs.map((song) => song.toJson()).toList();
    final songsJson = jsonEncode(songsJsonList);
    await prefs.setString(_songsKey, songsJson);
  }

  // Load songs from local storage
  Future<List<Song>> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = prefs.getString(_songsKey);

    if (songsJson == null) {
      return [];
    }

    try {
      final List<dynamic> songsList = jsonDecode(songsJson);
      return songsList.map((item) => Song.fromJson(item)).toList();
    } catch (e) {
      print('Error loading songs: $e');
      return [];
    }
  }

  // --- Combined Load/Save/Clear ---

  // Save user profile, portfolio, transactions, and songs (History saved separately)
  Future<void> saveUserData({
    required UserProfile profile,
    required List<PortfolioItem> portfolio,
    required List<Transaction> transactions,
    List<Song>? songs, // Add optional songs parameter
    // Note: History is no longer saved in bulk here
  }) async {
    await saveUserProfile(profile);
    await savePortfolio(portfolio);
    await saveTransactions(transactions);
    if (songs != null) {
      await saveSongs(songs);
    }
  }

  // Load user profile, portfolio, transactions, and songs (History loaded on demand)
  Future<Map<String, dynamic>> loadUserData() async {
    final profile = await loadUserProfile();
    final portfolio = await loadPortfolio();
    final transactions = await loadTransactions();
    final songs = await loadSongs();
    // Note: History is not loaded here anymore

    return {
      'profile': profile,
      'portfolio': portfolio,
      'transactions': transactions,
      'songs': songs, // Add songs to the returned data
      // 'history': history, // Removed history loading
    };
  }

  // Clear all stored data (SharedPreferences and SQLite table)
  Future<void> clearAllData() async {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
    await prefs.remove(_portfolioKey);
    await prefs.remove(_transactionsKey);
    await prefs.remove(_songsKey); // Also clear saved songs

    // Clear SQLite table
    try {
      final db = await database;
      await db.delete(_snapshotsTable);
    } catch (e) {
      print('Error clearing portfolio snapshots table: $e');
      // Optionally delete the whole database file if clearing fails consistently
      // final documentsDirectory = await getApplicationDocumentsDirectory();
      // final path = join(documentsDirectory.path, _dbName);
      // await deleteDatabase(path);
      // _database = null; // Reset database instance
    }
  }
}
