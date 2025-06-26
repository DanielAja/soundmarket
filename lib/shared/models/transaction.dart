class Transaction {
  final String id;
  final String songId;
  final String songName;
  final String artistName;
  final TransactionType type;
  final int quantity;
  final double price;
  final DateTime timestamp;
  final String? albumArtUrl;

  Transaction({
    required this.id,
    required this.songId,
    required this.songName,
    required this.artistName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.timestamp,
    this.albumArtUrl,
  });

  // Calculate total value of the transaction
  double get totalValue => quantity * price;

  // Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? songId,
    String? songName,
    String? artistName,
    TransactionType? type,
    int? quantity,
    double? price,
    DateTime? timestamp,
    String? albumArtUrl,
  }) {
    return Transaction(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'songName': songName,
      'artistName': artistName,
      'type': type.toString(),
      'quantity': quantity,
      'price': price,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'albumArtUrl': albumArtUrl,
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      songId: json['songId'],
      songName: json['songName'],
      artistName: json['artistName'],
      type:
          json['type'] == 'TransactionType.buy'
              ? TransactionType.buy
              : TransactionType.sell,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      albumArtUrl: json['albumArtUrl'],
    );
  }
}

enum TransactionType { buy, sell }
