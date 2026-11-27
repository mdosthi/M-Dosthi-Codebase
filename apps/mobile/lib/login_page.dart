import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mdosthi_app/designExecutive/design_executive_util_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_page_util.dart';
import 'backend/database_helper.dart';
import 'dpdp_consent_dialog.dart';
import 'main.dart';
import 'service/language_service.dart';
import 'surveyor/survery_page_util.dart';
import 'theme/brand_theme.dart';

class LoginPage extends StatefulWidget {
  static String jwtToken = "";
  static String userId = "";
  static String username = "";
  static String userType = "";
  static String password = "";
  static String patid = "";
  static List<String> usernames = [];
  static String get protocol =>
      kIsWeb && Uri.base.scheme == 'https' ? 'https' : 'http';
  static const String _configuredApiHost = String.fromEnvironment('API_HOST');
  static String get domainName {
    return _configuredApiHost.isEmpty ? 'localhost:9090' : _configuredApiHost;
  }

  static bool get isClinician {
    final type = userType.trim().toLowerCase();
    return type == 'doc' || type == 'psy';
  }

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

  /// Save session details to SharedPreferences so the user stays logged in
  /// even after closing and reopening the app.
  static Future<void> saveSession({
    required String jwtToken,
    required String userId,
    required String username,
    required String password,
    required String patid,
    required String name,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_jwtToken', jwtToken);
    await prefs.setString('session_userId', userId);
    await prefs.setString('session_username', username);
    await prefs.setString('session_password', password);
    await prefs.setString('session_patid', patid);
    await prefs.setString('session_name', name);
    await prefs.setString('session_type', type);
  }

  /// Clear the saved session from SharedPreferences.
  /// Call this when the user explicitly taps Logout.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_jwtToken');
    await prefs.remove('session_userId');
    await prefs.remove('session_username');
    await prefs.remove('session_password');
    await prefs.remove('session_patid');
    await prefs.remove('session_name');
    await prefs.remove('session_type');
    LoginPage.jwtToken = "";
    LoginPage.userId = "";
    LoginPage.username = "";
    LoginPage.userType = "";
    LoginPage.password = "";
    LoginPage.patid = "";
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.closeDatabase();
      } catch (_) {}
    }
  }
}

class _RoleOption {
  final String id;
  final String labelEn;
  final String labelBn;
  final String hintEn;
  final String hintBn;
  final IconData icon;

  const _RoleOption({
    required this.id,
    required this.labelEn,
    required this.labelBn,
    required this.hintEn,
    required this.hintBn,
    required this.icon,
  });
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final LanguageService _languageService = LanguageService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isHoveringLoginBtn = false;
  bool _isHoveringEmblem = false;
  int _selectedRoleIndex = 0;
  String? _inlineError;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const List<_RoleOption> _roleOptions = [
    _RoleOption(
      id: 'pat',
      labelEn: 'Patient',
      labelBn: 'রোগী',
      hintEn: 'Enter your Patient ID or username',
      hintBn: 'আপনার রোগী আইডি বা ইউজারনেম লিখুন',
      icon: Icons.favorite_border_rounded,
    ),
    _RoleOption(
      id: 'psy',
      labelEn: 'Psychologist',
      labelBn: 'মনোবিদ',
      hintEn: 'Enter Psychologist username',
      hintBn: 'মনোবিদ ইউজারনেম লিখুন',
      icon: Icons.psychology_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();

    usernameController.addListener(_clearErrorOnEdit);
    passwordController.addListener(_clearErrorOnEdit);
  }

  void _clearErrorOnEdit() {
    if (_inlineError != null && mounted) {
      setState(() => _inlineError = null);
    }
  }

  @override
  void dispose() {
    usernameController.removeListener(_clearErrorOnEdit);
    passwordController.removeListener(_clearErrorOnEdit);
    usernameController.dispose();
    passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _inlineError = message);
  }

  void handleLogin() async {
    if (_isLoading) return;

    final bool isBn = _languageService.isBengali;
    final String username = usernameController.text.trim();
    final String password = passwordController.text;

    if (username.isEmpty && password.isEmpty) {
      _showError(isBn
          ? 'অনুগ্রহ করে আপনার ইউজারনেম এবং পাসওয়ার্ড লিখুন।'
          : 'Please enter both your username and password.');
      _usernameFocus.requestFocus();
      return;
    }
    if (username.isEmpty) {
      _showError(isBn
          ? 'অনুগ্রহ করে আপনার ইউজারনেম লিখুন।'
          : 'Please enter your username.');
      _usernameFocus.requestFocus();
      return;
    }
    if (password.isEmpty) {
      _showError(isBn
          ? 'অনুগ্রহ করে আপনার পাসওয়ার্ড লিখুন।'
          : 'Please enter your password.');
      _passwordFocus.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _inlineError = null;
    });

    final String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/login";
    final Map<String, dynamic> payload = {
      "username": username,
      "password": password,
    };
    final String jsonPayload = jsonEncode(payload);

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == "success") {
          setState(() {
            LoginPage.jwtToken = json["jwtToken"];
            LoginPage.userId = json["userid"];
            LoginPage.username = username;
            LoginPage.userType = (json["type"] ?? "").toString();
            LoginPage.password = password;
            LoginPage.patid = json["userid"];

            if (!LoginPage.usernames.contains(json['name'])) {
              LoginPage.usernames.add(json['name']);
            }
            loginAccount = "${json["name"]} (${json["userid"]})";
          });

          await LoginPage.saveSession(
            jwtToken: json["jwtToken"],
            userId: json["userid"],
            username: username,
            password: password,
            patid: json["userid"],
            name: json["name"] ?? "",
            type: json["type"] ?? "",
          );

          if (!kIsWeb) {
            try {
              final db = DatabaseHelper.instance;
              if (await db.checkLoginUser(username) == 0) {
                await db.saveLoginDetails(username, password, json["name"],
                    json["type"], json["userid"]);
              }
            } catch (_) {}
          }

          if (!mounted) return;

          void navigateToHome() {
            if (!mounted) return;
            final String normType =
                (json["type"] ?? "").toString().trim().toLowerCase();
            if (normType == "adm") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminPageUtil()),
              );
            } else if (normType == "dex") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DesignExecutiveUtilPage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const SurveyorPageUtil()),
              );
            }
          }

          final int dpdpAgreed = json["dpdpAgreed"] ?? 0;

          if (dpdpAgreed == 0) {
            setState(() => _isLoading = false);
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => DpdpConsentDialog(
                uid: json["userid"],
                onAgreed: navigateToHome,
              ),
            );
          } else {
            navigateToHome();
          }
        } else {
          setState(() => _isLoading = false);
          _showError(isBn
              ? 'ভুল ইউজারনেম বা পাসওয়ার্ড। অনুগ্রহ করে আবার চেষ্টা করুন।'
              : 'Invalid username or password. Please check your credentials and try again.');
        }
      } else {
        setState(() => _isLoading = false);
        _showError(isBn
            ? 'সার্ভার ত্রুটি (${response.statusCode})। অনুগ্রহ করে কিছুক্ষণ পর চেষ্টা করুন।'
            : 'Unable to reach the server (HTTP ${response.statusCode}). Please try again shortly.');
      }
    } catch (e) {
      if (!mounted) return;
      if (kIsWeb) {
        setState(() => _isLoading = false);
        _showError(isBn
            ? 'সার্ভারের সাথে সংযোগ করা যায়নি। অনুগ্রহ করে API সার্ভার (${LoginPage.domainName}) চালু আছে কিনা পরীক্ষা করুন।'
            : 'Could not connect to the mDosthi API (${LoginPage.domainName}). Please ensure the backend service is running.');
        return;
      }

      // Attempt offline login (only on non-web)
      try {
        LoginPage.userId = username;
        final db = DatabaseHelper.instance;
        if (await db.checkLoginDetails(username, password) == 1) {
          final results = await db.getLoginDetails(username, password);
          if (!mounted) return;
          if (results.isNotEmpty) {
            setState(() {
              LoginPage.jwtToken = "";
              LoginPage.userId = results[0]["userid"];
              LoginPage.username = username;
              LoginPage.userType = (results[0]["user_type"] ?? "").toString();
              LoginPage.password = password;
              loginAccount = "${results[0]["name"]} (${results[0]["userid"]})";
            });

            final String userType = results[0]["user_type"];
            if (userType == "adm") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminPageUtil()),
              );
            } else if (userType == "svy") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const SurveyorPageUtil()),
              );
            } else if (userType == "dex") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DesignExecutiveUtilPage()),
              );
            }
            return;
          }
        }
        setState(() => _isLoading = false);
        _showError(isBn
            ? 'লগইন ব্যর্থ হয়েছে। ইন্টারনেট সংযোগ ও তথ্য পরীক্ষা করুন।'
            : 'Sign in failed. Please check your connection and credentials.');
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(isBn
            ? 'লগইন ব্যর্থ হয়েছে। অনুগ্রহ করে পুনরায় চেষ্টা করুন।'
            : 'Sign in failed. Please try again.');
      }
    }
  }

  Future<void> util() async {
    final db = DatabaseHelper.instance;
    await db.updateImage('zone1_4');
  }

  Future<void> copyImageToApplicationDirectory() async {
    if (kIsWeb) return;
    final Directory appDir = await getApplicationDocumentsDirectory();
    const String assetsImagePath = 'assets/images/p4.jpg';
    final String destinationImagePath = '${appDir.path}/zone1_4.jpg';
    try {
      final ByteData imageBytes = await rootBundle.load(assetsImagePath);
      final List<int> byteList = imageBytes.buffer.asUint8List();
      File(destinationImagePath).writeAsBytes(byteList);
    } catch (_) {}
  }

  Future<void> copyAudioToApplicationDirectory() async {
    if (kIsWeb) return;
    final Directory appDir = await getApplicationDocumentsDirectory();
    const String assetsAudioPath = 'assets/images/p6.mp3';
    final String destinationAudioPath = '${appDir.path}/zone1_6.mp3';
    try {
      final ByteData audioBytes = await rootBundle.load(assetsAudioPath);
      final List<int> byteList = audioBytes.buffer.asUint8List();
      File(destinationAudioPath).writeAsBytes(byteList);
    } catch (_) {}
  }

  void _showHelpModal(bool isBn) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BrandColors.ice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: BrandColors.tealDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBn ? 'লগইন সহায়তা' : 'Sign-In Help',
                        style: BrandTypography.heading(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: BrandColors.mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HelpInfoTile(
                  icon: Icons.people_outline_rounded,
                  title: isBn
                      ? 'রোগী ও মনোবিদ লগইন'
                      : 'Patient & Psychologist Access',
                  body: isBn
                      ? 'আপনার নির্ধারিত ইউজারনেম এবং পাসওয়ার্ড দিয়ে সাইন ইন করুন। অ্যাকাউন্ট অনুযায়ী আপনার পোর্টাল স্বয়ংক্রিয়ভাবে খুলে যাবে।'
                      : 'Sign in with your assigned username and password. Your Patient or Psychologist view opens automatically.',
                ),
                const SizedBox(height: 10),
                _HelpInfoTile(
                  icon: Icons.verified_user_outlined,
                  title: isBn ? 'গোপনীয়তা ও সম্মতি' : 'Privacy & Consent',
                  body: isBn
                      ? 'প্রথমবার লগইন করার সময় তথ্য সুরক্ষার জন্য সম্মতি প্রদান করতে হবে।'
                      : 'First-time users review a brief consent prompt before continuing.',
                ),
                const SizedBox(height: 10),
                const _HelpContactTile(),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.teal,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 11),
                    ),
                    child: Text(isBn ? 'ঠিক আছে' : 'Got it'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageService,
      builder: (context, _) {
        final bool isBn = _languageService.isBengali;
        return Scaffold(
          body: Stack(
            children: [
              // Soft Brand Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: BrandColors.softPageGradient,
                  ),
                ),
              ),
              Positioned(
                top: -110,
                left: -90,
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          BrandColors.teal.withValues(alpha: 0.14),
                          BrandColors.teal.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -130,
                right: -90,
                child: IgnorePointer(
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          BrandColors.blue.withValues(alpha: 0.11),
                          BrandColors.blue.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    final double h = constraints.maxHeight;
                    final bool isDesktop = w >= 992;
                    final bool isTablet = w >= 600 && w < 992;
                    final bool isSmallPhone = w < 380;
                    final bool isShortDesktop = isDesktop && h < 760;

                    final double horizontalGutter = isDesktop
                        ? (w >= 1400 ? 32 : 24)
                        : (isTablet ? 20 : (isSmallPhone ? 10 : 14));
                    final double verticalGutter = isDesktop
                        ? (isShortDesktop ? 14 : 26)
                        : (isTablet ? 22 : 16);
                    final double maxContentWidth = isDesktop
                        ? (w >= 1400 ? 1280 : 1200)
                        : (isTablet ? 640 : double.infinity);

                    return Column(
                      children: [
                        _buildTopUtilityBar(
                          isBn: isBn,
                          viewportWidth: w,
                          maxContentWidth: maxContentWidth,
                          horizontalGutter: horizontalGutter,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                          isSmallPhone: isSmallPhone,
                        ),
                        Expanded(
                          child: Align(
                            alignment: isDesktop
                                ? Alignment.center
                                : Alignment.topCenter,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalGutter,
                                vertical: verticalGutter,
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: maxContentWidth),
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: SlideTransition(
                                    position: _slideAnim,
                                    child: isDesktop
                                        ? _buildDesktopSplitLayout(
                                            isBn,
                                            wideGap: w >= 1280
                                                ? 52
                                                : (w >= 1120 ? 38 : 28),
                                            isShortDesktop: isShortDesktop,
                                          )
                                        : _buildCompactStackedLayout(
                                            isBn,
                                            isTablet: isTablet,
                                            isSmallPhone: isSmallPhone,
                                            stretchPartners: w < 600,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopUtilityBar({
    required bool isBn,
    required double viewportWidth,
    required double maxContentWidth,
    required double horizontalGutter,
    required bool isDesktop,
    required bool isTablet,
    required bool isSmallPhone,
  }) {
    final double barMinHeight =
        isDesktop ? 74 : (isTablet ? 66 : kToolbarHeight);
    final double logoHeight = isDesktop
        ? 44
        : (isTablet ? 38 : (viewportWidth < 360 ? 28 : 32));
    final double logoMaxWidth = isDesktop
        ? 176
        : (isTablet ? 152 : (viewportWidth < 360 ? 102 : (isSmallPhone ? 114 : 132)));

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: barMinHeight),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(
            color: BrandColors.navy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: BrandColors.ctaGradient,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
                minHeight: barMinHeight - 3,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalGutter,
                  vertical: isDesktop ? 10 : 8,
                ),
                child: Row(
                  children: [
                    Flexible(
                      flex: 0,
                      child: MdosthiHorizontalLogo(
                        height: logoHeight,
                        maxWidth: logoMaxWidth,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 14),
                      Container(
                        height: 22,
                        width: 1.2,
                        color: BrandColors.navy.withValues(alpha: 0.14),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: BrandColors.ice,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: BrandColors.teal.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded,
                                size: 14, color: BrandColors.tealDark),
                            const SizedBox(width: 6),
                            Text(
                              isBn
                                  ? 'রোগী ও মনোবিদ পোর্টাল'
                                  : 'Patient & Psychologist Portal',
                              style: BrandTypography.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    _buildLanguageToggle(isBn, compact: isSmallPhone),
                    SizedBox(width: isSmallPhone ? 6 : 8),
                    Tooltip(
                      message: isBn ? 'সহায়তা' : 'Sign-in help',
                      child: InkWell(
                        onTap: () => _showHelpModal(isBn),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                isDesktop ? 14 : (isSmallPhone ? 8 : 11),
                            vertical: isSmallPhone ? 7 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: BrandColors.navy.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.help_outline_rounded,
                                  size: 17, color: BrandColors.navy),
                              if (isDesktop || isTablet) ...[
                                const SizedBox(width: 6),
                                Text(
                                  isBn ? 'সহায়তা' : 'Help',
                                  style: BrandTypography.body(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: BrandColors.navy,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(bool isBn, {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrandColors.pageBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BrandColors.teal.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangPill(
            label: 'EN',
            selected: !isBn,
            compact: compact,
            onTap: () {
              if (isBn) _languageService.toggleLanguage();
            },
          ),
          _LangPill(
            label: 'বাংলা',
            selected: isBn,
            compact: compact,
            onTap: () {
              if (!isBn) _languageService.toggleLanguage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSplitLayout(
    bool isBn, {
    required double wideGap,
    required bool isShortDesktop,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildBrandOverview(
            isBn,
            isCompact: false,
            isTablet: false,
            isShortDesktop: isShortDesktop,
            stretchPartners: false,
          ),
        ),
        SizedBox(width: wideGap),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _buildSignInCard(
            isBn,
            isDesktop: true,
            isTablet: false,
            isSmallPhone: false,
            isShortDesktop: isShortDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStackedLayout(
    bool isBn, {
    required bool isTablet,
    required bool isSmallPhone,
    required bool stretchPartners,
  }) {
    return Column(
      children: [
        _buildSignInCard(
          isBn,
          isDesktop: false,
          isTablet: isTablet,
          isSmallPhone: isSmallPhone,
          isShortDesktop: false,
        ),
        SizedBox(height: isTablet ? 28 : 22),
        _buildBrandOverview(
          isBn,
          isCompact: true,
          isTablet: isTablet,
          isShortDesktop: false,
          stretchPartners: stretchPartners,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBrandOverview(
    bool isBn, {
    required bool isCompact,
    required bool isTablet,
    required bool isShortDesktop,
    required bool stretchPartners,
  }) {
    final chips = isBn
        ? const [
            (Icons.translate_rounded, 'বাংলা ও ইংরেজি', BrandColors.teal),
            (Icons.mic_none_rounded, 'চ্যাট ও ভয়েস', BrandColors.cyanTeal),
            (Icons.favorite_border_rounded, 'সহমর্মী যত্ন', BrandColors.blue),
          ]
        : const [
            (Icons.translate_rounded, 'English & বাংলা', BrandColors.teal),
            (Icons.mic_none_rounded, 'Chat & Voice', BrandColors.cyanTeal),
            (Icons.favorite_border_rounded, 'Supportive Care', BrandColors.blue),
          ];

    const partnerItems = [
      (
        'assets/images/iitkgp.png',
        'Developed By',
        'IIT Kharagpur',
      ),
      (
        'assets/images/All_India_Institute_of_Medical_Sciences,_Kalyani.png',
        'Collaborated With',
        'AIIMS Kalyani',
      ),
      (
        'assets/images/icmr.png',
        'Sponsored By',
        'ICMR',
      ),
    ];

    final double titleSize = isCompact
        ? (isTablet ? 21 : 18)
        : (isShortDesktop ? 21 : 24);

    return Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        MdosthiPrimaryLogo(
          maxWidth: isCompact
              ? (isTablet ? 280 : 240)
              : (isShortDesktop ? 310 : 365),
          alignment: isCompact ? Alignment.center : Alignment.centerLeft,
        ),
        SizedBox(height: isCompact ? 14 : (isShortDesktop ? 12 : 20)),
        Text(
          isBn
              ? 'ম্যালিগন্যান্সি-সম্পর্কিত মানসিক কষ্ট ও চাপ উপশমের উদ্যোগ'
              : 'Malignancy related Distress and Other Stress Healing Initiative',
          textAlign: isCompact ? TextAlign.center : TextAlign.left,
          style: BrandTypography.heading(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: BrandColors.navy,
            height: 1.24,
          ),
        ),
        SizedBox(height: isShortDesktop ? 6 : 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            isBn
                ? 'নিয়মিত চিকিৎসার পাশাপাশি রোগী ও মনোবিদদের যুক্ত রাখার একটি শান্ত, নিরাপদ ও দ্বিভাষিক পরিসর।'
                : 'A calm space in English and Bengali connecting patients and psychologists alongside routine hospital care.',
            textAlign: isCompact ? TextAlign.center : TextAlign.left,
            style: BrandTypography.subtitle(
              fontSize: isCompact ? (isTablet ? 14.5 : 13.5) : 15.5,
              fontStyle: FontStyle.italic,
              color: BrandColors.bodyInk,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: isShortDesktop ? 14 : 20),
        Wrap(
          alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map(
                (c) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact && !isTablet ? 11 : 13,
                    vertical: isCompact && !isTablet ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: c.$3.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.navy.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.$1, size: 15, color: c.$3),
                      const SizedBox(width: 6),
                      Text(
                        c.$2,
                        style: BrandTypography.body(
                          fontSize: isCompact && !isTablet ? 12 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: isShortDesktop ? 16 : 22),
        if (stretchPartners)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                for (int i = 0; i < partnerItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _PartnerBadge(
                    assetPath: partnerItems[i].$1,
                    roleLabel: partnerItems[i].$2,
                    label: partnerItems[i].$3,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Row(
              children: [
                for (int i = 0; i < partnerItems.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _PartnerBadge(
                      assetPath: partnerItems[i].$1,
                      roleLabel: partnerItems[i].$2,
                      label: partnerItems[i].$3,
                      fullWidth: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSignInCard(
    bool isBn, {
    required bool isDesktop,
    required bool isTablet,
    required bool isSmallPhone,
    required bool isShortDesktop,
  }) {
    final role = _roleOptions[_selectedRoleIndex];
    final double cardRadius = isDesktop ? 22 : 20;
    final double cardMaxWidth =
        isDesktop ? 438 : (isTablet ? 460 : double.infinity);
    final double cardHorizPad =
        isDesktop ? 26 : (isTablet ? 24 : (isSmallPhone ? 14 : 18));
    final double cardVertPad = isDesktop
        ? (isShortDesktop ? 18 : 24)
        : (isTablet ? 22 : (isSmallPhone ? 16 : 20));
    final double emblemSize =
        isDesktop ? (isShortDesktop ? 50 : 58) : (isSmallPhone ? 46 : 52);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: cardMaxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: BrandColors.navy.withValues(alpha: 0.10),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.navy.withValues(alpha: 0.14),
            blurRadius: isDesktop ? 44 : 26,
            offset: Offset(0, isDesktop ? 18 : 10),
          ),
          BoxShadow(
            color: BrandColors.teal.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius - 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signature Branded Gradient Header Banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: BrandColors.heroHeaderGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -34,
                    right: -26,
                    child: IgnorePointer(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColors.green.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -42,
                    left: 64,
                    child: IgnorePointer(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardHorizPad,
                      vertical: isShortDesktop ? 16 : (isDesktop ? 22 : 18),
                    ),
                    child: Row(
                      children: [
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isHoveringEmblem = true),
                          onExit: (_) =>
                              setState(() => _isHoveringEmblem = false),
                          child: AnimatedScale(
                            scale: _isHoveringEmblem ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: emblemSize,
                              height: emblemSize,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: BrandColors.ice.withValues(alpha: 0.85),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: BrandColors.navyDark
                                        .withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/mdosthi-emblem.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.volunteer_activism_rounded,
                                  size: 28,
                                  color: BrandColors.teal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isBn ? 'MDOSTHI পোর্টাল' : 'MDOSTHI CARE',
                                style: BrandTypography.body(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFA7F3D0),
                                ).copyWith(letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBn ? 'স্বাগতম' : 'Welcome Back',
                                style: BrandTypography.heading(
                                  fontSize: isDesktop ? 21 : 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBn
                                    ? 'রোগী ও মনোবিদদের জন্য সাইন ইন'
                                    : 'For Patients & Psychologists',
                                style: BrandTypography.body(
                                  fontSize: 12.5,
                                  color: BrandColors.ice.withValues(alpha: 0.90),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: cardHorizPad,
                vertical: cardVertPad,
              ),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // High-Contrast 2-Role Selector: Patient | Psychologist
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: BrandColors.navy.withValues(alpha: 0.09),
                        ),
                      ),
                      child: Row(
                        children: List.generate(_roleOptions.length, (index) {
                          final opt = _roleOptions[index];
                          final bool active = index == _selectedRoleIndex;
                          return Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedRoleIndex = index);
                                  _usernameFocus.requestFocus();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? BrandColors.activeTabGradient
                                        : null,
                                    color: active ? null : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: BrandColors.teal
                                                  .withValues(alpha: 0.26),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        opt.icon,
                                        size: 16,
                                        color: active
                                            ? const Color(0xFFC7F9CC)
                                            : const Color(0xFF3E6351),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isBn ? opt.labelBn : opt.labelEn,
                                          overflow: TextOverflow.ellipsis,
                                          style: BrandTypography.heading(
                                            fontSize: 12.5,
                                            fontWeight: active
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: active
                                                ? Colors.white
                                                : const Color(0xFF3E6351),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Inline Error Alert Banner
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _inlineError == null
                          ? const SizedBox.shrink()
                          : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _inlineError!,
                                      style: BrandTypography.body(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF991B1B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        setState(() => _inlineError = null),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Username Label + Field
                    Text(
                      isBn ? 'ইউজারনেম' : 'USERNAME',
                      style: BrandTypography.body(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A5C4A),
                      ).copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: usernameController,
                      builder: (context, value, _) {
                        return TextField(
                          controller: usernameController,
                          focusNode: _usernameFocus,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          style: BrandTypography.body(
                            fontSize: 14.5,
                            color: BrandColors.navy,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: isBn ? role.hintBn : role.hintEn,
                            hintStyle: BrandTypography.body(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: BrandColors.tealDark,
                                  size: 19,
                                ),
                              ),
                            ),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    tooltip: isBn ? 'মুছুন' : 'Clear',
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: BrandColors.mutedInk,
                                    ),
                                    onPressed: () {
                                      usernameController.clear();
                                      _usernameFocus.requestFocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8FDFB),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    BrandColors.navy.withValues(alpha: 0.14),
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BrandColors.teal,
                                width: 1.8,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Password Label + Field
                    Text(
                      isBn ? 'পাসওয়ার্ড' : 'PASSWORD',
                      style: BrandTypography.body(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A5C4A),
                      ).copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      focusNode: _passwordFocus,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => handleLogin(),
                      style: BrandTypography.body(
                        fontSize: 14.5,
                        color: BrandColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: isBn
                            ? 'আপনার পাসওয়ার্ড লিখুন'
                            : 'Enter your password',
                        hintStyle: BrandTypography.body(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: BrandColors.cyanBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: BrandColors.cyanTeal,
                              size: 19,
                            ),
                          ),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            tooltip: _obscurePassword
                                ? (isBn ? 'পাসওয়ার্ড দেখুন' : 'Show password')
                                : (isBn
                                    ? 'পাসওয়ার্ড লুকান'
                                    : 'Hide password'),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: BrandColors.mutedInk,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FDFB),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: BrandColors.navy.withValues(alpha: 0.14),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: BrandColors.teal,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Matched 14px Rounded Gradient CTA Button
                    MouseRegion(
                      cursor: _isLoading
                          ? SystemMouseCursors.wait
                          : SystemMouseCursors.click,
                      onEnter: (_) =>
                          setState(() => _isHoveringLoginBtn = true),
                      onExit: (_) =>
                          setState(() => _isHoveringLoginBtn = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 50,
                        transform: Matrix4.translationValues(
                          0,
                          (_isHoveringLoginBtn && !_isLoading) ? -1.5 : 0,
                          0,
                        ),
                        decoration: BoxDecoration(
                          gradient: BrandColors.ctaGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.teal.withValues(
                                alpha: _isHoveringLoginBtn ? 0.32 : 0.22,
                              ),
                              blurRadius: _isHoveringLoginBtn ? 22 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isBn ? 'সাইন ইন হচ্ছে...' : 'Signing in...',
                                      style: BrandTypography.heading(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isBn ? 'লগইন করুন' : 'Sign In',
                                      style: BrandTypography.heading(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Clean Hairline Security Footer
                    Container(
                      padding: const EdgeInsets.only(top: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: BrandColors.navy.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: BrandColors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.green.withValues(alpha: 0.28),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: BrandColors.cyanTeal,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isBn ? 'গোপনীয় ও সুরক্ষিত' : 'Private & Secure',
                              style: BrandTypography.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: BrandColors.mutedInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _LangPill({
    required this.label,
    required this.selected,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            gradient: selected ? BrandColors.ctaGradient : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: BrandTypography.heading(
              fontSize: compact ? 11.5 : 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : BrandColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerBadge extends StatelessWidget {
  final String assetPath;
  final String roleLabel;
  final String label;
  final bool fullWidth;

  const _PartnerBadge({
    required this.assetPath,
    required this.roleLabel,
    required this.label,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.teal.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.navy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: BrandColors.navy.withValues(alpha: 0.07),
              ),
            ),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_rounded,
                size: 17,
                color: BrandColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roleLabel.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: BrandTypography.body(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.tealDark,
                  ).copyWith(letterSpacing: 0.4),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTypography.heading(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HelpInfoTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.teal.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: BrandColors.tealDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BrandTypography.heading(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: BrandTypography.body(
                    fontSize: 12.5,
                    color: BrandColors.bodyInk,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpContactTile extends StatelessWidget {
  const _HelpContactTile();

  @override
  Widget build(BuildContext context) {
    final baseStyle = BrandTypography.body(
      fontSize: 12.5,
      color: BrandColors.bodyInk,
      height: 1.45,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.teal.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.contact_mail_outlined,
            size: 19,
            color: BrandColors.tealDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developed and designed at Computer Science & Engineering Department, IIT Kharagpur',
                  style: BrandTypography.heading(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.navy,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText.rich(
                  TextSpan(
                    style: baseStyle,
                    children: [
                      TextSpan(
                        text: 'Contact: ',
                        style: baseStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BrandColors.navy,
                        ),
                      ),
                      const TextSpan(text: 'Prof. Jayanta Mukhopadhyay, '),
                      TextSpan(
                        text: 'jay@cse.iitkgp.ac.in',
                        style: baseStyle.copyWith(
                          color: BrandColors.blue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: BrandColors.blue,
                        ),
                      ),
                      const TextSpan(text: ', Phone: +91-3222-283484'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
