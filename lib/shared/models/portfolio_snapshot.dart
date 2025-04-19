import 'package:flutter/foundation.dart';

@immutable
class PortfolioSnapshot {
  final DateTime timestamp;
  final double value;

  const PortfolioSnapshot({required this.timestamp, required this.value});

  // Factory constructor for JSON deserialization
  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(), // Handle potential int/double
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.toIso8601String(), 'value': value};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioSnapshot &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          value == other.value;

  @override
  int get hashCode => timestamp.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'PortfolioSnapshot{timestamp: $timestamp, value: $value}';
  }
}
