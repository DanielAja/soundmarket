/// String extension methods
extension StringExtensions on String {
  // Capitalize first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
        )
        .join(' ');
  }

  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // Convert to title case
  String get toTitleCase {
    if (isEmpty) return this;

    final words = split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';

      // Don't capitalize articles, conjunctions, and prepositions
      final lowercaseWords = [
        'a',
        'an',
        'the',
        'and',
        'but',
        'or',
        'for',
        'nor',
        'on',
        'at',
        'to',
        'by',
        'in',
        'of',
      ];
      if (lowercaseWords.contains(word.toLowerCase()) &&
          words.indexOf(word) != 0) {
        return word.toLowerCase();
      }

      return word.capitalize;
    });

    return capitalizedWords.join(' ');
  }

  // Check if string is a valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  // Check if string is a valid URL
  bool get isValidUrl {
    return RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    ).hasMatch(this);
  }

  // Check if string is numeric
  bool get isNumeric {
    return RegExp(r'^-?[0-9]+(\.[0-9]+)?$').hasMatch(this);
  }

  // Check if string is alphanumeric
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  // Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  // Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  // Convert to slug (URL-friendly string)
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  // Convert to camelCase
  String get toCamelCase {
    if (isEmpty) return this;

    final words = split(RegExp(r'[\s_-]'));
    final firstWord = words.first.toLowerCase();
    final remainingWords = words.skip(1).map((word) => word.capitalize);

    return firstWord + remainingWords.join('');
  }

  // Convert to snake_case
  String get toSnakeCase {
    if (isEmpty) return this;

    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp(r'[\s-]'), '_').toLowerCase();
  }

  // Convert to kebab-case
  String get toKebabCase {
    if (isEmpty) return this;

    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '-${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp(r'[\s_]'), '-').toLowerCase();
  }

  // Extract numbers from string
  String get extractNumbers {
    return replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Extract first n characters
  String first(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }

  // Extract last n characters
  String last(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }

  // Check if string contains only letters
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  // Check if string is a valid phone number
  bool get isValidPhone {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(this);
  }

  // Mask a credit card number
  String get maskCreditCard {
    if (length < 4) return this;
    return '${substring(0, 4)} **** **** ${substring(length - 4)}';
  }

  // Mask an email address
  String get maskEmail {
    if (!isValidEmail) return this;

    final parts = split('@');
    if (parts.length != 2) return this;

    final username = parts[0];
    final domain = parts[1];

    final maskedUsername =
        username.length <= 2
            ? username
            : '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';

    return '$maskedUsername@$domain';
  }
}
