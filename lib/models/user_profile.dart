class UserProfile {
  final String userId;
  double cashBalance;
  String? displayName;
  String? profileImageUrl;
  
  UserProfile({
    required this.userId,
    this.cashBalance = 100.0, // Default starting balance
    this.displayName,
    this.profileImageUrl,
  });
  
  // Create a copy of this UserProfile with given fields replaced with new values
  UserProfile copyWith({
    String? userId,
    double? cashBalance,
    String? displayName,
    String? profileImageUrl,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      cashBalance: cashBalance ?? this.cashBalance,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
  
  // Convert UserProfile to a Map for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'cashBalance': cashBalance,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
    };
  }
  
  // Create a UserProfile from a Map (e.g., from storage)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      cashBalance: json['cashBalance'] ?? 100.0,
      displayName: json['displayName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
