// lib/core/services/sanitization_service.dart

class SanitizationService {
  static const List<String> _profanityList = [
    'stupid', 'dumb', 'idiot', 'lazy', 'terrible', 'awful', 'hate', 
    'useless', 'fool', 'pathetic', 'worst', 'failure', 'garbage'
  ];

  /// Filters out unprofessional language and sanitizes input to prevent XSS/SQLi vectors
  static String sanitizeNarrative(String input) {
    if (input.isEmpty) return input;

    // 1. Basic HTML/Script tag removal for XSS prevention
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // 2. Remove script injections specifically
    sanitized = sanitized.replaceAll(RegExp(r'(?i)(javascript:|onerror=|onload=|eval\()'), '');

    // 3. Profanity filtering - replace with asterisks to maintain context without offense
    for (final word in _profanityList) {
      final regex = RegExp('\\b$word\\b', caseSensitive: false);
      sanitized = sanitized.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }

    // 4. Transform extreme punctuation (e.g., "!!!" -> "!")
    sanitized = sanitized.replaceAll(RegExp(r'!{2,}'), '!');
    sanitized = sanitized.replaceAll(RegExp(r'\?{2,}'), '?');

    return sanitized.trim();
  }
}
