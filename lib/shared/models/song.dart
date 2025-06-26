class Song {
  final String id;
  final String name;
  final String artist;
  final String genre;
  double currentPrice; // Removed final to allow updates
  double previousPrice; // Removed final to allow updates
  final String? albumArtUrl;
  final String? previewUrl;
  final String? spotifyExternalUrl;

  // Stream counts for different time periods (for pricing algorithm)
  int allTimeStreams = 0;
  int lastFiveYearsStreams = 0;
  int yearlyStreams = 0;
  int monthlyStreams = 0;
  int weeklyStreams = 0;
  int dailyStreams = 0;
  int totalStreams = 0; // Kept for backward compatibility

  // Pricing algorithm metadata
  double basePricePerStream = 0.001; // Base price per stream
  DateTime? lastPriceUpdate;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.genre,
    required this.currentPrice,
    this.previousPrice = 0.0,
    this.albumArtUrl,
    this.previewUrl,
    this.spotifyExternalUrl,
    this.allTimeStreams = 0,
    this.lastFiveYearsStreams = 0,
    this.yearlyStreams = 0,
    this.monthlyStreams = 0,
    this.weeklyStreams = 0,
    this.dailyStreams = 0,
    this.totalStreams = 0,
    this.basePricePerStream = 0.001,
    this.lastPriceUpdate,
  });

  // Calculate price change percentage
  double get priceChangePercent {
    if (previousPrice == 0) return 0;
    return ((currentPrice - previousPrice) / previousPrice) * 100;
  }

  // Determine if price is up or down
  bool get isPriceUp => currentPrice > previousPrice;

  // Note: Price calculation is now handled by PricingEngine service
  // This removes duplicate logic and centralizes pricing calculations

  // Create a copy with updated fields
  Song copyWith({
    String? id,
    String? name,
    String? artist,
    String? genre,
    double? currentPrice,
    double? previousPrice,
    String? albumArtUrl,
    String? previewUrl,
    String? spotifyExternalUrl,
    int? allTimeStreams,
    int? lastFiveYearsStreams,
    int? yearlyStreams,
    int? monthlyStreams,
    int? weeklyStreams,
    int? dailyStreams,
    int? totalStreams,
    double? basePricePerStream,
    DateTime? lastPriceUpdate,
  }) {
    // If currentPrice is being updated, set previousPrice to the current currentPrice
    // if previousPrice parameter wasn't explicitly provided
    double newPreviousPrice =
        previousPrice ??
        (currentPrice != null ? this.currentPrice : this.previousPrice);

    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      currentPrice: currentPrice ?? this.currentPrice,
      previousPrice: newPreviousPrice,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      spotifyExternalUrl: spotifyExternalUrl ?? this.spotifyExternalUrl,
      allTimeStreams: allTimeStreams ?? this.allTimeStreams,
      lastFiveYearsStreams: lastFiveYearsStreams ?? this.lastFiveYearsStreams,
      yearlyStreams: yearlyStreams ?? this.yearlyStreams,
      monthlyStreams: monthlyStreams ?? this.monthlyStreams,
      weeklyStreams: weeklyStreams ?? this.weeklyStreams,
      dailyStreams: dailyStreams ?? this.dailyStreams,
      totalStreams: totalStreams ?? this.totalStreams,
      basePricePerStream: basePricePerStream ?? this.basePricePerStream,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'genre': genre,
      'currentPrice': currentPrice,
      'previousPrice': previousPrice,
      'albumArtUrl': albumArtUrl,
      'previewUrl': previewUrl,
      'spotifyExternalUrl': spotifyExternalUrl,
      'allTimeStreams': allTimeStreams,
      'lastFiveYearsStreams': lastFiveYearsStreams,
      'yearlyStreams': yearlyStreams,
      'monthlyStreams': monthlyStreams,
      'weeklyStreams': weeklyStreams,
      'dailyStreams': dailyStreams,
      'totalStreams': totalStreams,
      'basePricePerStream': basePricePerStream,
      'lastPriceUpdate': lastPriceUpdate?.millisecondsSinceEpoch,
    };
  }

  // Create from JSON with proper type handling
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      genre: json['genre'],
      currentPrice: (json['currentPrice'] as num).toDouble(),
      previousPrice:
          json['previousPrice'] != null
              ? (json['previousPrice'] as num).toDouble()
              : 0.0,
      albumArtUrl: json['albumArtUrl'],
      previewUrl: json['previewUrl'],
      spotifyExternalUrl: json['spotifyExternalUrl'],
      allTimeStreams:
          json['allTimeStreams'] != null
              ? (json['allTimeStreams'] as num).toInt()
              : 0,
      lastFiveYearsStreams:
          json['lastFiveYearsStreams'] != null
              ? (json['lastFiveYearsStreams'] as num).toInt()
              : 0,
      yearlyStreams:
          json['yearlyStreams'] != null
              ? (json['yearlyStreams'] as num).toInt()
              : 0,
      monthlyStreams:
          json['monthlyStreams'] != null
              ? (json['monthlyStreams'] as num).toInt()
              : 0,
      weeklyStreams:
          json['weeklyStreams'] != null
              ? (json['weeklyStreams'] as num).toInt()
              : 0,
      dailyStreams:
          json['dailyStreams'] != null
              ? (json['dailyStreams'] as num).toInt()
              : 0,
      totalStreams:
          json['totalStreams'] != null
              ? (json['totalStreams'] as num).toInt()
              : 0,
      basePricePerStream:
          json['basePricePerStream'] != null
              ? (json['basePricePerStream'] as num).toDouble()
              : 0.001,
      lastPriceUpdate:
          json['lastPriceUpdate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['lastPriceUpdate'])
              : null,
    );
  }
}
