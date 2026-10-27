import 'package:flutter/material.dart';
import '../login_page.dart';

import 'package:app_001/backend/database_helper.dart';
import 'edit_survey_response.dart';
// import 'package:app_001/surveyor/change_username.dart';

//Import the font package
import 'package:google_fonts/google_fonts.dart';

class AdminPageUtil extends StatefulWidget {
  const AdminPageUtil({super.key});

  @override
  _AdminPageUtilState createState() => _AdminPageUtilState();
}

class _AdminPageUtilState extends State<AdminPageUtil> {
  
  static Future<void> clearLocalDatabase() async {
    final databaseHelper = DatabaseHelper.instance;
    await databaseHelper.clearAllTablesData();

    await databaseHelper.updateLastestDownloadUploadTime('download', '');
    await databaseHelper.updateLastestDownloadUploadTime('upload', '');
  }

  Future<void> displayLatestDBUpdateTime() async {
    final databaseHelper = DatabaseHelper.instance;
    final latestDownloadTime = await databaseHelper.getUpdateLastestDownloadUploadTime('download');
    final latestUploadTime = await databaseHelper.getUpdateLastestDownloadUploadTime('upload');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Latest DB Update Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Latest Download Time: $latestDownloadTime'),
              Text('Latest Upload Time: $latestUploadTime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      'Welcome to mDosthi !',
                      style: GoogleFonts.caveat(                      
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(211, 2, 4, 138),
                      //fontStyle: FontStyle.italic,
                      shadows: <Shadow>[
                        const Shadow(
                          offset: Offset(3.0, 3.0),
                          blurRadius: 8.0,
                          color: Color.fromARGB(118, 85, 30, 235),
                        ),
                        
                      ]
                    )
                    ),
                                        
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => CreateUsersPage(),
                //       ),
                //     );
                //   },
                //   icon: Icon(Icons.add, size: 30), // Add an icon
                //   label: Text('Create New Users'),
                // ),
                const SizedBox(height: 7), // Add spacing between buttons
                // ElevatedButton.icon(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => DisplayUsersPage(),
                //       ),
                //     );
                //   },
                //   icon: Icon(Icons.list, size: 30), // Add an icon
                //   label: Text('Display Users'),
                // ),
                ElevatedButton.icon(
                  onPressed: () {
                    displayLatestDBUpdateTime();
                  },
                  icon: const Icon(Icons.timelapse_sharp, size: 20), // Add an icon
                  label: const Text('Last DB update'),
                ),

                const SizedBox(height: 20), // Add spacing between buttons
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DisplaySurveyResponses(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list, size: 30), // Add an icon
                  label: const Text('Edit Responses'),
                ),

                const SizedBox(height: 20), // Add spacing between buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    await clearLocalDatabase();
                    LoginPage.usernames=[];
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Database cleared!!'), // Heading
                          content: const Text(
                              'Local data deleted successfully.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.delete, size: 30), // Add an icon
                  label: const Text('Clear Cache'),
                ),

              ],
            ),
          ),
          Positioned(
            top: 10, // Adjust top position as needed
            right: 10, // Adjust right position as needed
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.logout, size: 30), // Add a logout icon
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
