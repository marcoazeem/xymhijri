import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xymhijri/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and renders the calendar shell', (tester) async {
    await tester.pumpWidget(const HijriCalendarApp());
    await tester.pump();

    expect(find.byTooltip('Today'), findsOneWidget);
    expect(find.byTooltip('Export'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
  });

  testWidgets('persisted offset is restored on launch', (tester) async {
    SharedPreferences.setMockInitialValues({'hijri_offset': 5});

    await tester.pumpWidget(const HijriCalendarApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Offset +5'), findsOneWidget);
  });
}
