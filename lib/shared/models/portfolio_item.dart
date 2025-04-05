class PortfolioItem {
  final String songId;
  final String songName;
  final String artistName;
  int quantity;
  double purchasePrice; // Average purchase price
  String? albumArtUrl;
  
  PortfolioItem({
    required this.songId,
    required this.songName,
    required this.artistName,
    required this.quantity,
    required this.purchasePrice,
    this.albumArtUrl,
  });
  
  // Calculate the total value at purchase
  double get totalPurchaseValue => quantity * purchasePrice;
  
  // Calculate the current value (would need current price from elsewhere)
  double getCurrentValue(double currentPrice) => quantity * currentPrice;
  
  // Calculate profit/loss (would need current price from elsewhere)
  double getProfitLoss(double currentPrice) => 
      getCurrentValue(currentPrice) - totalPurchaseValue;
  
  // Create a copy with updated fields
  PortfolioItem copyWith({
    String? songId,
    String? songName,
    String? artistName,
    int? quantity,
    double? purchasePrice,
    String? albumArtUrl,
  }) {
    return PortfolioItem(
      songId: songId ?? this.songId,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'songName': songName,
      'artistName': artistName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'albumArtUrl': albumArtUrl,
    };
  }
  
  // Create from JSON (e.g., from storage)
  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      songId: json['songId'],
      songName: json['songName'],
      artistName: json['artistName'],
      quantity: json['quantity'],
      purchasePrice: json['purchasePrice'],
      albumArtUrl: json['albumArtUrl'],
    );
  }
}
