import 'package:intl/intl.dart';
import 'dart:math' as math;

/// Integer extension methods
extension IntExtensions on int {
  // Convert to currency format
  String get toCurrency {
    return NumberFormat.currency(symbol: '\$').format(this);
  }

  // Convert to compact currency format (e.g., $1.2K)
  String get toCompactCurrency {
    return NumberFormat.compactCurrency(symbol: '\$').format(this);
  }

  // Convert to percentage
  String get toPercentage {
    return NumberFormat.percentPattern().format(this / 100);
  }

  // Format with commas
  String get withCommas {
    return NumberFormat('#,###').format(this);
  }

  // Format as compact number (e.g., 1.2K)
  String get compact {
    return NumberFormat.compact().format(this);
  }

  // Convert to ordinal (1st, 2nd, 3rd, etc.)
  String get toOrdinal {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }

    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }

  // Convert to duration string (e.g., 1h 30m)
  String get toDuration {
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = this % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours}h');
    }

    if (minutes > 0) {
      parts.add('${minutes}m');
    }

    if (seconds > 0 && hours == 0) {
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }

  // Convert to duration string with full words (e.g., 1 hour 30 minutes)
  String get toDurationFull {
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = this % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }

    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }

    if (seconds > 0 && hours == 0) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    return parts.join(' ');
  }

  // Convert to file size (e.g., 1.5 MB)
  String get toFileSize {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = this.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size.truncateToDouble() == size ? 0 : 1)} ${units[unitIndex]}';
  }

  // Convert to roman numeral
  String get toRoman {
    if (this <= 0 || this > 3999) {
      return this.toString();
    }

    final List<String> romanNumerals = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I',
    ];
    final List<int> values = [
      1000,
      900,
      500,
      400,
      100,
      90,
      50,
      40,
      10,
      9,
      5,
      4,
      1,
    ];

    String result = '';
    int remaining = this;

    for (int i = 0; i < romanNumerals.length; i++) {
      while (remaining >= values[i]) {
        result += romanNumerals[i];
        remaining -= values[i];
      }
    }

    return result;
  }

  // Convert to words (e.g., 123 -> one hundred twenty-three)
  String get toWords {
    if (this == 0) return 'zero';

    final units = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    final tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    String _convert(int n) {
      if (n < 20) {
        return units[n];
      } else if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 > 0 ? '-${units[n % 10]}' : ''}';
      } else if (n < 1000) {
        return '${units[n ~/ 100]} hundred${n % 100 > 0 ? ' ${_convert(n % 100)}' : ''}';
      } else if (n < 1000000) {
        return '${_convert(n ~/ 1000)} thousand${n % 1000 > 0 ? ' ${_convert(n % 1000)}' : ''}';
      } else if (n < 1000000000) {
        return '${_convert(n ~/ 1000000)} million${n % 1000000 > 0 ? ' ${_convert(n % 1000000)}' : ''}';
      } else {
        return '${_convert(n ~/ 1000000000)} billion${n % 1000000000 > 0 ? ' ${_convert(n % 1000000000)}' : ''}';
      }
    }

    return _convert(this.abs()) + (this < 0 ? ' negative' : '');
  }

  // Convert to binary
  String get toBinary => this.toRadixString(2);

  // Convert to hexadecimal
  String get toHex => this.toRadixString(16).toUpperCase();

  // Convert to octal
  String get toOctal => this.toRadixString(8);

  // Convert to DateTime
  DateTime get toDateTime => DateTime.fromMillisecondsSinceEpoch(this);

  // Convert milliseconds to Duration
  Duration get toDurationObject => Duration(milliseconds: this);
}

/// Double extension methods
extension DoubleExtensions on double {
  // Convert to currency format
  String get toCurrency {
    return NumberFormat.currency(symbol: '\$').format(this);
  }

  // Convert to compact currency format (e.g., $1.2K)
  String get toCompactCurrency {
    return NumberFormat.compactCurrency(symbol: '\$').format(this);
  }

  // Convert to percentage
  String get toPercentage {
    return NumberFormat.percentPattern().format(this / 100);
  }

  // Format with commas and decimal places
  String get withCommas {
    return NumberFormat('#,##0.00').format(this);
  }

  // Format as compact number (e.g., 1.2K)
  String get compact {
    return NumberFormat.compact().format(this);
  }

  // Round to specified decimal places
  double roundTo(int places) {
    final mod = math.pow(10.0, places);
    return (this * mod).round() / mod;
  }

  // Format with specified decimal places
  String toStringWithDecimalPlaces(int decimalPlaces) {
    return toStringAsFixed(decimalPlaces).replaceAll(RegExp(r'\.0+$'), '');
  }

  // Check if double is an integer
  bool get isInteger => this == this.roundToDouble();

  // Convert to price change format with sign
  String get toPriceChange {
    final sign = this >= 0 ? '+' : '';
    return '$sign${this.withCommas}';
  }

  // Convert to price change percentage format with sign
  String get toPriceChangePercentage {
    final sign = this >= 0 ? '+' : '';
    return '$sign${this.withCommas}%';
  }

  // Power function
  double pow(double exponent) {
    return math.pow(this, exponent) as double;
  }
}
