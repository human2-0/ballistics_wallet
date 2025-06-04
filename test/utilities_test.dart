import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';

void main() {
  group('toTitleCase', () {
    test('returns empty string for empty input', () {
      expect(toTitleCase(''), '');
    });

    test('lowercases and joins with underscore', () {
      expect(toTitleCase('Hello World'), 'hello_world');
    });

    test('handles multiple spaces', () {
      expect(toTitleCase('  HELLO   WORLD  '), '__hello___world__');
    });
  });

  group('csvToList', () {
    test('parses data with \n line endings', () {
      const data = '1,2\n3,4';
      expect(csvToList(data), [[1, 2], [3, 4]]);
    });

    test('parses data with \r\n line endings', () {
      const data = '1,2\r\n3,4';
      expect(csvToList(data), [[1, 2], [3, 4]]);
    });
  });

  group('formatWorkingHours', () {
    test('no minutes when decimal part is zero', () {
      expect(formatWorkingHours(2.0), '2 hours');
    });

    test('converts fractional hours to minutes', () {
      expect(formatWorkingHours(1.5), '1 hours & 30 minutes');
      expect(formatWorkingHours(2.25), '2 hours & 15 minutes');
    });

    test('rounds minutes correctly', () {
      expect(formatWorkingHours(0.016), '0 hours & 1 minutes');
    });
  });

  group('MapExtensions', () {
    final map = {
      'double': 2.5,
      'int': 2,
      'list': <int>[1, 2, 3],
      'string': 'value',
    };

    test('getDouble returns stored double', () {
      expect(map.getDouble('double'), 2.5);
    });

    test('getDouble returns default when type mismatch', () {
      expect(map.getDouble('int'), 0.0);
      expect(map.getDouble('missing', 1.2), 1.2);
    });

    test('getList returns list of correct type or empty', () {
      expect(map.getList<int>('list'), <int>[1, 2, 3]);
      expect(map.getList<String>('string'), <String>[]);
    });

    test('getValue respects type and default', () {
      expect(map.getValue<String>('string'), 'value');
      expect(map.getValue<int>('missing', defaultValue: 5), 5);
      expect(map.getValue<int>('double', defaultValue: 4), 4);
    });
  });

  test('ColorAlphaExtension uses withOpacity under the hood', () {
    const color = Colors.red;
    expect(color.withValues(alpha: 0.5), color.withOpacity(0.5));
  });
}
