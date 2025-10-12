extension StringExtensions on String {
  bool get isEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  bool get isPhoneNumber {
    final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
    return phoneRegex.hasMatch(this) && length >= 10;
  }

  bool get isUrl {
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(this);
  }

  bool get isStrongPassword {
    if (length < 8) return false;

    final hasUpperCase = contains(RegExp(r'[A-Z]'));
    final hasLowerCase = contains(RegExp(r'[a-z]'));
    final hasDigit = contains(RegExp(r'[0-9]'));
    final hasSpecialChar = contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUpperCase && hasLowerCase && hasDigit && hasSpecialChar;
  }

  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // capitalize first name and middle as well as last name (on spaces)
  String capitalizeFirstAndLast() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  String removeAllWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  String? get nullIfEmpty => isEmpty ? null : this;

  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  String get initials {
    if (isEmpty) return '';
    final words = split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  String maskEmail() {
    if (!isEmail) return this;
    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${username[0]}***@$domain';
    }

    final visibleChars = (username.length * 0.3).ceil();
    final maskedPart = '*' * (username.length - visibleChars);
    return '${username.substring(0, visibleChars)}$maskedPart@$domain';
  }

  String maskPhoneNumber() {
    if (length < 10) return this;
    final visibleDigits = substring(length - 4);
    final maskedPart = '*' * (length - 4);
    return '$maskedPart$visibleDigits';
  }

  double toDouble() {
    return double.parse(this);
  }

  String fuzzySubstring(int maxLength) {
    if (isEmpty || maxLength <= 0) return '';
    if (length <= maxLength) return this;
    final lastSpace = substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace > 0 && lastSpace > maxLength * 0.6) {
      return '${substring(0, lastSpace)}.....';
    }
    return '${substring(0, maxLength)}.....';
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String orEmpty() => this ?? '';

  String or(String defaultValue) => this ?? defaultValue;
}
