import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_analytics/utils/formatters.dart';

void main() {
  test('fixture dates are displayed using local timezone', () {
    const iso = '2025-08-25T00:45:00Z';
    final dt = DateTime.parse(iso).toLocal();
    const months = [
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

    expect(formatDateShort(iso), '${dt.day} ${months[dt.month - 1]}');
  });
}
