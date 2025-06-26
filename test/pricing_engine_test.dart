import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/shared/models/song.dart';
import 'package:soundmarket/shared/services/pricing_engine.dart';

void main() {
  group('PricingEngine Tests', () {
    test(
      'calculateDynamicBasePricePerStream should scale based on total streams',
      () {
        // Test very low stream count (below 1K threshold)
        double veryLowStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(500);
        expect(veryLowStreamPrice, equals(0.0001)); // Minimum base price

        // Test low stream count (1K-100K range)
        double lowStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(50000);
        expect(lowStreamPrice, greaterThan(0.0001));
        expect(lowStreamPrice, lessThan(0.001));

        // Test high stream count (above 100M)
        double highStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(200000000);
        expect(highStreamPrice, greaterThan(0.008)); // Higher due to new scaling
        expect(highStreamPrice, lessThan(0.015));

        // Test medium stream count (should be between min and max)
        double mediumStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(10000000);
        expect(mediumStreamPrice, greaterThan(0.001));
        expect(mediumStreamPrice, lessThan(0.010));

        // Test that higher stream counts get higher base prices
        double lowerStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(1000000);
        double higherStreamPrice =
            PricingEngine.calculateDynamicBasePricePerStream(50000000);
        expect(higherStreamPrice, greaterThan(lowerStreamPrice));
      },
    );

    test('calculatePrice should use bell curve pricing correctly', () {
      // Create a test song with moderate stream data for bell curve testing
      final song = Song(
        id: 'test-song-1',
        name: 'Test Song',
        artist: 'Test Artist',
        genre: 'pop', // Use pop genre for predictable multiplier
        currentPrice: 10.0,
        allTimeStreams: 500000, // 500K streams - moderate level
        lastFiveYearsStreams: 250000,
        yearlyStreams: 50000,
        monthlyStreams: 5000,
        dailyStreams: 500,
        basePricePerStream: 0.001,
      );

      final calculatedPrice = PricingEngine.calculatePrice(song);

      // With bell curve pricing, expect prices in reasonable bell curve range
      // 500K streams should map to moderate popularity score
      // Should be in affordable range for $1000 budget
      expect(calculatedPrice, greaterThan(0.10)); // Above minimum
      expect(calculatedPrice, lessThan(2000.0)); // Within reasonable range
      
      // Verify dynamic base price calculation still works
      double expectedBasePricePerStream =
          PricingEngine.calculateDynamicBasePricePerStream(500000);
      expect(expectedBasePricePerStream, greaterThan(0.0001));
    });

    test('calculatePrice should handle zero streams with soft minimum', () {
      final song = Song(
        id: 'test-song-2',
        name: 'Low Stream Song',
        artist: 'Test Artist',
        genre: 'classical', // Use classical for lower multiplier
        currentPrice: 5.0,
        allTimeStreams: 0,
        lastFiveYearsStreams: 0,
        yearlyStreams: 0,
        monthlyStreams: 0,
        dailyStreams: 0,
        basePricePerStream: 0.001,
      );

      final calculatedPrice = PricingEngine.calculatePrice(song);

      // With bell curve, zero streams should still have a small price (soft minimum)
      expect(calculatedPrice, greaterThan(0.05)); // Above absolute minimum
      expect(calculatedPrice, lessThan(5.0)); // But still very low
    });

    test('calculatePrice should handle very high streams with soft maximum', () {
      final song = Song(
        id: 'test-song-3',
        name: 'Viral Hit Song',
        artist: 'Mega Artist',
        genre: 'hip-hop', // Use hip-hop for higher multiplier
        currentPrice: 500.0,
        allTimeStreams: 1000000000, // 1B streams - viral hit
        lastFiveYearsStreams: 500000000,
        yearlyStreams: 100000000,
        monthlyStreams: 50000000,
        dailyStreams: 10000000,
        basePricePerStream: 0.01,
      );

      final calculatedPrice = PricingEngine.calculatePrice(song);

      // With bell curve, very high streams should be expensive but not unlimited
      // Should be in high-end of bell curve (above $2000 but with soft cap)
      expect(calculatedPrice, greaterThan(1000.0)); // High price for viral hit
      expect(calculatedPrice, lessThan(15000.0)); // Soft maximum applies
    });

    test(
      'updateSongPrice should update price, basePricePerStream, and timestamp',
      () {
        final originalTime = DateTime.now().subtract(const Duration(hours: 1));

        final song = Song(
          id: 'test-song-4',
          name: 'Update Test Song',
          artist: 'Test Artist',
          genre: 'Test Genre',
          currentPrice: 10.0,
          previousPrice: 8.0,
          allTimeStreams: 1000000,
          lastFiveYearsStreams: 800000,
          yearlyStreams: 500000,
          monthlyStreams: 100000,
          dailyStreams: 10000,
          basePricePerStream: 0.001, // Static base price
          lastPriceUpdate: originalTime,
        );

        final updatedSong = PricingEngine.updateSongPrice(song);

        // Should update the price
        expect(updatedSong.currentPrice, isNot(equals(10.0)));

        // Should update the base price per stream to dynamic value
        double expectedDynamicBasePricePerStream =
            PricingEngine.calculateDynamicBasePricePerStream(1000000);
        expect(
          updatedSong.basePricePerStream,
          equals(expectedDynamicBasePricePerStream),
        );
        expect(
          updatedSong.basePricePerStream,
          isNot(equals(0.001)),
        ); // Should be different from static value

        // Should update the timestamp
        expect(updatedSong.lastPriceUpdate, isNotNull);
        expect(updatedSong.lastPriceUpdate!.isAfter(originalTime), isTrue);

        // Should preserve previous price
        expect(updatedSong.previousPrice, equals(10.0));
      },
    );

    test('validateStreamData should check stream consistency', () {
      // Valid stream data (newer periods ≤ older periods)
      final validSong = Song(
        id: 'valid-song',
        name: 'Valid Song',
        artist: 'Test Artist',
        genre: 'Test Genre',
        currentPrice: 10.0,
        allTimeStreams: 10000000,
        lastFiveYearsStreams: 5000000,
        yearlyStreams: 1000000,
        monthlyStreams: 100000,
        dailyStreams: 10000,
      );

      expect(PricingEngine.validateStreamData(validSong), isTrue);

      // Invalid stream data (daily > monthly)
      final invalidSong = Song(
        id: 'invalid-song',
        name: 'Invalid Song',
        artist: 'Test Artist',
        genre: 'Test Genre',
        currentPrice: 10.0,
        allTimeStreams: 10000000,
        lastFiveYearsStreams: 5000000,
        yearlyStreams: 1000000,
        monthlyStreams: 10000,
        dailyStreams: 50000, // Invalid: daily > monthly
      );

      expect(PricingEngine.validateStreamData(invalidSong), isFalse);
    });

    test('getAlgorithmWeights should return correct weights', () {
      final weights = PricingEngine.getAlgorithmWeights();

      expect(weights['all_time'], equals(0.50));
      expect(weights['five_years'], equals(0.30));
      expect(weights['yearly'], equals(0.10));
      expect(weights['monthly'], equals(0.05));
      expect(weights['daily'], equals(0.05));

      // Weights should sum to 1.0
      final totalWeight = weights.values.reduce((a, b) => a + b);
      expect(totalWeight, equals(1.0));
    });

    test('getPricingBreakdown should provide detailed analysis', () {
      final song = Song(
        id: 'breakdown-song',
        name: 'Breakdown Song',
        artist: 'Test Artist',
        genre: 'Test Genre',
        currentPrice: 10.0,
        allTimeStreams: 300000, // Reduced to avoid hitting max price
        lastFiveYearsStreams: 200000,
        yearlyStreams: 100000,
        monthlyStreams: 10000,
        dailyStreams: 1000,
        basePricePerStream: 0.001,
      );

      final breakdown = PricingEngine.getPricingBreakdown(song);

      expect(breakdown['song_id'], equals('breakdown-song'));
      expect(breakdown['song_name'], equals('Breakdown Song'));
      expect(breakdown['stream_data'], isA<Map<String, dynamic>>());
      expect(breakdown['contributions'], isA<Map<String, dynamic>>());
      expect(breakdown['final_price'], isA<double>());
      expect(breakdown['base_price_per_stream'], isA<double>());
      expect(
        breakdown['static_base_price_per_stream'],
        equals(0.001),
      ); // Static comparison value

      // Dynamic base price should be different from static value for 300K streams
      double dynamicBasePricePerStream =
          breakdown['base_price_per_stream'] as double;
      expect(dynamicBasePricePerStream, isNot(equals(0.001)));
      expect(
        dynamicBasePricePerStream,
        greaterThan(0.0001),
      ); // Should be higher than minimum for 300K streams

      // Check that bell curve pricing metrics are present
      expect(breakdown['popularity_score'], isA<double>());
      expect(breakdown['bell_curve_base'], isA<double>());
      expect(breakdown['market_multiplier'], isA<double>());
      
      // Popularity score should be reasonable for 300K streams
      double popularityScore = breakdown['popularity_score'] as double;
      expect(popularityScore, greaterThan(0.0));
      expect(popularityScore, lessThan(1.0));
      
      // Bell curve base price should be reasonable
      double bellCurveBase = breakdown['bell_curve_base'] as double;
      expect(bellCurveBase, greaterThanOrEqualTo(0.10)); // Allow exactly 0.10
      expect(bellCurveBase, lessThan(5000.0));
    });
  });
}
