import 'product.dart';

abstract final class ProductValidation {
  static String clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? name(String? raw) {
    final value = clean(raw ?? '');
    if (value.isEmpty) return 'Enter a product name';
    if (value.length < 3) return 'Use at least 3 characters';
    if (value.length > 80) return 'Keep the name under 80 characters';
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(value)) {
      return 'Enter a meaningful product name';
    }
    final compact = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (compact.length >= 4 && compact.split('').toSet().length == 1) {
      return 'Enter a meaningful product name';
    }
    return null;
  }

  static String? brand(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final value = clean(raw);
    if (value.isEmpty) return 'Remove spaces or enter a brand';
    if (value.length > 60) return 'Keep the brand under 60 characters';
    return null;
  }

  static String? notes(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (clean(raw).isEmpty) return 'Remove spaces or enter a note';
    if (clean(raw).length > 500) return 'Keep notes under 500 characters';
    return null;
  }

  static String? frequency(int? value, {required bool inRoutine}) {
    if (!inRoutine) return null;
    if (value == null) return 'Choose a frequency';
    if (value <= 0) return 'Frequency must be at least once a week';
    if (value > 14) return 'Frequency cannot exceed 14 times a week';
    return null;
  }

  static String? dates(DateTime? start, DateTime? end) {
    if (start != null &&
        start.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Start date cannot be in the future';
    }
    if (start != null && end != null && end.isBefore(start)) {
      return 'End date cannot be before the start date';
    }
    return null;
  }

  static bool duplicate(
    Product candidate,
    Iterable<Product> products, {
    String? excludingId,
  }) {
    final name = clean(candidate.name).toLowerCase();
    final brandName = clean(candidate.brand ?? '').toLowerCase();
    return products.any(
      (item) =>
          item.id != excludingId &&
          item.status != ProductStatus.archived &&
          clean(item.name).toLowerCase() == name &&
          clean(item.brand ?? '').toLowerCase() == brandName,
    );
  }
}
