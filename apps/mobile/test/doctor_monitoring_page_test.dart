import 'package:app_001/welbeing/doctor_monitoring_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders profile details from the selected patient record',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DoctorMonitoringPage(
          patientId: 'PAT-123',
          patientProfile: {
            'pat_id': 'PAT-123',
            'name': 'Sample Patient',
            'age': '42 years',
            'sex': 'Female',
            'appointment_date': '12-10-2026 10:00',
            'entry_date': '01-10-2026',
          },
        ),
      ),
    );

    expect(find.text('Sample Patient'), findsOneWidget);
    expect(find.text('Patient ID: PAT-123'), findsOneWidget);
    expect(find.text('Age: 42 years'), findsOneWidget);
    expect(find.text('Gender: Female'), findsOneWidget);
    expect(find.text('Appointment: 12-10-2026 10:00'), findsOneWidget);
    expect(find.text('Registered: 01-10-2026'), findsOneWidget);
  });
}