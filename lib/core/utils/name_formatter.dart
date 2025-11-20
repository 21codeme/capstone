/// Utility class for formatting names, particularly for middle name display
class NameFormatter {
  /// Capitalizes the first letter of a name for uniformity
  /// 
  /// Example: "mark" -> "Mark"
  /// Example: "JOHN" -> "John"
  /// Example: "mary jane" -> "Mary jane"
  static String capitalizeName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '';
    }
    
    final trimmed = name.trim();
    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }
    
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  /// Formats a middle name to show only the first letter followed by a dot
  /// 
  /// Example: "Charles Simon Delmundo" -> "C. S. D."
  /// Example: "Maria" -> "M."
  /// Example: "" -> ""
  static String formatMiddleName(String? middleName) {
    if (middleName == null || middleName.trim().isEmpty) {
      return '';
    }
    
    final trimmed = middleName.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}.')
        .join(' ');
  }
  
  /// Builds a full name with formatted middle name for display purposes
  /// Automatically capitalizes first and last names for uniformity
  /// 
  /// Example: firstName="mark", middleName="Simon Delmundo", lastName="smith"
  /// Result: "Mark S. D. Smith"
  static String buildDisplayName({
    required String firstName,
    String? middleName,
    required String lastName,
  }) {
    final parts = <String>[];
    
    final capitalizedFirstName = capitalizeName(firstName);
    if (capitalizedFirstName.isNotEmpty) {
      parts.add(capitalizedFirstName);
    }
    
    final formattedMiddleName = formatMiddleName(middleName);
    if (formattedMiddleName.isNotEmpty) {
      parts.add(formattedMiddleName);
    }
    
    final capitalizedLastName = capitalizeName(lastName);
    if (capitalizedLastName.isNotEmpty) {
      parts.add(capitalizedLastName);
    }
    
    return parts.join(' ');
  }
  
  /// Builds a full name with complete middle name for storage purposes
  /// Automatically capitalizes first and last names for uniformity
  /// 
  /// Example: firstName="mark", middleName="Simon Delmundo", lastName="smith"
  /// Result: "Mark Simon Delmundo Smith"
  static String buildFullName({
    required String firstName,
    String? middleName,
    required String lastName,
  }) {
    final parts = <String>[];
    
    final capitalizedFirstName = capitalizeName(firstName);
    if (capitalizedFirstName.isNotEmpty) {
      parts.add(capitalizedFirstName);
    }
    
    if (middleName != null && middleName.trim().isNotEmpty) {
      parts.add(middleName.trim());
    }
    
    final capitalizedLastName = capitalizeName(lastName);
    if (capitalizedLastName.isNotEmpty) {
      parts.add(capitalizedLastName);
    }
    
    return parts.join(' ');
  }
  
  /// Formats an existing full name to display middle names as initials
  /// 
  /// Example: "Charles Simon Delmundo Miembro" -> "Charles S. D. Miembro"
  static String formatExistingFullName(String fullName) {
    if (fullName.trim().isEmpty) return '';
    
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) {
      // No middle names to format
      return fullName;
    }
    
    final result = <String>[];
    
    // Add first name
    result.add(words.first);
    
    // Format middle names (all except first and last)
    for (int i = 1; i < words.length - 1; i++) {
      if (words[i].isNotEmpty) {
        result.add('${words[i][0].toUpperCase()}.');
      }
    }
    
    // Add last name
    result.add(words.last);
    
    return result.join(' ');
  }
}