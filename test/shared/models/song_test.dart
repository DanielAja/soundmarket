import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/shared/models/song.dart';
import 'package:soundmarket/shared/services/pricing_engine.dart';

void main() {
  group('Song Model Tests', () {
    final testSong = Song(
      id: 'test-song-id',
      name: 'Test Song',
      artist: 'Test Artist',
      genre: 'Pop',
      currentPrice: 15.50,
      previousPrice: 14.00,
      albumArtUrl: 'https://example.com/album.jpg',
      allTimeStreams: 1000000,
      lastFiveYearsStreams: 800000,
      yearlyStreams: 500000,
      monthlyStreams: 100000,
      weeklyStreams: 25000,
      dailyStreams: 5000,
      totalStreams: 1000000,
      basePricePerStream: 0.001,
      lastPriceUpdate: DateTime(2024, 1, 1),
    );

    test('should create Song with all properties', () {
      expect(testSong.id, equals('test-song-id'));
      expect(testSong.name, equals('Test Song'));
      expect(testSong.artist, equals('Test Artist'));
      expect(testSong.genre, equals('Pop'));
      expect(testSong.currentPrice, equals(15.50));
      expect(testSong.previousPrice, equals(14.00));
      expect(testSong.albumArtUrl, equals('https://example.com/album.jpg'));
      expect(testSong.allTimeStreams, equals(1000000));
      expect(testSong.lastFiveYearsStreams, equals(800000));
      expect(testSong.yearlyStreams, equals(500000));
      expect(testSong.monthlyStreams, equals(100000));
      expect(testSong.weeklyStreams, equals(25000));
      expect(testSong.dailyStreams, equals(5000));
      expect(testSong.totalStreams, equals(1000000));
      expect(testSong.basePricePerStream, equals(0.001));
      expect(testSong.lastPriceUpdate, equals(DateTime(2024, 1, 1)));
    });

    test('should create Song with default values', () {
      final minimalSong = Song(
        id: 'minimal-id',
        name: 'Minimal Song',
        artist: 'Minimal Artist',
        genre: 'Rock',
        currentPrice: 10.00,
      );

      expect(minimalSong.previousPrice, equals(0.0));
      expect(minimalSong.albumArtUrl, isNull);
      expect(minimalSong.allTimeStreams, equals(0));
      expect(minimalSong.lastFiveYearsStreams, equals(0));
      expect(minimalSong.yearlyStreams, equals(0));
      expect(minimalSong.monthlyStreams, equals(0));
      expect(minimalSong.weeklyStreams, equals(0));
      expect(minimalSong.dailyStreams, equals(0));
      expect(minimalSong.totalStreams, equals(0));
      expect(minimalSong.basePricePerStream, equals(0.001));
      expect(minimalSong.lastPriceUpdate, isNull);
    });

    test('should calculate price change percentage correctly', () {
      // Price increased from 14.00 to 15.50
      expect(testSong.priceChangePercent, closeTo(10.71, 0.01));

      // No previous price
      final noPreviousPrice = Song(
        id: 'test',
        name: 'Test',
        artist: 'Test',
        genre: 'Test',
        currentPrice: 10.00,
        previousPrice: 0.0,
      );
      expect(noPreviousPrice.priceChangePercent, equals(0.0));

      // Price decreased
      final decreasedPrice = Song(
        id: 'test',
        name: 'Test',
        artist: 'Test',
        genre: 'Test',
        currentPrice: 8.00,
        previousPrice: 10.00,
      );
      expect(decreasedPrice.priceChangePercent, equals(-20.0));
    });

    test('should determine if price is up correctly', () {
      expect(testSong.isPriceUp, isTrue);

      final priceDown = Song(
        id: 'test',
        name: 'Test',
        artist: 'Test',
        genre: 'Test',
        currentPrice: 8.00,
        previousPrice: 10.00,
      );
      expect(priceDown.isPriceUp, isFalse);

      final samePrice = Song(
        id: 'test',
        name: 'Test',
        artist: 'Test',
        genre: 'Test',
        currentPrice: 10.00,
        previousPrice: 10.00,
      );
      expect(samePrice.isPriceUp, isFalse);
    });

    test('should calculate bell curve price correctly using PricingEngine', () {
      final calculatedPrice = PricingEngine.calculatePrice(testSong);
      
      // Verify the price is calculated (should be > 0 for songs with streams)
      expect(calculatedPrice, greaterThan(0.0));
      
      // Verify it uses the bell curve algorithm (price should reflect stream counts)
      final breakdown = PricingEngine.getPricingBreakdown(testSong);
      expect(breakdown['final_price'], isA<double>());
      expect(breakdown['popularity_score'], isA<double>());
      expect(breakdown['bell_curve_base'], isA<double>());
      
      // Verify price is reasonable for the stream count (1M streams) with bell curve
      // 1M streams should map to moderate popularity, affordable for $1000 budget
      expect(calculatedPrice, greaterThan(0.10));
      expect(calculatedPrice, lessThan(3000.0));
    });

    test('should calculate dynamic base price per stream correctly using PricingEngine', () {
      // Test with very low streams (below 1K threshold)
      final veryLowBasePricePerStream = PricingEngine.calculateDynamicBasePricePerStream(500);
      expect(veryLowBasePricePerStream, equals(0.0001));

      // Test with low streams (1K-100K range)
      final lowBasePricePerStream = PricingEngine.calculateDynamicBasePricePerStream(50000);
      expect(lowBasePricePerStream, greaterThan(0.0001));
      expect(lowBasePricePerStream, lessThan(0.001));

      // Test with high streams (above 100M)
      final highBasePricePerStream = PricingEngine.calculateDynamicBasePricePerStream(200000000);
      expect(highBasePricePerStream, greaterThan(0.008)); // Should be higher due to new scaling
      expect(highBasePricePerStream, lessThan(0.015));

      // Test with medium streams (should be between min and max)
      final mediumBasePricePerStream = PricingEngine.calculateDynamicBasePricePerStream(10000000);
      expect(mediumBasePricePerStream, greaterThan(0.001));
      expect(mediumBasePricePerStream, lessThan(0.010));
    });

    test('should handle zero streams in dynamic pricing using PricingEngine', () {
      final zeroBasePricePerStream = PricingEngine.calculateDynamicBasePricePerStream(0);
      expect(zeroBasePricePerStream, equals(0.0001));
    });

    test('should create copy with updated fields', () {
      final updatedSong = testSong.copyWith(
        name: 'Updated Song',
        currentPrice: 20.00,
        allTimeStreams: 2000000,
      );

      expect(updatedSong.id, equals(testSong.id));
      expect(updatedSong.name, equals('Updated Song'));
      expect(updatedSong.artist, equals(testSong.artist));
      expect(updatedSong.currentPrice, equals(20.00));
      expect(updatedSong.previousPrice, equals(testSong.currentPrice)); // Should be set to previous current price
      expect(updatedSong.allTimeStreams, equals(2000000));
      expect(updatedSong.lastFiveYearsStreams, equals(testSong.lastFiveYearsStreams));
    });

    test('should handle explicit previous price in copyWith', () {
      final updatedSong = testSong.copyWith(
        currentPrice: 20.00,
        previousPrice: 16.00,
      );

      expect(updatedSong.currentPrice, equals(20.00));
      expect(updatedSong.previousPrice, equals(16.00)); // Should use explicit value
    });

    test('should implement equality correctly', () {
      final song1 = Song(
        id: 'same-id',
        name: 'Song 1',
        artist: 'Artist 1',
        genre: 'Genre 1',
        currentPrice: 10.0,
      );

      final song2 = Song(
        id: 'same-id',
        name: 'Song 2',
        artist: 'Artist 2',
        genre: 'Genre 2',
        currentPrice: 20.0,
      );

      final song3 = Song(
        id: 'different-id',
        name: 'Song 3',
        artist: 'Artist 3',
        genre: 'Genre 3',
        currentPrice: 30.0,
      );

      expect(song1, equals(song2)); // Same ID
      expect(song1, isNot(equals(song3))); // Different ID
      expect(song1.hashCode, equals(song2.hashCode));
      expect(song1.hashCode, isNot(equals(song3.hashCode)));
    });

    test('should serialize to JSON correctly', () {
      final json = testSong.toJson();

      expect(json['id'], equals('test-song-id'));
      expect(json['name'], equals('Test Song'));
      expect(json['artist'], equals('Test Artist'));
      expect(json['genre'], equals('Pop'));
      expect(json['currentPrice'], equals(15.50));
      expect(json['previousPrice'], equals(14.00));
      expect(json['albumArtUrl'], equals('https://example.com/album.jpg'));
      expect(json['allTimeStreams'], equals(1000000));
      expect(json['lastFiveYearsStreams'], equals(800000));
      expect(json['yearlyStreams'], equals(500000));
      expect(json['monthlyStreams'], equals(100000));
      expect(json['weeklyStreams'], equals(25000));
      expect(json['dailyStreams'], equals(5000));
      expect(json['totalStreams'], equals(1000000));
      expect(json['basePricePerStream'], equals(0.001));
      expect(json['lastPriceUpdate'], equals(DateTime(2024, 1, 1).millisecondsSinceEpoch));
    });

    test('should deserialize from JSON correctly', () {
      final json = testSong.toJson();
      final deserializedSong = Song.fromJson(json);

      expect(deserializedSong.id, equals(testSong.id));
      expect(deserializedSong.name, equals(testSong.name));
      expect(deserializedSong.artist, equals(testSong.artist));
      expect(deserializedSong.genre, equals(testSong.genre));
      expect(deserializedSong.currentPrice, equals(testSong.currentPrice));
      expect(deserializedSong.previousPrice, equals(testSong.previousPrice));
      expect(deserializedSong.albumArtUrl, equals(testSong.albumArtUrl));
      expect(deserializedSong.allTimeStreams, equals(testSong.allTimeStreams));
      expect(deserializedSong.lastFiveYearsStreams, equals(testSong.lastFiveYearsStreams));
      expect(deserializedSong.yearlyStreams, equals(testSong.yearlyStreams));
      expect(deserializedSong.monthlyStreams, equals(testSong.monthlyStreams));
      expect(deserializedSong.weeklyStreams, equals(testSong.weeklyStreams));
      expect(deserializedSong.dailyStreams, equals(testSong.dailyStreams));
      expect(deserializedSong.totalStreams, equals(testSong.totalStreams));
      expect(deserializedSong.basePricePerStream, equals(testSong.basePricePerStream));
      expect(deserializedSong.lastPriceUpdate, equals(testSong.lastPriceUpdate));
    });

    test('should handle null values in JSON deserialization', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Song',
        'artist': 'Test Artist',
        'genre': 'Test Genre',
        'currentPrice': 10.0,
        'previousPrice': null,
        'albumArtUrl': null,
        'allTimeStreams': null,
        'lastFiveYearsStreams': null,
        'yearlyStreams': null,
        'monthlyStreams': null,
        'weeklyStreams': null,
        'dailyStreams': null,
        'totalStreams': null,
        'basePricePerStream': null,
        'lastPriceUpdate': null,
      };

      final song = Song.fromJson(json);

      expect(song.previousPrice, equals(0.0));
      expect(song.albumArtUrl, isNull);
      expect(song.allTimeStreams, equals(0));
      expect(song.lastFiveYearsStreams, equals(0));
      expect(song.yearlyStreams, equals(0));
      expect(song.monthlyStreams, equals(0));
      expect(song.weeklyStreams, equals(0));
      expect(song.dailyStreams, equals(0));
      expect(song.totalStreams, equals(0));
      expect(song.basePricePerStream, equals(0.001));
      expect(song.lastPriceUpdate, isNull);
    });

    test('should handle number types in JSON deserialization', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Song',
        'artist': 'Test Artist',
        'genre': 'Test Genre',
        'currentPrice': 10, // int instead of double
        'previousPrice': 8, // int instead of double
        'albumArtUrl': 'test.jpg',
        'allTimeStreams': 1000000.0, // double instead of int
        'lastFiveYearsStreams': 800000.0, // double instead of int
        'yearlyStreams': 500000,
        'monthlyStreams': 100000,
        'weeklyStreams': 25000,
        'dailyStreams': 5000,
        'totalStreams': 1000000,
        'basePricePerStream': 0, // int instead of double
        'lastPriceUpdate': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      };

      final song = Song.fromJson(json);

      expect(song.currentPrice, equals(10.0));
      expect(song.previousPrice, equals(8.0));
      expect(song.allTimeStreams, equals(1000000));
      expect(song.lastFiveYearsStreams, equals(800000));
      expect(song.basePricePerStream, equals(0.0));
    });
  });
}