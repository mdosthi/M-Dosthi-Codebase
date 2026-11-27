import 'package:mdosthi_app/EditProfilePage.dart';
import 'package:mdosthi_app/surveyor/video_playback.dart';
import 'package:flutter/material.dart';
import '../service/language_service.dart';
import './form_list_page.dart';
import './chat_page.dart';
import './chat_history_page.dart';
import 'package:mdosthi_app/surveyor/hamburger_menu.dart';
import 'package:mdosthi_app/utils/NetworkSpeedChecker.dart';
import '../login_page.dart';
import '../main.dart';
import '../theme/brand_theme.dart';
import '../welbeing/welbeing_home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mdosthi_app/surveyor/readable_library.dart';

class SurveyorPageUtil extends StatefulWidget {
  const SurveyorPageUtil({super.key});

  @override
  SurveyorPageUtilState createState() => SurveyorPageUtilState();
}

class SurveyorPageUtilState extends State<SurveyorPageUtil> {
  final languageService = LanguageService();
  bool hasActiveSession = false;
  bool isLoadingChatStatus = false;
  bool isEnrolledInRCT = false;
  bool isLoadingRCTStatus = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    await Future.wait([
      _checkRCTEnrollment(),
      _loadChatStatus(),
    ]);
  }

  Future<void> _checkRCTEnrollment() async {
    setState(() => isLoadingRCTStatus = true);

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/check-rct-enrollment";

      debugPrint('Checking RCT enrollment for patient: ${LoginPage.patid}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      debugPrint('RCT enrollment response status: ${response.statusCode}');
      debugPrint('RCT enrollment response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            isEnrolledInRCT = jsonResponse['is_enrolled'] ?? false;
          });
          debugPrint('RCT enrollment status: $isEnrolledInRCT');
        } else {
          debugPrint('RCT enrollment API error: ${jsonResponse['message']}');
          setState(() => isEnrolledInRCT = false);
        }
      } else {
        debugPrint('RCT enrollment HTTP error: ${response.statusCode}');
        setState(() => isEnrolledInRCT = false);
      }
    } catch (e) {
      debugPrint('Error checking RCT enrollment: $e');
      setState(() => isEnrolledInRCT = false);
    } finally {
      setState(() => isLoadingRCTStatus = false);
    }
  }

  Future<void> _loadChatStatus() async {
    // Only check chat status if enrolled in RCT
    if (!isEnrolledInRCT) return;

    setState(() => isLoadingChatStatus = true);
    await _checkActiveSession();
    setState(() => isLoadingChatStatus = false);
  }

  Future<void> _withdrawDpdpConsent() async {
    // Step 1 — confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Consent'),
        content: const Text(
          'Are you sure you want to withdraw your data protection consent?\n\n'
          'Your consent will be removed and you will be logged out of the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 2 — call backend
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/withdraw-dpdp-consent";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'uid': LoginPage.userId}),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (!mounted) return;
        // Step 3 — logout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to withdraw consent. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkActiveSession() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-active-session";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            hasActiveSession = jsonResponse['session'] != null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking active session: $e');
      setState(() {
        hasActiveSession = false;
      });
    }
  }

  Widget _buildChatButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: hasActiveSession
            ? const LinearGradient(
                colors: [
                  BrandColors.tealDark,
                  BrandColors.teal,
                  BrandColors.blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : BrandColors.ctaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BrandColors.teal.withOpacity(0.26),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
            if (result != null) {
              _loadChatStatus();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BrandColors.light,
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(
                          'assets/icons/feature-counselling.png',
                        ),
                      ),
                    ),
                    if (hasActiveSession)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: BrandColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.getText('chat_with_mdosthi'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasActiveSession
                            ? (languageService.isBengali
                                ? "সেশন সচল রয়েছে - পুনরায় শুরু করতে চাপুন"
                                : "Active session - tap to resume conversation")
                            : (languageService.isBengali
                                ? "স্বাস্থ্য সংক্রান্ত সাহায্য এবং পরামর্শ পান"
                                : "Get instant support & answers for your health"),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoadingChatStatus)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatHistoryButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.navy.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatHistoryPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.navy.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: BrandColors.navy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.getText('chat_history'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        languageService.isBengali
                            ? "আপনার আগের কথোপকথনগুলি দেখুন"
                            : "View your past conversations with mDosthi",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.12), width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageService.isBengali ? "খুলুন" : "Open",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          drawer: HamburgerMenu(
            userName: LoginPage.userId,
            email: LoginPage.username,
            pages: const [
              SurveyorPageUtil(),
              EditProfilePage(),
              LoginPage(),
              NetworkSpeedChecker(),
              SurveyorPageUtil(),
            ],
            icons: const [
              Icons.home,
              Icons.person,
              Icons.logout,
              Icons.network_cell_rounded,
              Icons.edit_outlined,
            ],
            pageTitles: [
              languageService.getText('home'),
              languageService.getText('editProfile'),
              languageService.getText('logout'),
              languageService.getText('bandwidth'),
              languageService.getText('changeUsername'),
            ],
            reloadCallback: () {
              setState(() {});
            },
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: BrandColors.navy,
            titleSpacing: 8,
            title: const MdosthiHorizontalLogo(
              height: 32,
              maxWidth: 145,
              alignment: Alignment.centerLeft,
            ),
            actions: [
              // Only show chat icon if enrolled in RCT
              if (isEnrolledInRCT) ...[
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );

                    if (result != null) {
                      _loadChatStatus();
                    }
                  },
                  icon: Icon(
                    hasActiveSession
                        ? Icons.chat_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: hasActiveSession
                        ? Colors.green.shade600
                        : Colors.grey.shade700,
                  ),
                  tooltip: languageService.getText('chat_with_mdosthi'),
                ),
              ],
              // Language toggle
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  onPressed: () async {
                    await languageService.toggleLanguage();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.language_rounded, size: 16),
                  label: Text(
                    languageService.isBengali ? 'English' : 'বাংলা',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.navy,
                    // ignore: deprecated_member_use
                    backgroundColor: BrandColors.navy.withOpacity(0.08),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _initializeStatus,
            color: BrandColors.navy,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final bool isDesktop = w >= 960;
                final bool isTablet = w >= 600 && w < 960;
                final bool isTiny = w < 360;
                final double maxBodyWidth =
                    isDesktop ? 1040 : (isTablet ? 760 : double.infinity);
                final int gridCols = w >= 840 ? 3 : (w < 340 ? 1 : 2);
                final double cardExtent = w >= 840 ? 156 : (isTiny ? 156 : 148);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxBodyWidth),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : (isTablet ? 16 : 0),
                        vertical: isDesktop ? 22 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome section
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: BrandColors.heroHeaderGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.navy.withOpacity(0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -30,
                                    top: -30,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -40,
                                    bottom: -40,
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.all(isTiny ? 18.0 : 24.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                languageService
                                                    .getText('welcome'),
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTiny ? 22 : 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                loginAccount.isNotEmpty
                                                    ? loginAccount
                                                    : "mDosthi Patient Dashboard",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  languageService.isBengali
                                                      ? "আপনার স্বাস্থ্য আমাদের অগ্রাধিকার"
                                                      : "Your health is our priority",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isTiny) ...[
                                          const SizedBox(width: 14),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: Image.asset(
                                              'assets/images/mdosthi-emblem.png',
                                              width: isDesktop ? 64 : 52,
                                              height: isDesktop ? 64 : 52,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Chat section - Only show if enrolled in RCT
                          if (isEnrolledInRCT) ...[
                            _buildChatButton(),
                            _buildChatHistoryButton(),
                            const SizedBox(height: 12),
                          ],

                          if (!isEnrolledInRCT && !isLoadingRCTStatus) ...[
                            const SizedBox(height: 12),
                          ],

                          // Loading indicator for RCT status
                          if (isLoadingRCTStatus) ...[
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: BrandColors.navy),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Quick Actions Grid Title
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 8.0),
                            child: Text(
                              languageService.isBengali
                                  ? "দ্রুত মেনু"
                                  : "Quick Actions",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),

                          // Responsive Grid of Actions
                          GridView(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: cardExtent,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            children: [
                              _buildGridActionCard(
                                icon: Icons.monitor_heart_rounded,
                                title: languageService.getText('Well-Being'),
                                color: BrandColors.tealDark,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WelbeingHomePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridActionCard(
                                icon: Icons.assignment_turned_in_rounded,
                                title: languageService.getText('takeTest'),
                                color: Colors.green.shade700,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FormListPage(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridActionCard(
                                icon: Icons.video_library_rounded,
                                title: languageService.getText('video'),
                                color: Colors.red.shade600,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridActionCard(
                                icon: Icons.picture_as_pdf_rounded,
                                title: languageService.getText('readables'),
                                color: Colors.amber.shade700,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReadableLibraryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridActionCard(
                                icon: Icons.privacy_tip_rounded,
                                title:
                                    languageService.getText('withdraw_consent'),
                                color: BrandColors.mutedInk,
                                onTap: _withdrawDpdpConsent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Only show floating action button if enrolled in RCT and has active session
          floatingActionButton: (isEnrolledInRCT && hasActiveSession)
              ? FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );

                    if (result != null) {
                      _loadChatStatus();
                    }
                  },
                  backgroundColor: BrandColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  tooltip: languageService.getText('chat_with_mdosthi'),
                  child: const Icon(Icons.chat_bubble_rounded),
                )
              : null,
        );
      },
    );
  }
}
