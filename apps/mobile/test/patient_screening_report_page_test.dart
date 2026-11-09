import 'package:mdosthi_app/welbeing/patient_screening_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an individual follow-up date and countdown per screening',
      (tester) async {
    final schedules = [
      {
        'screeningType': 'PO Bado',
        'nextCheckpoint': '4 week Assessment',
        'dueDate': '2026-03-10',
        'countdown': 'Due in 2 days',
      },
      {
        'screeningType': 'Distress Thermometer',
        'nextCheckpoint': '8 week Assessment',
        'dueDate': '2026-03-12',
        'countdown': 'Due in 4 days',
      },
      {
        'screeningType': 'PHQ-9',
        'nextCheckpoint': '12 week Assessment',
        'dueDate': '2026-03-16',
        'countdown': 'Due in 8 days',
      },
      {
        'screeningType': 'GAD-7',
        'nextCheckpoint': '4 week Assessment',
        'dueDate': '2026-03-18',
        'countdown': 'Due in 10 days',
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: schedules
                  .map((item) => ScreeningScheduleCard(item: item))
                  .toList(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Next follow-up date'), findsNWidgets(schedules.length));
    for (final schedule in schedules) {
      expect(find.text(schedule['screeningType']!), findsOneWidget);
      expect(find.text(schedule['dueDate']!), findsOneWidget);
      expect(find.text(schedule['countdown']!), findsOneWidget);
    }
    expect(find.textContaining('Saved follow-up date'), findsNothing);
    expect(find.textContaining('Not scheduled'), findsNothing);
  });
}
