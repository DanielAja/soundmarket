class StreamHistory {
  final String songId;
  final DateTime timestamp;
  final int streamCount;
  final String period; // 'daily', 'monthly', 'yearly', 'all_time', 'five_years'

  const StreamHistory({
    required this.songId,
    required this.timestamp,
    required this.streamCount,
    required this.period,
  });

  // Create a copy with updated fields
  StreamHistory copyWith({
    String? songId,
    DateTime? timestamp,
    int? streamCount,
    String? period,
  }) {
    return StreamHistory(
      songId: songId ?? this.songId,
      timestamp: timestamp ?? this.timestamp,
      streamCount: streamCount ?? this.streamCount,
      period: period ?? this.period,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamHistory &&
        other.songId == songId &&
        other.timestamp == timestamp &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(songId, timestamp, period);

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'streamCount': streamCount,
      'period': period,
    };
  }

  // Create from JSON
  factory StreamHistory.fromJson(Map<String, dynamic> json) {
    return StreamHistory(
      songId: json['songId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      streamCount: json['streamCount'],
      period: json['period'],
    );
  }

  // Helper methods for calculating stream data by time periods
  static List<StreamHistory> filterByPeriod(
    List<StreamHistory> history,
    Duration period,
  ) {
    final cutoff = DateTime.now().subtract(period);
    return history.where((entry) => entry.timestamp.isAfter(cutoff)).toList();
  }

  static int getTotalStreamsForPeriod(
    List<StreamHistory> history,
    Duration period,
  ) {
    final filtered = filterByPeriod(history, period);
    return filtered.fold(0, (sum, entry) => sum + entry.streamCount);
  }

  // Pre-defined period filters
  static List<StreamHistory> getLastDayStreams(List<StreamHistory> history) =>
      filterByPeriod(history, const Duration(days: 1));

  static List<StreamHistory> getLastMonthStreams(List<StreamHistory> history) =>
      filterByPeriod(history, const Duration(days: 30));

  static List<StreamHistory> getLastYearStreams(List<StreamHistory> history) =>
      filterByPeriod(history, const Duration(days: 365));

  static List<StreamHistory> getLastFiveYearsStreams(
    List<StreamHistory> history,
  ) => filterByPeriod(history, const Duration(days: 365 * 5));

  @override
  String toString() {
    return 'StreamHistory(songId: $songId, timestamp: $timestamp, streamCount: $streamCount, period: $period)';
  }
}
