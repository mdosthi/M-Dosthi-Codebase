import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'doctor_patient_list_page.dart';
import 'education_page.dart';
import 'patient_wellbeing_page.dart';
import '../login_page.dart';
import '../service/language_service.dart';

class WelbeingHomePage extends StatelessWidget {
  const WelbeingHomePage({super.key});

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withOpacity(0.18), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClinician = LoginPage.isClinician;

    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'Well-Being',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClinician
                            ? 'Patient Monitoring'
                            : 'Patient Well-being',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isClinician
                            ? 'Review Distress Status, Therapy Change and Metastasis Update'
                            : 'Track sleep, mood, activities, and supportive education.',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (isClinician)
                  _buildSectionCard(
                    context,
                    icon: Icons.monitor_heart_rounded,
                    title: 'Patient Monitoring',
                    subtitle:
                        'Review Distress Status, Therapy Change and Metastasis Update',
                    color: Colors.red.shade600,
                    destination: const DoctorPatientListPage(),
                  )
                else ...[
                  _buildSectionCard(
                    context,
                    icon: Icons.bedtime_rounded,
                    title: LanguageService().getText('sleep_hygiene'),
                    subtitle:
                        'Log sleep timing, quality, and night awakenings.',
                    color: Colors.indigo.shade600,
                    destination: const PatientWellbeingPage(
                        tab: WellbeingTab.sleepHygiene),
                  ),
                  _buildSectionCard(
                    context,
                    icon: Icons.psychology_alt_rounded,
                    title: LanguageService().getText('mood_activity'),
                    subtitle: 'Track mood, activities, and daily routines.',
                    color: Colors.orange.shade700,
                    destination: const PatientWellbeingPage(
                        tab: WellbeingTab.moodActivity),
                  ),
                  _buildSectionCard(
                    context,
                    icon: Icons.school_rounded,
                    title: LanguageService().getText('education'),
                    subtitle:
                        'Learn about mood, CBT, and cognitive distortions.',
                    color: Colors.teal.shade700,
                    destination: const EducationPage(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
