import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/shared/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    final testTransaction = Transaction(
      id: 'test-transaction-id',
      songId: 'test-song-id',
      songName: 'Test Song',
      artistName: 'Test Artist',
      type: TransactionType.buy,
      quantity: 5,
      price: 12.50,
      timestamp: DateTime(2024, 1, 1, 12, 30),
      albumArtUrl: 'https://example.com/album.jpg',
    );

    test('should create Transaction with all properties', () {
      expect(testTransaction.id, equals('test-transaction-id'));
      expect(testTransaction.songId, equals('test-song-id'));
      expect(testTransaction.songName, equals('Test Song'));
      expect(testTransaction.artistName, equals('Test Artist'));
      expect(testTransaction.type, equals(TransactionType.buy));
      expect(testTransaction.quantity, equals(5));
      expect(testTransaction.price, equals(12.50));
      expect(testTransaction.timestamp, equals(DateTime(2024, 1, 1, 12, 30)));
      expect(testTransaction.albumArtUrl, equals('https://example.com/album.jpg'));
    });

    test('should create Transaction with optional albumArtUrl as null', () {
      final transaction = Transaction(
        id: 'test-id',
        songId: 'song-id',
        songName: 'Song Name',
        artistName: 'Artist Name',
        type: TransactionType.sell,
        quantity: 3,
        price: 8.75,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(transaction.albumArtUrl, isNull);
    });

    test('should calculate total value correctly', () {
      expect(testTransaction.totalValue, equals(62.50)); // 5 * 12.50

      final sellTransaction = Transaction(
        id: 'sell-id',
        songId: 'song-id',
        songName: 'Song Name',
        artistName: 'Artist Name',
        type: TransactionType.sell,
        quantity: 3,
        price: 15.25,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(sellTransaction.totalValue, equals(45.75)); // 3 * 15.25
    });

    test('should handle zero quantity and price', () {
      final zeroTransaction = Transaction(
        id: 'zero-id',
        songId: 'song-id',
        songName: 'Song Name',
        artistName: 'Artist Name',
        type: TransactionType.buy,
        quantity: 0,
        price: 0.0,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(zeroTransaction.totalValue, equals(0.0));
    });

    test('should create copy with updated fields', () {
      final updatedTransaction = testTransaction.copyWith(
        quantity: 10,
        price: 15.00,
        type: TransactionType.sell,
      );

      expect(updatedTransaction.id, equals(testTransaction.id));
      expect(updatedTransaction.songId, equals(testTransaction.songId));
      expect(updatedTransaction.songName, equals(testTransaction.songName));
      expect(updatedTransaction.artistName, equals(testTransaction.artistName));
      expect(updatedTransaction.type, equals(TransactionType.sell));
      expect(updatedTransaction.quantity, equals(10));
      expect(updatedTransaction.price, equals(15.00));
      expect(updatedTransaction.timestamp, equals(testTransaction.timestamp));
      expect(updatedTransaction.albumArtUrl, equals(testTransaction.albumArtUrl));
    });

    test('should serialize to JSON correctly', () {
      final json = testTransaction.toJson();

      expect(json['id'], equals('test-transaction-id'));
      expect(json['songId'], equals('test-song-id'));
      expect(json['songName'], equals('Test Song'));
      expect(json['artistName'], equals('Test Artist'));
      expect(json['type'], equals('TransactionType.buy'));
      expect(json['quantity'], equals(5));
      expect(json['price'], equals(12.50));
      expect(json['timestamp'], equals(DateTime(2024, 1, 1, 12, 30).millisecondsSinceEpoch));
      expect(json['albumArtUrl'], equals('https://example.com/album.jpg'));
    });

    test('should serialize sell transaction type correctly', () {
      final sellTransaction = testTransaction.copyWith(type: TransactionType.sell);
      final json = sellTransaction.toJson();

      expect(json['type'], equals('TransactionType.sell'));
    });

    test('should deserialize from JSON correctly', () {
      final json = testTransaction.toJson();
      final deserializedTransaction = Transaction.fromJson(json);

      expect(deserializedTransaction.id, equals(testTransaction.id));
      expect(deserializedTransaction.songId, equals(testTransaction.songId));
      expect(deserializedTransaction.songName, equals(testTransaction.songName));
      expect(deserializedTransaction.artistName, equals(testTransaction.artistName));
      expect(deserializedTransaction.type, equals(testTransaction.type));
      expect(deserializedTransaction.quantity, equals(testTransaction.quantity));
      expect(deserializedTransaction.price, equals(testTransaction.price));
      expect(deserializedTransaction.timestamp, equals(testTransaction.timestamp));
      expect(deserializedTransaction.albumArtUrl, equals(testTransaction.albumArtUrl));
    });

    test('should deserialize buy transaction type correctly', () {
      final json = {
        'id': 'test-id',
        'songId': 'song-id',
        'songName': 'Song Name',
        'artistName': 'Artist Name',
        'type': 'TransactionType.buy',
        'quantity': 3,
        'price': 10.0,
        'timestamp': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'albumArtUrl': null,
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.type, equals(TransactionType.buy));
    });

    test('should deserialize sell transaction type correctly', () {
      final json = {
        'id': 'test-id',
        'songId': 'song-id',
        'songName': 'Song Name',
        'artistName': 'Artist Name',
        'type': 'TransactionType.sell',
        'quantity': 3,
        'price': 10.0,
        'timestamp': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'albumArtUrl': null,
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.type, equals(TransactionType.sell));
    });

    test('should handle unknown transaction type in JSON', () {
      final json = {
        'id': 'test-id',
        'songId': 'song-id',
        'songName': 'Song Name',
        'artistName': 'Artist Name',
        'type': 'TransactionType.unknown',
        'quantity': 3,
        'price': 10.0,
        'timestamp': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'albumArtUrl': null,
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.type, equals(TransactionType.sell)); // Defaults to sell
    });

    test('should handle null albumArtUrl in JSON deserialization', () {
      final json = {
        'id': 'test-id',
        'songId': 'song-id',
        'songName': 'Song Name',
        'artistName': 'Artist Name',
        'type': 'TransactionType.buy',
        'quantity': 3,
        'price': 10.0,
        'timestamp': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'albumArtUrl': null,
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.albumArtUrl, isNull);
    });

    test('should handle number types in JSON deserialization', () {
      final json = {
        'id': 'test-id',
        'songId': 'song-id',
        'songName': 'Song Name',
        'artistName': 'Artist Name',
        'type': 'TransactionType.buy',
        'quantity': 3.0, // double instead of int
        'price': 10, // int instead of double
        'timestamp': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'albumArtUrl': 'test.jpg',
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.quantity, equals(3));
      expect(transaction.price, equals(10.0));
    });
  });

  group('TransactionType Enum Tests', () {
    test('should have correct values', () {
      expect(TransactionType.values.length, equals(2));
      expect(TransactionType.values, contains(TransactionType.buy));
      expect(TransactionType.values, contains(TransactionType.sell));
    });

    test('should convert to string correctly', () {
      expect(TransactionType.buy.toString(), equals('TransactionType.buy'));
      expect(TransactionType.sell.toString(), equals('TransactionType.sell'));
    });
  });
}