class TypeParser {
  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 30;
    if (value is bool) return value ? 1 : 0;
    return 30;
  }

  static double toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 1.0;
    return 1.0;
  } 

   static bool toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return false; // Fallback
  }

  static String StringTo(dynamic value) {
    if (value is String) return value;
    return value.toString();
  }
}