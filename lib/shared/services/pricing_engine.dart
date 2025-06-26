import 'dart:math' as math;
import '../models/song.dart';
import '../models/stream_history.dart';
import 'pricing_engine_extensions.dart';

class PricingEngine {
  // Weighted algorithm constants based on user specification
  static const double _allTimeWeight = 0.50; // 50%
  static const double _fiveYearWeight = 0.30; // 30%
  static const double _yearlyWeight = 0.10; // 10%
  static const double _monthlyWeight = 0.05; // 5%
  static const double _dailyWeight = 0.05; // 5%

  // Bell curve pricing parameters - designed for $1000 starting budget

  // Bell curve distribution parameters - designed for $1000 starting budget
  static const double _meanPrice =
      500.0; // Center of bell curve - balanced for $1000 budget
  static const double _standardDeviation =
      800.0; // Wide distribution for price variety
  static const double _softMinPrice = 0.10; // Soft minimum (no hard floor)
  static const double _maxReasonablePrice =
      10000.0; // Soft maximum for extreme outliers

  /// Calculates the price for a song using the weighted streaming algorithm
  /// with market dynamics and volatility factors
  ///
  /// Algorithm breakdown:
  /// - 50% weight: All-time streams
  /// - 30% weight: Last 5 years streams
  /// - 10% weight: Last year streams
  /// - 5% weight: Last month streams
  /// - 5% weight: Last day streams
  /// - Dynamic base price per stream based on total streams
  /// - Genre-based pricing multipliers
  /// - Time-based momentum factors
  static double calculatePrice(Song song) {
    // Calculate dynamic base price per stream based on total streams
    double dynamicBasePricePerStream = calculateDynamicBasePricePerStream(
      song.allTimeStreams,
    );

    // Calculate weighted stream count
    double weightedStreamCount =
        (song.allTimeStreams * _allTimeWeight) +
        (song.lastFiveYearsStreams * _fiveYearWeight) +
        (song.yearlyStreams * _yearlyWeight) +
        (song.monthlyStreams * _monthlyWeight) +
        (song.dailyStreams * _dailyWeight);

    // Calculate base price using dynamic base price per stream
    double basePrice = weightedStreamCount * dynamicBasePricePerStream;

    // Apply market dynamics factors
    basePrice = PricingEngineMarketDynamics.applyMarketDynamics(
      basePrice,
      song,
    );

    // Convert to bell curve pricing
    double popularityScore = calculatePopularityScore(song.allTimeStreams);
    double bellCurvePrice = popularityScoreToPrice(popularityScore);

    // Apply market dynamics as multiplier (not additive)
    double marketMultiplier = _calculateMarketMultiplier(song);
    double finalPrice = bellCurvePrice * marketMultiplier;

    return double.parse(finalPrice.toStringAsFixed(2));
  }

  /// Calculates bell curve position based on stream count popularity
  /// Returns a value from 0.0 to 1.0 representing position in popularity distribution
  static double calculatePopularityScore(num totalStreams) {
    int streamCount = totalStreams.toInt();
    if (streamCount <= 0) return 0.0;

    // Use logarithmic scale to map streams to popularity score (0-1)
    // Most tracks have low streams, few have high streams (realistic distribution)
    double logStreams = math.log(streamCount + 1);
    double maxLogStreams = math.log(
      1000000000,
    ); // 1B streams as theoretical max

    double rawScore = logStreams / maxLogStreams;

    // Apply inverse transformation to create realistic distribution
    // Most tracks score low (0.0-0.3), fewer score high (0.7-1.0)
    double popularityScore =
        math.pow(rawScore, 2.5).toDouble(); // Exponential curve

    return popularityScore.clamp(0.0, 1.0);
  }

  /// Converts popularity score to bell curve price using normal distribution
  static double popularityScoreToPrice(double popularityScore) {
    // Convert popularity score (0-1) to position on bell curve
    // Use inverse normal distribution to create bell curve

    // Most tracks (popularityScore 0.0-0.4) map to affordable range ($1-$50)
    // Fewer tracks (0.4-0.8) map to mid range ($50-$150)
    // Rare tracks (0.8-1.0) map to premium range ($150+)

    if (popularityScore <= 0.0) {
      return _softMinPrice;
    }

    // Create bell curve using cumulative distribution function approximation
    double normalizedScore =
        popularityScore * 6.0 - 3.0; // Map to -3 to +3 standard deviations

    // Approximate normal CDF for bell curve shape
    double bellCurvePosition =
        0.5 * (1.0 + _erf(normalizedScore / math.sqrt(2)));

    // Map bell curve position to price range
    // 68% of tracks in $20-$1,300 range (1 std dev)
    // 95% of tracks in $5-$2,100 range (2 std dev)
    // 99.7% of tracks in $1-$2,900 range (3 std dev)
    double price =
        _meanPrice + (bellCurvePosition - 0.5) * _standardDeviation * 2.5;

    // Apply soft bounds - no hard limits, but gentle scaling for extremes
    if (price < _softMinPrice) {
      price =
          _softMinPrice +
          (price - _softMinPrice) * 0.1; // Soft compression for very low prices
    } else if (price > _maxReasonablePrice) {
      price =
          _maxReasonablePrice +
          (price - _maxReasonablePrice) *
              0.1; // Soft compression for very high prices
    }

    return math.max(price, _softMinPrice); // Ensure minimum playability
  }

  /// Error function approximation for normal distribution
  static double _erf(double x) {
    // Abramowitz and Stegun approximation
    double a1 = 0.254829592;
    double a2 = -0.284496736;
    double a3 = 1.421413741;
    double a4 = -1.453152027;
    double a5 = 1.061405429;
    double p = 0.3275911;

    int sign = x >= 0 ? 1 : -1;
    x = x.abs();

    double t = 1.0 / (1.0 + p * x);
    double y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  /// Updates a song's price using the pricing algorithm
  static Song updateSongPrice(Song song) {
    double newPrice = calculatePrice(song);
    double dynamicBasePricePerStream = calculateDynamicBasePricePerStream(
      song.allTimeStreams,
    );

    return song.copyWith(
      currentPrice: newPrice,
      basePricePerStream: dynamicBasePricePerStream,
      lastPriceUpdate: DateTime.now(),
    );
  }

  /// Calculates price from stream history data using bell curve distribution
  static double calculatePriceFromHistory(
    String songId,
    List<StreamHistory> streamHistory, {
    double?
    basePricePerStream, // Legacy parameter - not used in bell curve pricing
  }) {
    // All time streams (sum of all historical data)
    int allTimeStreams = streamHistory
        .where((h) => h.songId == songId)
        .fold(0, (sum, h) => sum + h.streamCount);

    // Use bell curve pricing based on total streams
    double popularityScore = calculatePopularityScore(allTimeStreams);
    double bellCurvePrice = popularityScoreToPrice(popularityScore);

    return double.parse(bellCurvePrice.toStringAsFixed(2));
  }

  /// Batch update prices for multiple songs
  static List<Song> updateMultipleSongPrices(List<Song> songs) {
    return songs.map((song) => updateSongPrice(song)).toList();
  }

  /// Calculate price volatility based on recent price changes
  static double calculatePriceVolatility(List<double> recentPrices) {
    if (recentPrices.length < 2) return 0.0;

    double sum = recentPrices.reduce((a, b) => a + b);
    double mean = sum / recentPrices.length;

    double variance =
        recentPrices
            .map((price) => (price - mean) * (price - mean))
            .reduce((a, b) => a + b) /
        recentPrices.length;

    return variance;
  }

  /// Get pricing algorithm weights for display/debugging
  static Map<String, double> getAlgorithmWeights() {
    return {
      'all_time': _allTimeWeight,
      'five_years': _fiveYearWeight,
      'yearly': _yearlyWeight,
      'monthly': _monthlyWeight,
      'daily': _dailyWeight,
    };
  }

  /// Validate if stream data is reasonable
  static bool validateStreamData(Song song) {
    // Check if stream counts are logical (newer periods should not exceed older ones)
    if (song.dailyStreams > song.monthlyStreams && song.monthlyStreams > 0) {
      return false;
    }
    if (song.monthlyStreams > song.yearlyStreams && song.yearlyStreams > 0) {
      return false;
    }
    if (song.yearlyStreams > song.lastFiveYearsStreams &&
        song.lastFiveYearsStreams > 0) {
      return false;
    }
    if (song.lastFiveYearsStreams > song.allTimeStreams &&
        song.allTimeStreams > 0) {
      return false;
    }

    return true;
  }

  /// Calculate dynamic base price per stream based on total stream count
  /// Higher stream counts get higher base prices to reflect market value
  static double calculateDynamicBasePricePerStream(num totalStreams) {
    int streamCount = totalStreams.toInt();

    if (streamCount <= 1000) {
      // Very low streams: minimum base price
      return 0.0001;
    } else if (streamCount <= 100000) {
      // Low streams (1K-100K): gradual increase
      double factor = (streamCount - 1000) / 99000; // 0-1 range
      return 0.0001 + (factor * 0.0009); // 0.0001 to 0.001
    } else if (streamCount <= 10000000) {
      // Medium streams (100K-10M): moderate increase
      double factor = (streamCount - 100000) / 9900000; // 0-1 range
      return 0.001 + (factor * 0.004); // 0.001 to 0.005
    } else if (streamCount <= 100000000) {
      // High streams (10M-100M): significant increase
      double factor = (streamCount - 10000000) / 90000000; // 0-1 range
      return 0.005 + (factor * 0.005); // 0.005 to 0.010
    } else {
      // Ultra-high streams (100M+): premium pricing
      double factor = math.min(
        (streamCount - 100000000) / 900000000,
        1.0,
      ); // Capped at 1
      return 0.010 + (factor * 0.005); // 0.010 to 0.015
    }
  }

  /// Calculate market multiplier for dynamic pricing adjustments
  /// Incorporates genre, momentum, and volatility factors
  static double _calculateMarketMultiplier(Song song) {
    double multiplier = 1.0;

    // Genre-based multipliers adapted for bell curve distribution
    String genre = song.genre.toLowerCase();
    Map<String, double> genreMultipliers = {
      'pop': 1.2,
      'hip-hop': 1.3,
      'rap': 1.3,
      'rock': 1.1,
      'electronic': 1.15,
      'r&b': 1.1,
      'country': 1.05,
      'jazz': 0.9,
      'classical': 0.8,
      'indie': 0.95,
      'alternative': 1.0,
    };
    multiplier *= genreMultipliers[genre] ?? 1.0;

    // Momentum factor based on recent streaming trends (with bidirectional movement)
    double momentumFactor = _calculateMomentumFactor(song);
    multiplier *= momentumFactor;

    // Time-based volatility factor
    double volatilityFactor = _calculateVolatilityFactor(song);
    multiplier *= volatilityFactor;

    // Market sentiment for bell curve pricing (allow for decline)
    double sentimentFactor = _calculateMarketSentiment(song);
    multiplier *= sentimentFactor;

    // Clamp to reasonable range (0.3x to 3.0x) to prevent extreme outliers
    return multiplier.clamp(0.3, 3.0);
  }

  /// Calculate momentum factor with bidirectional movement support
  static double _calculateMomentumFactor(Song song) {
    // Compare recent streams to longer-term average
    double recentAverage = (song.dailyStreams * 30 + song.monthlyStreams) / 2;
    double longTermAverage = song.yearlyStreams / 12;

    if (longTermAverage <= 0) return 1.0;

    double ratio = recentAverage / longTermAverage;

    // Enhanced momentum with stronger effects for bell curve
    if (ratio > 3.0) {
      // Viral momentum: up to 80% price boost
      return 1.0 + math.min(0.8, (ratio - 1.0) * 0.25);
    } else if (ratio > 1.5) {
      // Strong momentum: moderate boost
      return 1.0 + (ratio - 1.0) * 0.2;
    } else if (ratio < 0.3) {
      // Strong decline: significant price reduction
      return math.max(0.4, 1.0 - (1.0 - ratio) * 0.6);
    } else if (ratio < 0.7) {
      // Moderate decline: price reduction
      return math.max(0.7, 1.0 - (1.0 - ratio) * 0.3);
    } else {
      // Stable or slight changes
      return 1.0 + (ratio - 1.0) * 0.1;
    }
  }

  /// Calculate volatility factor for bell curve pricing
  static double _calculateVolatilityFactor(Song song) {
    DateTime now = DateTime.now();
    double timeVolatility = 1.0;

    // Peak listening hours effect (more pronounced for bell curve)
    if (now.hour >= 18 && now.hour <= 23) {
      timeVolatility = 1.05; // Increased from 1.02
    } else if (now.hour >= 2 && now.hour <= 6) {
      timeVolatility = 0.95; // Decreased from 0.98
    }

    // Weekend effect (stronger for bell curve)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      timeVolatility *= 1.03; // Increased from 1.01
    }

    // Artist popularity effect based on total streams
    double popularityVolatility = 1.0;
    if (song.allTimeStreams > 50000000) {
      // Mega-hit artists get stability premium
      popularityVolatility = 1.08; // Increased from 1.05
    } else if (song.allTimeStreams < 100000) {
      // Emerging artists get more volatility
      popularityVolatility = 0.92; // Decreased from 0.95
    }

    return timeVolatility * popularityVolatility;
  }

  /// Calculate market sentiment factor with bell curve considerations
  static double _calculateMarketSentiment(Song song) {
    // Add random market fluctuations for realistic price movement
    double randomFactor =
        0.95 + (math.Random().nextDouble() * 0.1); // 0.95 to 1.05

    // Genre-specific sentiment cycles
    String genre = song.genre.toLowerCase();
    double genreSentiment = 1.0;

    switch (genre) {
      case 'pop':
      case 'hip-hop':
      case 'rap':
        // These genres have higher volatility
        genreSentiment = 0.9 + (math.Random().nextDouble() * 0.2); // 0.9 to 1.1
        break;
      case 'electronic':
      case 'dance':
        // Electronic music has moderate volatility
        genreSentiment =
            0.95 + (math.Random().nextDouble() * 0.1); // 0.95 to 1.05
        break;
      case 'classical':
      case 'jazz':
        // Classical genres are more stable
        genreSentiment =
            0.98 + (math.Random().nextDouble() * 0.04); // 0.98 to 1.02
        break;
      default:
        genreSentiment =
            0.96 + (math.Random().nextDouble() * 0.08); // 0.96 to 1.04
    }

    return randomFactor * genreSentiment;
  }

  /// Get detailed pricing breakdown for debugging
  static Map<String, dynamic> getPricingBreakdown(Song song) {
    // Calculate dynamic base price per stream
    double dynamicBasePricePerStream = calculateDynamicBasePricePerStream(
      song.allTimeStreams,
    );

    double allTimeContribution =
        song.allTimeStreams * _allTimeWeight * dynamicBasePricePerStream;
    double fiveYearContribution =
        song.lastFiveYearsStreams * _fiveYearWeight * dynamicBasePricePerStream;
    double yearlyContribution =
        song.yearlyStreams * _yearlyWeight * dynamicBasePricePerStream;
    double monthlyContribution =
        song.monthlyStreams * _monthlyWeight * dynamicBasePricePerStream;
    double dailyContribution =
        song.dailyStreams * _dailyWeight * dynamicBasePricePerStream;

    double totalBeforeBounds =
        allTimeContribution +
        fiveYearContribution +
        yearlyContribution +
        monthlyContribution +
        dailyContribution;

    // Use bell curve pricing for breakdown analysis
    double popularityScore = calculatePopularityScore(song.allTimeStreams);
    double finalPrice =
        popularityScoreToPrice(popularityScore) *
        _calculateMarketMultiplier(song);

    return {
      'song_id': song.id,
      'song_name': song.name,
      'stream_data': {
        'all_time': song.allTimeStreams,
        'five_years': song.lastFiveYearsStreams,
        'yearly': song.yearlyStreams,
        'monthly': song.monthlyStreams,
        'daily': song.dailyStreams,
      },
      'contributions': {
        'all_time': double.parse(allTimeContribution.toStringAsFixed(4)),
        'five_years': double.parse(fiveYearContribution.toStringAsFixed(4)),
        'yearly': double.parse(yearlyContribution.toStringAsFixed(4)),
        'monthly': double.parse(monthlyContribution.toStringAsFixed(4)),
        'daily': double.parse(dailyContribution.toStringAsFixed(4)),
      },
      'total_before_bounds': double.parse(totalBeforeBounds.toStringAsFixed(4)),
      'final_price': double.parse(finalPrice.toStringAsFixed(4)),
      'popularity_score': popularityScore,
      'bell_curve_base': popularityScoreToPrice(popularityScore),
      'market_multiplier': _calculateMarketMultiplier(song),
      'base_price_per_stream': double.parse(
        dynamicBasePricePerStream.toStringAsFixed(6),
      ),
      'static_base_price_per_stream':
          song.basePricePerStream, // Keep for comparison
    };
  }
}
