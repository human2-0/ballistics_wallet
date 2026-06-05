import 'package:ballistics_wallet_flutter/ui/pressing/wallet/date_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateCompare extension', () {
    test(
      'treats same calendar day as inclusive when checking before or same',
      () {
        final end = DateTime(2024, 7, 31);
        final occurrence = DateTime(2024, 7, 31, 23, 59, 59);

        expect(occurrence.isBeforeOrSame(end), isTrue);
      },
    );

    test(
      'treats same calendar day as inclusive when checking after or same',
      () {
        final start = DateTime(2024, 7);
        final occurrence = DateTime(2024, 7, 1, 8, 30);

        expect(occurrence.isAfterOrSame(start), isTrue);
      },
    );

    test('excludes values outside the calendar day window', () {
      final end = DateTime(2024, 7, 31);
      final occurrence = DateTime(2024, 8);

      expect(occurrence.isBeforeOrSame(end), isFalse);
    });
  });
}
