import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite; // Add prefix
import 'package:path/path.dart'; // Import path package
import '../models/user_profile.dart';
import '../models/portfolio_item.dart';
import '../models/transaction.dart';
import '../models/portfolio_snapshot.dart';
import '../models/song.dart';
import '../models/stream_history.dart';
import '../models/pricing_metrics.dart';

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
  static const String _streamHistoryTable = 'stream_history';
  static const String _pricingMetricsTable = 'pricing_metrics';

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
      version: 2, // Updated version for new tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Create stream history table
    await db.execute('''
      CREATE TABLE $_streamHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        stream_count INTEGER NOT NULL,
        period TEXT NOT NULL
      )
    ''');
    // Add indexes for stream history
    await db.execute(
      'CREATE INDEX idx_stream_song_id ON $_streamHistoryTable (song_id)',
    );
    await db.execute(
      'CREATE INDEX idx_stream_timestamp ON $_streamHistoryTable (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_stream_period ON $_streamHistoryTable (period)',
    );

    // Create pricing metrics table
    await db.execute('''
      CREATE TABLE $_pricingMetricsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        calculated_price REAL NOT NULL,
        previous_price REAL NOT NULL,
        price_change REAL NOT NULL,
        price_change_percent REAL NOT NULL,
        stream_breakdown TEXT NOT NULL,
        weighted_contributions TEXT NOT NULL,
        volatility_score REAL NOT NULL,
        was_price_clamped INTEGER NOT NULL
      )
    ''');
    // Add indexes for pricing metrics
    await db.execute(
      'CREATE INDEX idx_pricing_song_id ON $_pricingMetricsTable (song_id)',
    );
    await db.execute(
      'CREATE INDEX idx_pricing_timestamp ON $_pricingMetricsTable (timestamp)',
    );
  }

  // Handle database upgrades
  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add stream history table
      await db.execute('''
        CREATE TABLE $_streamHistoryTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          stream_count INTEGER NOT NULL,
          period TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_stream_song_id ON $_streamHistoryTable (song_id)',
      );
      await db.execute(
        'CREATE INDEX idx_stream_timestamp ON $_streamHistoryTable (timestamp)',
      );
      await db.execute(
        'CREATE INDEX idx_stream_period ON $_streamHistoryTable (period)',
      );

      // Add pricing metrics table
      await db.execute('''
        CREATE TABLE $_pricingMetricsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          calculated_price REAL NOT NULL,
          previous_price REAL NOT NULL,
          price_change REAL NOT NULL,
          price_change_percent REAL NOT NULL,
          stream_breakdown TEXT NOT NULL,
          weighted_contributions TEXT NOT NULL,
          volatility_score REAL NOT NULL,
          was_price_clamped INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_pricing_song_id ON $_pricingMetricsTable (song_id)',
      );
      await db.execute(
        'CREATE INDEX idx_pricing_timestamp ON $_pricingMetricsTable (timestamp)',
      );
    }
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
      final allSongs = songsList.map((item) => Song.fromJson(item)).toList();

      // Debug: Check how many songs have preview URLs
      int songsWithPreview = 0;
      int songsWithoutPreview = 0;

      for (final song in allSongs) {
        if (song.previewUrl != null && song.previewUrl!.isNotEmpty) {
          songsWithPreview++;
        } else {
          songsWithoutPreview++;
        }
      }

      print(
        '💾 Loaded ${allSongs.length} cached songs: $songsWithPreview with preview, $songsWithoutPreview without',
      );

      return allSongs;
    } catch (e) {
      print('Error loading songs: $e');
      return [];
    }
  }

  // Clear all cached songs
  Future<void> clearSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_songsKey);
    print('🗑️ Cleared all cached songs');
  }

  // Filter and save only songs with preview URLs
  Future<void> savePlayableSongs(List<Song> songs) async {
    final playableSongs =
        songs
            .where(
              (song) => song.previewUrl != null && song.previewUrl!.isNotEmpty,
            )
            .toList();

    print(
      '💾 Saving ${playableSongs.length} playable songs out of ${songs.length} total',
    );
    await saveSongs(playableSongs);
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

    // Clear SQLite tables
    try {
      final db = await database;
      await db.delete(_snapshotsTable);
      await db.delete(_streamHistoryTable);
      await db.delete(_pricingMetricsTable);
    } catch (e) {
      print('Error clearing database tables: $e');
      // Optionally delete the whole database file if clearing fails consistently
      // final documentsDirectory = await getApplicationDocumentsDirectory();
      // final path = join(documentsDirectory.path, _dbName);
      // await deleteDatabase(path);
      // _database = null; // Reset database instance
    }
  }

  // --- Stream History Operations ---

  // Save stream history entry
  Future<void> saveStreamHistory(StreamHistory streamHistory) async {
    final db = await database;
    await db.insert(_streamHistoryTable, {
      'song_id': streamHistory.songId,
      'timestamp': streamHistory.timestamp.millisecondsSinceEpoch,
      'stream_count': streamHistory.streamCount,
      'period': streamHistory.period,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  // Save multiple stream history entries
  Future<void> saveStreamHistoryBatch(
    List<StreamHistory> streamHistories,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final history in streamHistories) {
      batch.insert(_streamHistoryTable, {
        'song_id': history.songId,
        'timestamp': history.timestamp.millisecondsSinceEpoch,
        'stream_count': history.streamCount,
        'period': history.period,
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    }

    await batch.commit();
  }

  // Load stream history for a specific song
  Future<List<StreamHistory>> loadStreamHistory(
    String songId, {
    int? limit,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _streamHistoryTable,
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps
        .map(
          (map) => StreamHistory(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            streamCount: map['stream_count'],
            period: map['period'],
          ),
        )
        .toList();
  }

  // Load stream history within date range
  Future<List<StreamHistory>> loadStreamHistoryRange(
    String songId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      _streamHistoryTable,
      where: 'song_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [songId, startMillis, endMillis],
      orderBy: 'timestamp ASC',
    );

    return maps
        .map(
          (map) => StreamHistory(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            streamCount: map['stream_count'],
            period: map['period'],
          ),
        )
        .toList();
  }

  // Load all stream history for all songs (useful for pricing calculations)
  Future<List<StreamHistory>> loadAllStreamHistory({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _streamHistoryTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps
        .map(
          (map) => StreamHistory(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            streamCount: map['stream_count'],
            period: map['period'],
          ),
        )
        .toList();
  }

  // --- Pricing Metrics Operations ---

  // Save pricing metrics
  Future<void> savePricingMetrics(PricingMetrics metrics) async {
    final db = await database;
    await db.insert(_pricingMetricsTable, {
      'song_id': metrics.songId,
      'timestamp': metrics.timestamp.millisecondsSinceEpoch,
      'calculated_price': metrics.calculatedPrice,
      'previous_price': metrics.previousPrice,
      'price_change': metrics.priceChange,
      'price_change_percent': metrics.priceChangePercent,
      'stream_breakdown': jsonEncode(metrics.streamBreakdown),
      'weighted_contributions': jsonEncode(metrics.weightedContributions),
      'volatility_score': metrics.volatilityScore,
      'was_price_clamped': metrics.wasPriceClamped ? 1 : 0,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  // Load pricing metrics for a specific song
  Future<List<PricingMetrics>> loadPricingMetrics(
    String songId, {
    int? limit,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _pricingMetricsTable,
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps
        .map(
          (map) => PricingMetrics(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            calculatedPrice: map['calculated_price'],
            previousPrice: map['previous_price'],
            priceChange: map['price_change'],
            priceChangePercent: map['price_change_percent'],
            streamBreakdown: Map<String, int>.from(
              jsonDecode(map['stream_breakdown']),
            ),
            weightedContributions: Map<String, double>.from(
              jsonDecode(map['weighted_contributions']),
            ),
            volatilityScore: map['volatility_score'],
            wasPriceClamped: map['was_price_clamped'] == 1,
          ),
        )
        .toList();
  }

  // Load latest pricing metrics for all songs
  Future<List<PricingMetrics>> loadLatestPricingMetrics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p1.* FROM $_pricingMetricsTable p1
      INNER JOIN (
        SELECT song_id, MAX(timestamp) as max_timestamp
        FROM $_pricingMetricsTable
        GROUP BY song_id
      ) p2 ON p1.song_id = p2.song_id AND p1.timestamp = p2.max_timestamp
      ORDER BY p1.timestamp DESC
    ''');

    return maps
        .map(
          (map) => PricingMetrics(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            calculatedPrice: map['calculated_price'],
            previousPrice: map['previous_price'],
            priceChange: map['price_change'],
            priceChangePercent: map['price_change_percent'],
            streamBreakdown: Map<String, int>.from(
              jsonDecode(map['stream_breakdown']),
            ),
            weightedContributions: Map<String, double>.from(
              jsonDecode(map['weighted_contributions']),
            ),
            volatilityScore: map['volatility_score'],
            wasPriceClamped: map['was_price_clamped'] == 1,
          ),
        )
        .toList();
  }

  // Get pricing metrics within date range
  Future<List<PricingMetrics>> loadPricingMetricsRange(
    String songId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      _pricingMetricsTable,
      where: 'song_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [songId, startMillis, endMillis],
      orderBy: 'timestamp ASC',
    );

    return maps
        .map(
          (map) => PricingMetrics(
            songId: map['song_id'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
            calculatedPrice: map['calculated_price'],
            previousPrice: map['previous_price'],
            priceChange: map['price_change'],
            priceChangePercent: map['price_change_percent'],
            streamBreakdown: Map<String, int>.from(
              jsonDecode(map['stream_breakdown']),
            ),
            weightedContributions: Map<String, double>.from(
              jsonDecode(map['weighted_contributions']),
            ),
            volatilityScore: map['volatility_score'],
            wasPriceClamped: map['was_price_clamped'] == 1,
          ),
        )
        .toList();
  }
}
