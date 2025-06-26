import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/shared/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    tearDown(() {
      analyticsService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize correctly', () async {
      await analyticsService.initialize();
      // No exceptions should be thrown
    });

    test('should enable and disable analytics', () {
      analyticsService.setEnabled(true);
      // Should not throw any exception
      
      analyticsService.setEnabled(false);
      // Should not throw any exception
    });

    test('should track screen view when enabled', () {
      analyticsService.setEnabled(true);
      
      // Should not throw exception
      analyticsService.trackScreenView('home_screen');
      analyticsService.trackScreenView('profile_screen', parameters: {'user_id': '123'});
    });

    test('should not track events when disabled', () {
      analyticsService.setEnabled(false);
      
      // Should not throw exception even when disabled
      analyticsService.trackScreenView('home_screen');
      analyticsService.trackAction('button_click');
    });

    test('should track user actions', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackAction('button_click');
      analyticsService.trackAction('search', parameters: {'query': 'test'});
      analyticsService.trackAction('purchase', parameters: {'item_id': '123', 'price': 9.99});
    });

    test('should track errors', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackError('network_error', 'Failed to connect to server');
      analyticsService.trackError(
        'validation_error',
        'Invalid input provided',
        parameters: {'field': 'email'},
      );
    });

    test('should track song views', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSongView('song-123', 'Test Song', 'Test Artist');
      analyticsService.trackSongView(
        'song-456',
        'Another Song',
        'Another Artist',
        parameters: {'genre': 'pop'},
      );
    });

    test('should track song purchases', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSongPurchase('song-123', 'Test Song', 'Test Artist', 5, 12.50);
      analyticsService.trackSongPurchase(
        'song-456',
        'Another Song',
        'Another Artist',
        3,
        8.75,
        parameters: {'payment_method': 'credit_card'},
      );
    });

    test('should track song sales', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSongSale('song-123', 'Test Song', 'Test Artist', 2, 15.00);
      analyticsService.trackSongSale(
        'song-456',
        'Another Song',
        'Another Artist',
        1,
        20.00,
        parameters: {'reason': 'portfolio_rebalance'},
      );
    });

    test('should track searches', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSearch('test query', 10);
      analyticsService.trackSearch(
        'artist name',
        5,
        parameters: {'filter': 'artist'},
      );
    });

    test('should handle empty search queries', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSearch('', 0);
      analyticsService.trackSearch('   ', 0);
    });

    test('should handle negative quantities and prices', () {
      analyticsService.setEnabled(true);
      
      // Should not throw exceptions with invalid data
      analyticsService.trackSongPurchase('song-123', 'Test Song', 'Test Artist', -1, -5.0);
      analyticsService.trackSongSale('song-456', 'Test Song', 'Test Artist', 0, 0.0);
    });

    test('should handle null and empty parameters', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackScreenView('test_screen', parameters: {});
      analyticsService.trackAction('test_action', parameters: null);
      analyticsService.trackError('test_error', 'Test message', parameters: {});
    });

    test('should handle special characters in strings', () {
      analyticsService.setEnabled(true);
      
      analyticsService.trackSongView(
        'song-123',
        'Song with "quotes" & symbols',
        'Artist with émojis 🎵',
      );
      
      analyticsService.trackSearch('query with special chars: @#\$%^&*()', 1);
    });

    test('should dispose without errors', () {
      analyticsService.dispose();
      // Should not throw any exception
    });

    test('should handle multiple initialization calls', () async {
      await analyticsService.initialize();
      await analyticsService.initialize();
      // Should not throw any exception
    });

    test('should track events after reinitialization', () async {
      analyticsService.setEnabled(true);
      await analyticsService.initialize();
      
      analyticsService.trackAction('after_init');
      // Should not throw any exception
    });
  });
}