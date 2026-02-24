import 'dart:io';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const HijriCalendarApp());
}

class HijriCalendarApp extends StatelessWidget {
  const HijriCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hijri Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Serif',
        scaffoldBackgroundColor: const Color(0xFFF3F0D7),
      ),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late int _currentYear;
  late int _currentMonth;
  late int _selectedDay;
  int _offset = 0;
  bool _isExporting = false;

  final Map<String, Map<String, String>> _holidays = {
    '1/1': {'en': 'Islamic New Year', 'ar': 'رأس السنة الهجرية'},
    '1/10': {'en': 'Ashura', 'ar': 'عاشوراء'},
    '3/12': {'en': 'Mawlid al-Nabi', 'ar': 'المولد النبوي'},
    '9/1': {'en': 'Ramadan Start', 'ar': 'بداية رمضان'},
    '10/1': {'en': 'Eid al-Fitr', 'ar': 'عيد الفطر'},
    '10/2': {'en': 'Eid al-Fitr (Day 2)', 'ar': 'عيد الفطر'},
    '10/3': {'en': 'Eid al-Fitr (Day 3)', 'ar': 'عيد الفطر'},
    '12/9': {'en': 'Arafat Day', 'ar': 'يوم عرفة'},
    '12/10': {'en': 'Eid al-Adha', 'ar': 'عيد الأضحى'},
    '12/11': {'en': 'Eid al-Adha (Day 2)', 'ar': 'عيد الأضحى'},
    '12/12': {'en': 'Eid al-Adha (Day 3)', 'ar': 'عيد الأضحى'},
  };

  final List<Map<String, String>> _monthNames = [
    {'en': 'Muharram', 'ar': 'محرم'},
    {'en': 'Safar', 'ar': 'صفر'},
    {'en': 'Rabi\' al-Awwal', 'ar': 'ربيع الأول'},
    {'en': 'Rabi\' al-Thani', 'ar': 'ربيع الآخر'},
    {'en': 'Jumada al-Awwal', 'ar': 'جمادى الأولى'},
    {'en': 'Jumada al-Thani', 'ar': 'جمادى الآخرة'},
    {'en': 'Rajab', 'ar': 'رجب'},
    {'en': 'Sha\'ban', 'ar': 'شعبان'},
    {'en': 'Ramadan', 'ar': 'رمضان'},
    {'en': 'Shawwal', 'ar': 'شوال'},
    {'en': 'Dhu al-Qi\'dah', 'ar': 'ذو القعدة'},
    {'en': 'Dhu al-Hijjah', 'ar': 'ذو الحجة'},
  ];

  final List<String> _dhivehiWeekdays = const [
    'އާދިއްތަ',
    'ހޯމަ',
    'އަންގާރަ',
    'ބުދަ',
    'ބުރާސްފަތި',
    'ހުކުރު',
    'ހޮނިހިރު',
  ];

  final List<String> _dhivehiGregorianMonths = const [
    'ޖެނުއަރީ',
    'ފެބްރުއަރީ',
    'މާރިޗު',
    'އޭޕްރިލް',
    'މޭ',
    'ޖޫން',
    'ޖުލައި',
    'އޯގަސްޓް',
    'ސެޕްޓެމްބަރ',
    'އޮކްޓޯބަރ',
    'ނޮވެމްބަރ',
    'ޑިސެމްބަރ',
  ];

  @override
  void initState() {
    super.initState();
    _jumpToToday();
  }

  void _jumpToToday() {
    final HijriCalendar now = HijriCalendar.now();
    setState(() {
      _currentYear = now.hYear;
      _currentMonth = now.hMonth;
      _selectedDay = now.hDay;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      int year = _currentYear;
      int month = _currentMonth + delta;

      if (month < 1) {
        month = 12;
        year -= 1;
      } else if (month > 12) {
        month = 1;
        year += 1;
      }

      _currentYear = year;
      _currentMonth = month;
      final int maxDay = _getMonthLength(_currentYear, _currentMonth);
      _selectedDay = _selectedDay > maxDay ? maxDay : _selectedDay;
    });
  }

  DateTime _hijriToGregorianWithOffset(int year, int month, int day) {
    final HijriCalendar hDate = HijriCalendar()
      ..hYear = year
      ..hMonth = month
      ..hDay = day;

    DateTime gDate = hDate.hijriToGregorian(year, month, day);
    gDate = gDate.add(Duration(days: _offset));
    return gDate;
  }

  int _getMonthLength(int year, int month) {
    final DateTime gDate = _hijriToGregorianWithOffset(year, month, 1);
    final HijriCalendar corrected = HijriCalendar.fromDate(gDate);
    return corrected.lengthOfMonth;
  }

  _CalendarMeta _buildMeta() {
    final DateTime firstDayG = _hijriToGregorianWithOffset(
      _currentYear,
      _currentMonth,
      1,
    );
    int startWeekday = firstDayG.weekday;
    if (startWeekday == DateTime.sunday) {
      startWeekday = 0;
    }

    final int currentMonthLength = _getMonthLength(_currentYear, _currentMonth);

    int prevYear = _currentYear;
    int prevMonth = _currentMonth - 1;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear -= 1;
    }

    int nextYear = _currentYear;
    int nextMonth = _currentMonth + 1;
    if (nextMonth == 13) {
      nextMonth = 1;
      nextYear += 1;
    }

    final int prevMonthLength = _getMonthLength(prevYear, prevMonth);

    final List<_CalendarCellData> cells = [];

    for (int index = 0; index < 42; index++) {
      final int relativeDay = index - startWeekday + 1;

      if (relativeDay < 1) {
        final int day = prevMonthLength + relativeDay;
        cells.add(
          _CalendarCellData(
            hYear: prevYear,
            hMonth: prevMonth,
            hDay: day,
            gDate: _hijriToGregorianWithOffset(prevYear, prevMonth, day),
            inCurrentMonth: false,
          ),
        );
      } else if (relativeDay > currentMonthLength) {
        final int day = relativeDay - currentMonthLength;
        cells.add(
          _CalendarCellData(
            hYear: nextYear,
            hMonth: nextMonth,
            hDay: day,
            gDate: _hijriToGregorianWithOffset(nextYear, nextMonth, day),
            inCurrentMonth: false,
          ),
        );
      } else {
        cells.add(
          _CalendarCellData(
            hYear: _currentYear,
            hMonth: _currentMonth,
            hDay: relativeDay,
            gDate: _hijriToGregorianWithOffset(
              _currentYear,
              _currentMonth,
              relativeDay,
            ),
            inCurrentMonth: true,
          ),
        );
      }
    }

    return _CalendarMeta(cells: cells);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final String sheetName = 'Hijri $_currentYear';
      final excel_pkg.Sheet sheet = excel[sheetName];

      final excel_pkg.CellStyle titleStyle = excel_pkg.CellStyle(
        backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#4472C4'),
        fontColorHex: excel_pkg.ExcelColor.white,
        bold: true,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      final excel_pkg.CellStyle weekStyle = excel_pkg.CellStyle(
        backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#D9D9D9'),
        bold: true,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      final excel_pkg.CellStyle dayStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        fontSize: 12,
      );

      const int monthsPerGridRow = 3;
      const int monthBlockWidth = 8;
      const int monthBlockHeight = 9;

      for (int m = 1; m <= 12; m++) {
        final int gridColIndex = (m - 1) % monthsPerGridRow;
        final int gridRowIndex = (m - 1) ~/ monthsPerGridRow;

        final int startCol = gridColIndex * monthBlockWidth;
        final int startRow = gridRowIndex * monthBlockHeight;

        sheet.merge(
          excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: startCol,
            rowIndex: startRow,
          ),
          excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: startCol + 6,
            rowIndex: startRow,
          ),
          customValue: excel_pkg.TextCellValue(_monthNames[m - 1]['en']!),
        );

        final titleCell = sheet.cell(
          excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: startCol,
            rowIndex: startRow,
          ),
        );
        titleCell.cellStyle = titleStyle;

        const List<String> weekHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
        for (int i = 0; i < 7; i++) {
          final cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: startCol + i,
              rowIndex: startRow + 1,
            ),
          );
          cell.value = excel_pkg.TextCellValue(weekHeaders[i]);
          cell.cellStyle = weekStyle;
        }

        final DateTime monthStart = _hijriToGregorianWithOffset(
          _currentYear,
          m,
          1,
        );

        int startWeekday = monthStart.weekday;
        if (startWeekday == DateTime.sunday) {
          startWeekday = 0;
        }

        final HijriCalendar correctedHDate = HijriCalendar.fromDate(monthStart);
        final int monthLength = correctedHDate.lengthOfMonth;

        for (int i = 0; i < monthLength; i++) {
          final int hijriDay = i + 1;
          final int absoluteIndex = i + startWeekday;
          final int rowInMonth = absoluteIndex ~/ 7;
          final int colInMonth = absoluteIndex % 7;

          final int excelCol = startCol + colInMonth;
          final int excelRow = startRow + 2 + rowInMonth;

          final cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: excelCol,
              rowIndex: excelRow,
            ),
          );

          cell.value = excel_pkg.TextCellValue('$hijriDay');
          cell.cellStyle = dayStyle;
        }
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/Hijri_Only_$_currentYear.xlsx';
        final File file = File(path);
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles([
          XFile(path),
        ], text: 'Hijri Calendar $_currentYear');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');

    final _CalendarMeta meta = _buildMeta();
    final _CalendarCellData selected = meta.cells.firstWhere(
      (cell) =>
          cell.inCurrentMonth &&
          cell.hYear == _currentYear &&
          cell.hMonth == _currentMonth &&
          cell.hDay == _selectedDay,
      orElse: () => meta.cells.firstWhere((cell) => cell.inCurrentMonth),
    );

    final String monthAr = _monthNames[_currentMonth - 1]['ar']!;
    final String selectedHijriDay = _toArabicNum(selected.hDay);
    final String selectedHijriYear = _toArabicNum(_currentYear);
    final String selectedGregorian =
        '${_toArabicNum(selected.gDate.day)} ${_dhivehiMonthName(selected.gDate.month)} ${_toArabicNum(selected.gDate.year)}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6EE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                _buildTopStrip(
                  selectedHijriDay,
                  monthAr,
                  selectedHijriYear,
                  selectedGregorian,
                ),
                const SizedBox(height: 10),
                _buildMonthSelectorCard(),
                const SizedBox(height: 10),
                _buildWeekHeader(),
                const SizedBox(height: 8),
                Expanded(child: _buildCalendarGrid(meta)),
                const SizedBox(height: 8),
                _buildHolidaysPanel(),
                const SizedBox(height: 8),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStrip(
    String hijriDay,
    String hijriMonth,
    String hijriYear,
    String gregorianText,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFECE8D2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: _jumpToToday,
              icon: const Icon(Icons.today_rounded, color: Color(0xFF5D5D58)),
              tooltip: 'Today',
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hijriDay,
                        style: _arabicStyle(
                          size: 36,
                          color: const Color(0xFF1A1A1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        hijriMonth,
                        style: _arabicStyle(
                          size: 36,
                          color: const Color(0xFF1A1A1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        hijriYear,
                        style: _arabicStyle(
                          size: 36,
                          color: const Color(0xFF1A1A1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    gregorianText,
                    style: _dhivehiStyle(
                      size: 18,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _weekdayNameDhivehi(
                      _hijriToGregorianWithOffset(
                        _currentYear,
                        _currentMonth,
                        _selectedDay,
                      ).weekday,
                    ),
                    style: _dhivehiStyle(
                      size: 20,
                      color: const Color(0xFF252525),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isExporting ? null : _exportToExcel,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.ios_share_rounded,
                      color: Color(0xFF5D5D58),
                    ),
              tooltip: 'Export',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    final String monthAr = _monthNames[_currentMonth - 1]['ar']!;
    final String monthDv = _dhivehiMonthName(
      _hijriToGregorianWithOffset(
        _currentYear,
        _currentMonth,
        _selectedDay,
      ).month,
    );
    final String hijriDay = _toArabicNum(_selectedDay);
    final String hijriYear = _toArabicNum(_currentYear);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E2CC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right_rounded, size: 30),
              color: const Color(0xFF6A6A62),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hijriDay,
                        style: _arabicStyle(
                          size: 34,
                          color: const Color(0xFF1E1E1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        monthAr,
                        style: _arabicStyle(
                          size: 34,
                          color: const Color(0xFF1E1E1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        hijriYear,
                        style: _arabicStyle(
                          size: 34,
                          color: const Color(0xFF1E1E1A),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    monthDv,
                    style: _dhivehiStyle(
                      size: 16,
                      color: const Color(0xFF4A4A43),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
              color: const Color(0xFF6A6A62),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return SizedBox(
      height: 34,
      child: Row(
        children: List.generate(7, (index) {
          final bool weekend = index == 5 || index == 6;
          return Expanded(
            child: Center(
              child: Text(
                _dhivehiWeekdays[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _dhivehiStyle(
                  size: 14,
                  color: weekend
                      ? const Color(0xFFD55B55)
                      : const Color(0xFF4A4A45),
                  weight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid(_CalendarMeta meta) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.92,
      ),
      itemCount: meta.cells.length,
      itemBuilder: (context, index) {
        final _CalendarCellData cell = meta.cells[index];
        final bool isSelected =
            cell.inCurrentMonth &&
            cell.hYear == _currentYear &&
            cell.hMonth == _currentMonth &&
            cell.hDay == _selectedDay;

        final String holidayKey = '${cell.hMonth}/${cell.hDay}';
        final bool isHoliday = _holidays.containsKey(holidayKey);
        final int colIndex = index % 7;
        final bool isWeekend = colIndex == 5 || colIndex == 6;

        final Color hijriColor;
        if (!cell.inCurrentMonth) {
          hijriColor = const Color(0xFFA3A39B);
        } else if (isHoliday || isWeekend) {
          hijriColor = const Color(0xFFD35A54);
        } else {
          hijriColor = const Color(0xFF1D1D1A);
        }

        final Color gColor = cell.inCurrentMonth
            ? const Color(0xFF8A8A82)
            : const Color(0xFFC4C4BB);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _currentYear = cell.hYear;
              _currentMonth = cell.hMonth;
              _selectedDay = cell.hDay;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE1DCC8) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: const Color(0xFFD2CBB1))
                  : Border.all(color: Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _toArabicNum(cell.hDay),
                  style: _arabicStyle(
                    size: 38,
                    color: hijriColor,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${cell.gDate.day}',
                  style: _arabicStyle(size: 14, color: gColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Offset ${_offset >= 0 ? '+' : ''}$_offset',
              style: const TextStyle(color: Color(0xFF6B6B65), fontSize: 12),
            ),
            IconButton(
              onPressed: () => setState(() => _offset--),
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              color: const Color(0xFF6B6B65),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => setState(() => _offset++),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              color: const Color(0xFF6B6B65),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysPanel() {
    final List<MapEntry<String, Map<String, String>>> monthHolidays =
        _holidays.entries
            .where((entry) => entry.key.startsWith('$_currentMonth/'))
            .toList()
          ..sort((a, b) {
            final int dayA = int.parse(a.key.split('/')[1]);
            final int dayB = int.parse(b.key.split('/')[1]);
            return dayA.compareTo(dayB);
          });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 150,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E0CC)),
          ),
          child: monthHolidays.isEmpty
              ? Center(
                  child: Text(
                    'މިމަހު ބަންދު ދުވަހެއް ނެތެވެ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: _dhivehiStyle(
                      size: 13,
                      color: const Color(0xFF76766F),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  itemCount: monthHolidays.length,
                  separatorBuilder: (_, unused) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = monthHolidays[index];
                    final int day = int.parse(entry.key.split('/')[1]);
                    final data = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8E2C8),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _toArabicNum(day),
                              style: _arabicStyle(
                                size: 16,
                                color: const Color(0xFF30302A),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['en'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF3F3F39),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data['ar'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: _arabicStyle(
                                    size: 15,
                                    color: const Color(0xFF44443C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _dhivehiMonthName(int month) {
    return _dhivehiGregorianMonths[month - 1];
  }

  String _weekdayNameDhivehi(int weekday) {
    const List<String> weekdays = [
      'ހޯމަ',
      'އަންގާރަ',
      'ބުދަ',
      'ބުރާސްފަތި',
      'ހުކުރު',
      'ހޮނިހިރު',
      'އާދިއްތަ',
    ];
    return weekdays[weekday - 1];
  }

  String _toArabicNum(int input) {
    const List<String> english = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];
    const List<String> arabic = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];

    String value = input.toString();
    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], arabic[i]);
    }
    return value;
  }

  TextStyle _arabicStyle({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'KfgqpcUthmanic',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.05,
      fontFeatures: const [
        FontFeature.enable('rlig'),
        FontFeature.enable('liga'),
        FontFeature.enable('calt'),
        FontFeature.enable('ccmp'),
        FontFeature.enable('mark'),
        FontFeature.enable('mkmk'),
      ],
    );
  }

  TextStyle _dhivehiStyle({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'Faseyha',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.05,
    );
  }
}

class _CalendarMeta {
  _CalendarMeta({required this.cells});

  final List<_CalendarCellData> cells;
}

class _CalendarCellData {
  _CalendarCellData({
    required this.hYear,
    required this.hMonth,
    required this.hDay,
    required this.gDate,
    required this.inCurrentMonth,
  });

  final int hYear;
  final int hMonth;
  final int hDay;
  final DateTime gDate;
  final bool inCurrentMonth;
}
