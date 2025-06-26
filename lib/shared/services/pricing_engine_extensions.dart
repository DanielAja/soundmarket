import 'dart:math' as Math;
import '../models/song.dart';
import 'pricing_engine.dart';

/// Extensions to PricingEngine for market dynamics
extension PricingEngineMarketDynamics on PricingEngine {
  // Market dynamics factors
  static const Map<String, double> _genreMultipliers = {
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

  /// Apply market dynamics factors to base price
  static double applyMarketDynamics(double basePrice, Song song) {
    double adjustedPrice = basePrice;

    // Apply genre multiplier
    String genre = song.genre.toLowerCase();
    double genreMultiplier = _genreMultipliers[genre] ?? 1.0;
    adjustedPrice *= genreMultiplier;

    // Apply momentum factor based on recent streaming trends
    double momentumFactor = calculateMomentumFactor(song);
    adjustedPrice *= momentumFactor;

    // Apply time-based volatility
    double volatilityFactor = calculateVolatilityFactor(song);
    adjustedPrice *= volatilityFactor;

    return adjustedPrice;
  }

  /// Calculate momentum factor based on recent streaming trends
  static double calculateMomentumFactor(Song song) {
    // Compare recent streams to long-term average
    double recentAverage = (song.dailyStreams * 30 + song.monthlyStreams) / 2;
    double longTermAverage = song.yearlyStreams / 12;

    if (longTermAverage <= 0) return 1.0;

    double ratio = recentAverage / longTermAverage;

    // Apply momentum boost for trending songs, penalty for declining
    if (ratio > 2.0) {
      // Viral momentum: up to 50% price boost
      return 1.0 + Math.min(0.5, (ratio - 1.0) * 0.2);
    } else if (ratio < 0.5) {
      // Declining momentum: up to 20% price reduction
      return Math.max(0.8, 1.0 - (1.0 - ratio) * 0.4);
    } else {
      // Stable momentum: slight adjustment
      return 1.0 + (ratio - 1.0) * 0.1;
    }
  }

  /// Calculate volatility factor based on price history and market conditions
  static double calculateVolatilityFactor(Song song) {
    // Time-based volatility (market hours effect)
    DateTime now = DateTime.now();
    double timeVolatility = 1.0;

    // Peak listening hours (evening) get slight price boost
    if (now.hour >= 18 && now.hour <= 23) {
      timeVolatility = 1.02;
    }
    // Late night/early morning gets slight reduction
    else if (now.hour >= 2 && now.hour <= 6) {
      timeVolatility = 0.98;
    }

    // Weekend effect
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      timeVolatility *= 1.01;
    }

    // Artist popularity effect (based on multiple songs by same artist)
    // This would require access to other songs by the same artist
    // For now, use a simple popularity indicator
    double popularityVolatility = 1.0;
    if (song.allTimeStreams > 50000000) {
      // Mega-hit artists get stability premium
      popularityVolatility = 1.05;
    } else if (song.allTimeStreams < 100000) {
      // Emerging artists get volatility discount
      popularityVolatility = 0.95;
    }

    return timeVolatility * popularityVolatility;
  }
}
