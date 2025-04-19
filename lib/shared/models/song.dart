class Song {
  final String id;
  final String name;
  final String artist;
  final String genre;
  double currentPrice; // Removed final to allow updates
  double previousPrice; // Removed final to allow updates
  final String? albumArtUrl;
  
  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.genre,
    required this.currentPrice,
    this.previousPrice = 0.0,
    this.albumArtUrl,
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
  }) {
    // If currentPrice is being updated, set previousPrice to the current currentPrice 
    // if previousPrice parameter wasn't explicitly provided
    double newPreviousPrice = previousPrice ?? 
                             (currentPrice != null ? this.currentPrice : this.previousPrice);
    
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      currentPrice: currentPrice ?? this.currentPrice,
      previousPrice: newPreviousPrice,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
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
    );
  }
}
