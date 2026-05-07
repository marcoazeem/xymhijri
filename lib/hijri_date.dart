import 'package:hijri/hijri_calendar.dart';

DateTime hijriToGregorianWithOffset(int year, int month, int day, int offset) {
  final HijriCalendar hDate = HijriCalendar()
    ..hYear = year
    ..hMonth = month
    ..hDay = day;
  final DateTime gDate = hDate.hijriToGregorian(year, month, day);
  return gDate.add(Duration(days: offset));
}

int hijriMonthLength(int year, int month, int offset) {
  final DateTime gDate = hijriToGregorianWithOffset(year, month, 1, offset);
  return HijriCalendar.fromDate(gDate).lengthOfMonth;
}
