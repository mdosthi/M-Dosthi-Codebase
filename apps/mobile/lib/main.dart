// import 'package:mdosthi_app/surveyor/form_selection_survey.dart';
// import 'package:mdosthi_app/surveyor/subject_selection_survey.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'theme/brand_theme.dart';
import 'backend/database_helper.dart';
import 'surveyor/survery_page_util.dart';
import 'admin/admin_page_util.dart';
import 'package:mdosthi_app/designExecutive/design_executive_util_page.dart';
import 'service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import './log/logger.dart';

String loginAccount = "";

//To show upload count
int uploadBeneficiaryDetailsCount = 0;
int uploadServiceEnrollmentCount = 0;
int uploadResponsesUtilCount = 0;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  log.info('Started the APP');

  final dbHelper = DatabaseHelper.instance;
  //dbHelper.deleteDatabaseUtil();
  // dbHelper.initDatabase();
  // print("In main dbhelper initdatabase");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTimeTracker(
      child: MaterialApp(
        title: 'mDosthi',
        theme: BrandTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppTimeTracker extends StatefulWidget {
  final Widget child;
  const AppTimeTracker({super.key, required this.child});

  @override
  State<AppTimeTracker> createState() => _AppTimeTrackerState();
}

class _AppTimeTrackerState extends State<AppTimeTracker> {
  DateTime? _appResumedTime;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _appResumedTime = DateTime.now();
    // Sync time to server every 15 seconds while app is open
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_appResumedTime != null && LoginPage.userId.isNotEmpty) {
        final timeSpent = DateTime.now().difference(_appResumedTime!).inSeconds;
        if (timeSpent > 0) {
          _logTimeSpent(timeSpent);
          // reset so we only send the delta next time
          _appResumedTime = DateTime.now();
        }
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _logTimeSpent(int timeSpentSeconds) async {
    final logUrl =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/log-time";
    try {
      await http.post(
        Uri.parse(logUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'userid': LoginPage.userId,
          'timespent': timeSpentSeconds,
        }),
      );
      print("AppTimeTracker: Logged $timeSpentSeconds seconds");
    } catch (e) {
      print("AppTimeTracker: Error logging time: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// SplashScreen checks SharedPreferences for a saved session.
///
/// If a saved session is found:
///   1. The JWT token is decoded locally to check if it has expired.
///   2. If expired → silent re-login is attempted using saved credentials.
///   3. If re-login succeeds → new token saved, user goes to home page.
///   4. If re-login fails → session cleared, user goes to LoginPage.
///
/// If no saved session is found → user goes to LoginPage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    late final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      print("SplashScreen: Could not load saved session: $error");
      _goToLogin();
      return;
    }

    final String? savedToken = prefs.getString('session_jwtToken');
    final String? savedUserId = prefs.getString('session_userId');
    final String? savedUsername = prefs.getString('session_username');
    final String? savedPassword = prefs.getString('session_password');
    final String? savedPatid = prefs.getString('session_patid');
    final String? savedName = prefs.getString('session_name');
    final String? savedType = prefs.getString('session_type');

    // No saved session — go to login
    if (savedToken == null ||
        savedToken.isEmpty ||
        savedUserId == null ||
        savedUserId.isEmpty ||
        savedType == null ||
        savedType.isEmpty) {
      print("SplashScreen: No saved session found");
      _goToLogin();
      return;
    }

    // Restore static fields from saved session
    LoginPage.jwtToken = savedToken;
    LoginPage.userId = savedUserId;
    LoginPage.username = savedUsername ?? "";
    LoginPage.userType = savedType;
    LoginPage.password = savedPassword ?? "";
    LoginPage.patid = savedPatid ?? savedUserId;
    loginAccount = "${savedName ?? savedUsername} ($savedUserId)";

    print(
        "SplashScreen: Saved session found for $savedUserId — validating token");

    // Validate token. If expired, AuthService silently re-logs in and saves
    // a fresh token before we navigate. This is what fixes the "token has
    // expired" blank-screen bug.
    final bool sessionValid = await AuthService.validateAndRefreshToken();

    if (!sessionValid) {
      print("SplashScreen: Token validation failed — going to login");
      await LoginPage.clearSession();
      _goToLogin();
      return;
    }

    print(
        "SplashScreen: Session valid — navigating to home for type $savedType");

    if (!mounted) return;
    _navigateToHome(savedType);
  }

  void _navigateToHome(String userType) {
    if (userType == "adm") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminPageUtil()),
      );
    } else if (userType == "svy" ||
        userType == "doc" ||
        userType == "psy" ||
        userType == "pat" ||
        userType == "PAT") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SurveyorPageUtil()),
      );
    } else if (userType == "dex") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const DesignExecutiveUtilPage()),
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Brief splash UI shown while checking / refreshing session
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: BrandColors.softPageGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                MdosthiPrimaryLogo(maxWidth: 300),
                SizedBox(height: 28),
                CircularProgressIndicator(color: BrandColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
reset password
gender drop down
Age from 1 to 150
mobile - only number 10 digits
template source - button to display
 */
