import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/pdf_viewer_widget.dart';
import '../service/language_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_page.dart';

class ReadableModel {
  final String id;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final String url;
  final List<Color> gradientColors;

  const ReadableModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.url,
    required this.gradientColors,
  });
}

class ReadableLibraryScreen extends StatelessWidget {
  const ReadableLibraryScreen({super.key});

  static const List<ReadableModel> readables = [
    ReadableModel(
      id: "1st pdf",
      titleBn: "গর্ভাবস্থায় ধূমপান ত্যাগ করার প্রয়োজনীয়তা ",
      titleEn: "Importance of Quitting Smoking During Pregnancy",
      descriptionEn:
          "A detailed guide to help understand tobacco addiction and step-by-step methods to quit smoking.",
      descriptionBn:
          "তামাকাসক্তি বুঝতে এবং ধূমপান ছাড়ার ধাপে ধাপে পদ্ধতি জানতে সাহায্য করার জন্য একটি বিস্তারিত নির্দেশিকা।",
      url: "assets/1.pdf",
      gradientColors: [Color(0xFFe65c00), Color(0xFFF9D423)],
    ),
    ReadableModel(
      id: "2nd pdf",
      titleBn: "তামাকঘটিত রোগ",
      titleEn: "Tobacco-related Diseases",
      descriptionEn:
          "Educational poster highlighting the tobacco cessation process, symptoms, and support contacts.",
      descriptionBn:
          "তামাক বর্জন প্রক্রিয়া, লক্ষণ এবং সহায়তা পরিচিতি তুলে ধরে শিক্ষামূলক পোস্টার।",
      url: "assets/2.pdf",
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    ReadableModel(
      id: "3rd pdf",
      titleBn: "নিকোটিন রিপ্লেসমেন্ট থেরাপি(NRT)",
      titleEn: "Nicotine Replacement Therapy (NRT)",
      descriptionEn:
          "Official World Health Organization publication and statistics regarding tobacco control.",
      descriptionBn:
          "তামাক নিয়ন্ত্রণ সংক্রান্ত বিশ্ব স্বাস্থ্য সংস্থার সরকারি প্রকাশনা এবং পরিসংখ্যান।",
      url: "assets/3.pdf",
      gradientColors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    ),
    ReadableModel(
      id: "4th pdf",
      titleBn: "ধূমপান ছাড়ার সুফল",
      titleEn: "Benefits of Quitting Smoking",
      descriptionEn:
          "A guide discussing the health impacts of smoking, shisha, and chewing tobacco, with coping tools.",
      descriptionBn:
          "ধূমপান, শিশা এবং চিবানো তামাকের স্বাস্থ্যের প্রভাব নিয়ে আলোচনা করা একটি নির্দেশিকা, সঙ্গে মোকাবিলার উপায়।",
      url: "assets/4.pdf",
      gradientColors: [Color(0xFF8e2de2), Color(0xFF4a00e0)],
    ),
    ReadableModel(
      id: "5th pdf",
      titleBn: "শরীরের উপর তামাকের প্রভাব (WHO)",
      titleEn: "Effects of Tobacco on the Body (WHO)",
      descriptionEn:
          "Standard standee presentation guide highlighting general guidelines for cessation programs.",
      descriptionBn:
          "বর্জন কর্মসূচির জন্য সাধারণ নির্দেশিকা তুলে ধরে আদর্শ স্ট্যান্ডি উপস্থাপনা নির্দেশিকা।",
      url: "assets/5.pdf",
      gradientColors: [Color(0xFFff00cc), Color(0xFF333399)],
    ),
  ];

  Future<void> _trackPdfOpen(String id) async {
    if (LoginPage.userId.isEmpty) return;
    final progressUrl =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/save-progress";
    try {
      final response = await http.post(
        Uri.parse(progressUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'userid': LoginPage.userId,
          'item_id': id,
          'item_type': 'pdf',
        }),
      );
      print(
          "ReadableLibraryScreen: PDF open tracked. Response: ${response.statusCode}");
    } catch (e) {
      print("ReadableLibraryScreen: Error tracking PDF open: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();

    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey.shade800,
            title: Text(
              languageService.getText('readable_materials'),
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageService.getText('educational_docs'),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          languageService.getText('select_doc_read'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Readables list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: readables.length,
                      itemBuilder: (context, index) {
                        final pdf = readables[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Colors.grey.shade200, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              _trackPdfOpen(pdf.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      getPdfViewerWidget(pdf.url),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                // Thumbnail (gradient design)
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: pdf.gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 38,
                                    color: Colors.white,
                                  ),
                                ),

                                // Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          languageService.isBengali
                                              ? pdf.titleBn
                                              : pdf.titleEn,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade900,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          languageService.isBengali
                                              ? pdf.descriptionBn
                                              : pdf.descriptionEn,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Arrow indicator
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
