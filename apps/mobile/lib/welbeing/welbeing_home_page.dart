import 'package:flutter/material.dart';

import 'doctor_patient_list_page.dart';
import 'education_page.dart';
import 'patient_wellbeing_page.dart';
import '../login_page.dart';
import '../service/language_service.dart';
import '../theme/brand_theme.dart';

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
                      style: BrandTypography.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: BrandTypography.body(
                        fontSize: 12,
                        color: BrandColors.mutedInk,
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
        backgroundColor: BrandColors.pageBg,
        appBar: AppBar(
          title: Text(
            'Well-Being',
            style: BrandTypography.heading(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: BrandColors.navy,
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final bool isWide = w >= 720;
              final bool isSmall = w < 380;
              final double emblemBox = isSmall ? 46 : 56;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmall ? 15 : 18),
                          decoration: BoxDecoration(
                            gradient: BrandColors.heroHeaderGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isClinician
                                          ? 'Patient Monitoring'
                                          : 'Patient Well-being',
                                      style: BrandTypography.heading(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmall ? 19 : 22,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isClinician
                                          ? 'Review Distress Status, Therapy Change and Metastasis Update'
                                          : 'Track sleep, mood, activities, and supportive education.',
                                      style: BrandTypography.body(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.asset(
                                  'assets/images/mdosthi-emblem.png',
                                  width: emblemBox,
                                  height: emblemBox,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
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
                            subtitle:
                                'Track mood, activities, and daily routines.',
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
              );
            },
          ),
        ),
      ),
    );
  }
}
