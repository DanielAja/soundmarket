class Song {
  final String id;
  final String name;
  final String artist;
  final String genre;
  double currentPrice; // Removed final to allow updates
  double previousPrice; // Removed final to allow updates
  final String? albumArtUrl;

  // Stream counts for different time periods
  int yearlyStreams = 0;
  int monthlyStreams = 0;
  int weeklyStreams = 0;
  int dailyStreams = 0;
  int totalStreams = 0;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.genre,
    required this.currentPrice,
    this.previousPrice = 0.0,
    this.albumArtUrl,
    this.yearlyStreams = 0,
    this.monthlyStreams = 0,
    this.weeklyStreams = 0,
    this.dailyStreams = 0,
    this.totalStreams = 0,
  });

  // Calculate price change percentage
  double get priceChangePercent {
    if (previousPrice == 0) return 0;
    return ((currentPrice - previousPrice) / previousPrice) * 100;
  }

  // Determine if price is up or down
  bool get isPriceUp => currentPrice > previousPrice;

  // Create a copy with updated fields
  Song copyWith({
    String? id,
    String? name,
    String? artist,
    String? genre,
    double? currentPrice,
    double? previousPrice,
    String? albumArtUrl,
    int? yearlyStreams,
    int? monthlyStreams,
    int? weeklyStreams,
    int? dailyStreams,
    int? totalStreams,
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
      yearlyStreams: yearlyStreams ?? this.yearlyStreams,
      monthlyStreams: monthlyStreams ?? this.monthlyStreams,
      weeklyStreams: weeklyStreams ?? this.weeklyStreams,
      dailyStreams: dailyStreams ?? this.dailyStreams,
      totalStreams: totalStreams ?? this.totalStreams,
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
      'yearlyStreams': yearlyStreams,
      'monthlyStreams': monthlyStreams,
      'weeklyStreams': weeklyStreams,
      'dailyStreams': dailyStreams,
      'totalStreams': totalStreams,
    };
  }

  // Create from JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      genre: json['genre'],
      currentPrice: json['currentPrice'],
      previousPrice: json['previousPrice'] ?? 0.0,
      albumArtUrl: json['albumArtUrl'],
      yearlyStreams: json['yearlyStreams'] ?? 0,
      monthlyStreams: json['monthlyStreams'] ?? 0,
      weeklyStreams: json['weeklyStreams'] ?? 0,
      dailyStreams: json['dailyStreams'] ?? 0,
      totalStreams: json['totalStreams'] ?? 0,
    );
  }
}
