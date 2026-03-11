/// Format a number as Philippine Peso currency
String formatCurrency(double amount) {
  return '₱${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      )}';
}

/// Get the Monday (week start) of a given date
String getWeekStart(DateTime date) {
  final weekday = date.weekday; // 1 = Monday, 7 = Sunday
  final monday = date.subtract(Duration(days: weekday - 1));
  return monday.toString().split(' ')[0];
}

/// Get week end (Sunday) from a week start string
String getWeekEnd(String weekStart) {
  final d = DateTime.parse(weekStart);
  return d.add(const Duration(days: 6)).toString().split(' ')[0];
}

/// Generate a unique ID
String generateId(String prefix) {
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
}
