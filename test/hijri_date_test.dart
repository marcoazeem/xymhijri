import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:xymhijri/hijri_date.dart';

void main() {
  group('hijriToGregorianWithOffset', () {
    test('with offset 0 matches the package conversion', () {
      final base = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 9
        ..hDay = 1;
      final expected = base.hijriToGregorian(1446, 9, 1);
      expect(hijriToGregorianWithOffset(1446, 9, 1, 0), expected);
    });

    test('positive offset shifts the result forward by N days', () {
      final zero = hijriToGregorianWithOffset(1446, 1, 1, 0);
      final shifted = hijriToGregorianWithOffset(1446, 1, 1, 3);
      expect(shifted.difference(zero).inDays, 3);
    });

    test('negative offset shifts the result backward by N days', () {
      final zero = hijriToGregorianWithOffset(1446, 12, 10, 0);
      final shifted = hijriToGregorianWithOffset(1446, 12, 10, -2);
      expect(shifted.difference(zero).inDays, -2);
    });

    test('different Hijri days produce different Gregorian days', () {
      final d1 = hijriToGregorianWithOffset(1446, 1, 1, 0);
      final d2 = hijriToGregorianWithOffset(1446, 1, 2, 0);
      expect(d2.difference(d1).inDays, 1);
    });
  });

  group('hijriMonthLength', () {
    test('returns 29 or 30 days for a known month with no offset', () {
      final length = hijriMonthLength(1446, 9, 0);
      expect(length, anyOf(29, 30));
    });

    test('all 12 months of 1446 are 29 or 30 days', () {
      for (int m = 1; m <= 12; m++) {
        final length = hijriMonthLength(1446, m, 0);
        expect(length, anyOf(29, 30), reason: 'month $m');
      }
    });

    test('iterating each day of a month covers exactly its length', () {
      final length = hijriMonthLength(1446, 1, 0);
      final start = hijriToGregorianWithOffset(1446, 1, 1, 0);
      final end = hijriToGregorianWithOffset(1446, 1, length, 0);
      expect(end.difference(start).inDays, length - 1);
    });
  });
}
