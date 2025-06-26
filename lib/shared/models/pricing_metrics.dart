class PricingMetrics {
  final String songId;
  final DateTime timestamp;
  final double calculatedPrice;
  final double previousPrice;
  final double priceChange;
  final double priceChangePercent;
  final Map<String, int> streamBreakdown;
  final Map<String, double> weightedContributions;
  final double volatilityScore;
  final bool wasPriceClamped;

  const PricingMetrics({
    required this.songId,
    required this.timestamp,
    required this.calculatedPrice,
    required this.previousPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.streamBreakdown,
    required this.weightedContributions,
    required this.volatilityScore,
    required this.wasPriceClamped,
  });

  // Create a PricingMetrics from pricing breakdown
  factory PricingMetrics.fromBreakdown(
    Map<String, dynamic> breakdown,
    double previousPrice,
    double volatilityScore,
  ) {
    final calculatedPrice = breakdown['final_price'] as double;
    final priceChange = calculatedPrice - previousPrice;
    final priceChangePercent =
        previousPrice > 0 ? (priceChange / previousPrice) * 100 : 0.0;

    return PricingMetrics(
      songId: breakdown['song_id'],
      timestamp: DateTime.now(),
      calculatedPrice: calculatedPrice,
      previousPrice: previousPrice,
      priceChange: priceChange,
      priceChangePercent: priceChangePercent,
      streamBreakdown: Map<String, int>.from(breakdown['stream_data']),
      weightedContributions: Map<String, double>.from(
        breakdown['contributions'],
      ),
      volatilityScore: volatilityScore,
      wasPriceClamped: breakdown['was_clamped'] as bool,
    );
  }

  // Create a copy with updated fields
  PricingMetrics copyWith({
    String? songId,
    DateTime? timestamp,
    double? calculatedPrice,
    double? previousPrice,
    double? priceChange,
    double? priceChangePercent,
    Map<String, int>? streamBreakdown,
    Map<String, double>? weightedContributions,
    double? volatilityScore,
    bool? wasPriceClamped,
  }) {
    return PricingMetrics(
      songId: songId ?? this.songId,
      timestamp: timestamp ?? this.timestamp,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      previousPrice: previousPrice ?? this.previousPrice,
      priceChange: priceChange ?? this.priceChange,
      priceChangePercent: priceChangePercent ?? this.priceChangePercent,
      streamBreakdown: streamBreakdown ?? this.streamBreakdown,
      weightedContributions:
          weightedContributions ?? this.weightedContributions,
      volatilityScore: volatilityScore ?? this.volatilityScore,
      wasPriceClamped: wasPriceClamped ?? this.wasPriceClamped,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PricingMetrics &&
        other.songId == songId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(songId, timestamp);

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'calculatedPrice': calculatedPrice,
      'previousPrice': previousPrice,
      'priceChange': priceChange,
      'priceChangePercent': priceChangePercent,
      'streamBreakdown': streamBreakdown,
      'weightedContributions': weightedContributions,
      'volatilityScore': volatilityScore,
      'wasPriceClamped': wasPriceClamped,
    };
  }

  // Create from JSON
  factory PricingMetrics.fromJson(Map<String, dynamic> json) {
    return PricingMetrics(
      songId: json['songId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      calculatedPrice: json['calculatedPrice'],
      previousPrice: json['previousPrice'],
      priceChange: json['priceChange'],
      priceChangePercent: json['priceChangePercent'],
      streamBreakdown: Map<String, int>.from(json['streamBreakdown']),
      weightedContributions: Map<String, double>.from(
        json['weightedContributions'],
      ),
      volatilityScore: json['volatilityScore'],
      wasPriceClamped: json['wasPriceClamped'],
    );
  }

  // Helper getters for analysis
  bool get isPriceIncreasing => priceChange > 0;
  bool get isPriceDecreasing => priceChange < 0;
  bool get isPriceStable => priceChange == 0;

  String get trend {
    if (isPriceIncreasing) return 'increasing';
    if (isPriceDecreasing) return 'decreasing';
    return 'stable';
  }

  // Get the most impactful stream period
  String get mostImpactfulPeriod {
    String maxPeriod = 'all_time';
    double maxContribution = 0;

    weightedContributions.forEach((period, contribution) {
      if (contribution > maxContribution) {
        maxContribution = contribution;
        maxPeriod = period;
      }
    });

    return maxPeriod;
  }

  // Calculate total weighted streams
  double get totalWeightedStreams {
    return weightedContributions.values.fold(
      0.0,
      (sum, contribution) => sum + contribution,
    );
  }

  @override
  String toString() {
    return 'PricingMetrics(songId: $songId, price: \$${calculatedPrice.toStringAsFixed(4)}, '
        'change: ${priceChangePercent.toStringAsFixed(2)}%, trend: $trend)';
  }
}

// Class for storing pricing algorithm configuration
class PricingAlgorithmConfig {
  final double allTimeWeight;
  final double fiveYearWeight;
  final double yearlyWeight;
  final double monthlyWeight;
  final double dailyWeight;
  final double basePricePerStream;
  final double minPrice;
  final double maxPrice;

  const PricingAlgorithmConfig({
    this.allTimeWeight = 0.50,
    this.fiveYearWeight = 0.30,
    this.yearlyWeight = 0.10,
    this.monthlyWeight = 0.05,
    this.dailyWeight = 0.05,
    this.basePricePerStream = 0.001,
    this.minPrice = 0.01,
    this.maxPrice = 1000.0,
  });

  // Validate that weights sum to 1.0
  bool get isValid {
    double totalWeight =
        allTimeWeight +
        fiveYearWeight +
        yearlyWeight +
        monthlyWeight +
        dailyWeight;
    return (totalWeight - 1.0).abs() <
        0.001; // Allow for floating point precision
  }

  Map<String, double> get weights => {
    'all_time': allTimeWeight,
    'five_years': fiveYearWeight,
    'yearly': yearlyWeight,
    'monthly': monthlyWeight,
    'daily': dailyWeight,
  };

  @override
  String toString() {
    return 'PricingAlgorithmConfig(weights: $weights, basePricePerStream: $basePricePerStream)';
  }
}
