/// Environment-specific configurations (dev, staging, prod)
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;
  
  // Initialize the environment
  static void initialize(Environment env) {
    _environment = env;
  }
  
  // Get the current environment
  static Environment get environment => _environment;
  
  // Check if we're in development mode
  static bool get isDevelopment => _environment == Environment.development;
  
  // Check if we're in staging mode
  static bool get isStaging => _environment == Environment.staging;
  
  // Check if we're in production mode
  static bool get isProduction => _environment == Environment.production;
  
  // Get the API base URL based on environment
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://dev-api.soundmarket.example.com';
      case Environment.staging:
        return 'https://staging-api.soundmarket.example.com';
      case Environment.production:
        return 'https://api.soundmarket.example.com';
    }
  }
  
  // Get environment-specific settings
  static Map<String, dynamic> get settings {
    switch (_environment) {
      case Environment.development:
        return {
          'logLevel': 'debug',
          'enableMockData': true,
          'refreshInterval': 10, // seconds
        };
      case Environment.staging:
        return {
          'logLevel': 'info',
          'enableMockData': false,
          'refreshInterval': 30, // seconds
        };
      case Environment.production:
        return {
          'logLevel': 'error',
          'enableMockData': false,
          'refreshInterval': 60, // seconds
        };
    }
  }
}
