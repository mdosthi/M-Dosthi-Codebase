import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mdosthi_app/designExecutive/design_executive_util_page.dart';
//import 'profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend/database_helper.dart';
import 'surveyor/survery_page_util.dart';
import 'dpdp_consent_dialog.dart';
import 'admin/admin_page_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

//Import the font package
import 'package:google_fonts/google_fonts.dart';
// import 'package:footer/footer.dart';
// import 'package:footer/footer_view.dart';

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
  //static String domainName = "matrikaruna.in";
  //static String domainName="10.5.29.236:9090";
  //static String domainName = "10.5.29.226:9090";
  static const String _configuredApiHost = String.fromEnvironment('API_HOST');
  static String get domainName {
    return _configuredApiHost.isEmpty ? 'localhost:9090' : _configuredApiHost;
  }

  static bool get isClinician {
    final type = userType.trim().toLowerCase();
    return type == 'doc' || type == 'psy';
  }
  //static String domainName = "csjitsi.iitkgp.ac.in";

  const LoginPage({super.key});
  //static String domainName = "csjitsi.iitkgp.ac.in";
  //static String domainName = "10.5.29.229:9090";
  //static String domainName = "10.5.29.10:9090";
  //static String IP_Address = "10.5.29.10:9090";
  //static String Port = "8080";
  @override
  _LoginPageState createState() => _LoginPageState();

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
    print("LoginPage.saveSession: Session saved for user $userId");
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
    // Also clear in-memory static fields
    LoginPage.jwtToken = "";
    LoginPage.userId = "";
    LoginPage.username = "";
    LoginPage.userType = "";
    LoginPage.password = "";
    LoginPage.patid = "";
    // Close the database to release file locks and clean cache
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.closeDatabase();
      } catch (e) {
        print("LoginPage.clearSession: Error closing database: $e");
      }
    }
    print("LoginPage.clearSession: Session cleared and database closed");
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  // String? userType;
  // List<String> logs = []; // List to store logs

  @override
  void initState() {
    super.initState();
    // NOTE: We intentionally do NOT clear LoginPage static fields here anymore.
    // Clearing them was what caused the logout-on-app-close bug.
    // Session state is now managed via SharedPreferences (see LoginPage.saveSession
    // and LoginPage.clearSession). The SplashScreen in main.dart handles
    // restoring the session on app start.
    // util();
    // copyImageToApplicationDirectory();
    // copyAudioToApplicationDirectory();
  }

// login_page.dart - handleLogin method

  void handleLogin() async {
    String username = usernameController.text;
    String password = passwordController.text;

    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/login";
    Map<String, dynamic> payload = {"username": username, "password": password};
    String jsonPayload = jsonEncode(payload);

    try {
      var response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        if (json["status"] == "success") {
          // Store ALL relevant user information in static fields
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

          // Persist session to SharedPreferences so it survives app restarts
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
            } catch (dbError) {
              print(
                  "LoginPage.handleLogin: Database error storing credentials: $dbError");
            }
          }

          // Navigate based on user type
          void navigateToHome() {
            if (json["type"] == "adm") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminPageUtil()),
              );
            } else if (json["type"] == "svy" ||
                json["type"] == "doc" ||
                json["type"] == "psy" ||
                json["type"] == "pat" ||
                json["type"] == "PAT") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const SurveyorPageUtil()),
              );
            } else if (json["type"] == "dex") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DesignExecutiveUtilPage()),
              );
            }
          }

          // Check DPDP consent — 0 or null means not yet agreed
          final int dpdpAgreed = json["dpdpAgreed"] ?? 0;

          if (dpdpAgreed == 0) {
            // First time — show mandatory dialog, navigation happens inside onAgreed
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => DpdpConsentDialog(
                uid: json["userid"],
                onAgreed: navigateToHome,
              ),
            );
          } else {
            // Already agreed — go straight to home
            navigateToHome();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error')),
        );
      }
    } catch (e) {
      print("Login error: $e");
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
        return;
      }
      // Attempt offline login (only on non-web)
      try {
        LoginPage.userId = username;
        final db = DatabaseHelper.instance;
        if (await db.checkLoginDetails(username, password) == 1) {
          final results = await db.getLoginDetails(username, password);
          if (results.isNotEmpty) {
            setState(() {
              LoginPage.jwtToken = "";
              LoginPage.userId = results[0]["userid"];
              LoginPage.username = username;
              LoginPage.userType = (results[0]["user_type"] ?? "").toString();
              LoginPage.password = password;
              loginAccount = "${results[0]["name"]} (${results[0]["userid"]})";
            });

            // Navigate based on stored user type
            String userType = results[0]["user_type"];
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
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      } catch (dbError) {
        print("LoginPage.handleLogin: Offline login database error: $dbError");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  Future<void> util() async {
    final db = DatabaseHelper.instance;
    await db.updateImage('zone1_4');
  }

  Future<void> copyImageToApplicationDirectory() async {
    if (kIsWeb) return;
    // Get the directory for storing application files
    Directory appDir = await getApplicationDocumentsDirectory();

    // Define the source and destination paths
    String assetsImagePath = 'assets/images/p4.jpg';
    String destinationImagePath = '${appDir.path}/zone1_4.jpg';
    // print(destinationImagePath);
    try {
      // Load the image byte data from assets
      ByteData imageBytes = await rootBundle.load(assetsImagePath);
      List<int> byteList = imageBytes.buffer.asUint8List();

      // Write the image byte data to a file in the application directory
      File(destinationImagePath).writeAsBytes(byteList);

      // /data/user/0/com.example.mdosthi_app/app_flutter/null
      print('Image copied successfully to application directory.');
    } catch (e) {
      print('Error copying image: $e');
    }
  }

  Future<void> copyAudioToApplicationDirectory() async {
    if (kIsWeb) return;
    // Get the directory for storing application files
    Directory appDir = await getApplicationDocumentsDirectory();

    // Define the source and destination paths
    String assetsAudioPath = 'assets/images/p6.mp3';
    String destinationAudioPath = '${appDir.path}/zone1_6.mp3';
    // print(destinationAudioPath);
    try {
      // Load the image byte data from assets
      ByteData audioBytes = await rootBundle.load(assetsAudioPath);
      List<int> byteList = audioBytes.buffer.asUint8List();

      // Write the image byte data to a file in the application directory
      File(destinationAudioPath).writeAsBytes(byteList);

      // /data/user/0/com.example.mdosthi_app/app_flutter/null
      print('Audio copied successfully to application directory.');
    } catch (e) {
      print('Error copying image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // very light green
              Color(0xFFFFFFFF), // white
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - 120, // leave space for footer
            ),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // AIIMS Kalyani Logo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/All_India_Institute_of_Medical_Sciences,_Kalyani.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Card Container
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.06),
                              blurRadius: 32,
                              spreadRadius: 2,
                              offset: const Offset(0, 16),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF1B5E20).withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28.0, vertical: 36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'mDosthi',
                                style: GoogleFonts.outfit(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B5E20),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1B5E20)
                                        .withOpacity(0.12),
                                    width: 2,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 46,
                                  backgroundImage:
                                      AssetImage('assets/images/eDosthi.png'),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Username Field
                              TextField(
                                controller: usernameController,
                                style: GoogleFonts.outfit(
                                    fontSize: 16, color: Colors.grey.shade900),
                                decoration: InputDecoration(
                                  labelText: 'ইউজারনেম / Username',
                                  labelStyle: GoogleFonts.outfit(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'Enter your username',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFF1B5E20),
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1B5E20), width: 2.0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.outfit(
                                    fontSize: 16, color: Colors.grey.shade900),
                                decoration: InputDecoration(
                                  labelText: 'পাসওয়ার্ড / Password',
                                  labelStyle: GoogleFonts.outfit(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'Enter your password',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF1B5E20),
                                    size: 22,
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade500,
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
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1B5E20), width: 2.0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    shadowColor: const Color(0xFF1B5E20)
                                        .withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'লগইন করুন / Login',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Developed and designed at",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                "Computer Science & Engineering Department, IIT Kharagpur",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: const Color(0xFF1B5E20), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "Prof. Jayanta Mukhopadhyay",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.phone_outlined,
                      color: const Color(0xFF1B5E20), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "+91-3222-283484",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      color: const Color(0xFF1B5E20), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "jay@cse.iitkgp.ac.in",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ],
      // footer: new Footer(
      // child: Padding(
      // padding: new EdgeInsets.all(10.0),
      // child: Text('Developed and designed at Computer Science & Engineering Department, IIT Kharagpur Contact: Prof. Jayanta Mukhopadhyay, jay@cse.iitkgp.ac.in, Phone: +91-3222-283484',style: TextStyle(color: Colors.black)),
      // ),
      // ),
      // flex: 1),
    );
  }

  // // Function to append log message to logs list
  // void logMessage(String message) {
  //   setState(() {
  //     logs.add(message);
  //   });
  // }
}
