/// Application-wide configuration settings
class AppConfig {
  // App version information
  static const String appName = 'Sound Market';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCaching = true;

  // Default settings
  static const double defaultStartingBalance = 100.0;

  // API configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Cache configuration
  static const int cacheDurationMinutes = 60;

  // UI configuration
  static const int animationDurationMs = 300;

  // Pagination
  static const int defaultPageSize = 20;
}
