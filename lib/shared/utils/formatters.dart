import 'package:intl/intl.dart';

/// Data formatting utilities
class Formatters {
  // Currency formatter
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  // Compact currency formatter (e.g., $1.2K)
  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 1,
  );
  
  // Percentage formatter
  static final NumberFormat _percentFormat = NumberFormat.percentPattern();
  
  // Decimal formatter
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.00');
  
  // Date formatter
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  
  // Time formatter
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  
  // Date and time formatter
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');
  
  // Relative time formatter (e.g., "2 hours ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  // Format currency
  static String currency(double value) {
    return _currencyFormat.format(value);
  }
  
  // Format compact currency
  static String compactCurrency(double value) {
    return _compactCurrencyFormat.format(value);
  }
  
  // Format percentage
  static String percentage(double value) {
    return _percentFormat.format(value / 100);
  }
  
  // Format decimal
  static String decimal(double value) {
    return _decimalFormat.format(value);
  }
  
  // Format date
  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
  
  // Format time
  static String time(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
  
  // Format date and time
  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  // Format number with commas
  static String numberWithCommas(int number) {
    return NumberFormat('#,###').format(number);
  }
  
  // Format compact number (e.g., 1.2K)
  static String compactNumber(int number) {
    return NumberFormat.compact().format(number);
  }
  
  // Format price change with sign
  static String priceChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${_decimalFormat.format(change)}';
  }
  
  // Format price change percentage with sign
  static String priceChangePercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${_decimalFormat.format(percentage)}%';
  }
  
  // Format stream count
  static String streamCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
