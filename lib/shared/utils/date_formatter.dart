class DateFormatter {
  const DateFormatter._();

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String compact(DateTime date) {
    final DateTime now = DateTime.now();
    if (date.year == now.year) {
      return '${_months[date.month - 1]} ${date.day}';
    }
    return full(date);
  }

  static String full(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
