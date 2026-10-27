import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/language_service.dart';

class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.grey.shade900)),
                const SizedBox(height: 6),
                Text(description,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distortions = [
      {
        'title': 'All-or-Nothing Thinking',
        'description': 'Seeing situations as completely good or completely bad.\nExample: “If I am not perfect, I have failed.”\nAlternative view: “I can still learn and improve without judging the whole thing as a failure.”',
      },
      {
        'title': 'Overgeneralization',
        'description': 'Taking one event and treating it as a pattern for everything.\nExample: “I felt low once, so I will always feel this way.”\nAlternative view: “This is one situation, not proof of every future outcome.”',
      },
      {
        'title': 'Catastrophizing',
        'description': 'Expecting the worst possible outcome.\nExample: “If this goes wrong, everything will collapse.”\nAlternative view: “What is the most realistic outcome and how can I respond calmly?”',
      },
      {
        'title': 'Mind Reading',
        'description': 'Assuming you know what others are thinking.\nExample: “They think I am weak.”\nAlternative view: “I do not know their thoughts; I can ask or focus on what I know.”',
      },
      {
        'title': 'Fortune Telling',
        'description': 'Believing you already know what will happen in the future.\nExample: “I know I will fail this conversation.”\nAlternative view: “I can plan for this moment without assuming the worst.”',
      },
      {
        'title': 'Personalization',
        'description': 'Taking responsibility for things that are not yours to control.\nExample: “It is my fault they are upset.”\nAlternative view: “I can notice my role without assuming full responsibility for others’ feelings.”',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Education', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'Mood & Activity Explanation',
                description:
                    'Why mood tracking is useful: it helps you notice patterns, stressors, and recovery moments. Why activity tracking is useful: it supports routine, purpose, and daily structure. It is helpful to maintain daily structure and speak with the healthcare team if concerns persist for a long time.',
                icon: Icons.track_changes_rounded,
                color: Colors.teal.shade700,
              ),
              _buildInfoCard(
                title: 'What is CBT?',
                description:
                    'CBT means Cognitive Behavioural Therapy. It focuses on the connection between thoughts, feelings, and behaviour. Sometimes unhelpful thinking patterns can make stress, sadness, or worry feel bigger. Professional guidance can help you explore this gently and practically.',
                icon: Icons.psychology_alt_rounded,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                'Cognitive Distortions',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
              ),
              const SizedBox(height: 8),
              ...distortions.map((item) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
                        const SizedBox(height: 8),
                        Text(item['description'] as String, style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: Colors.grey.shade700)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
