import 'package:mdosthi_app/designExecutive/display_fields_page.dart';
import 'package:mdosthi_app/designExecutive/display_forms_page.dart';
import 'package:mdosthi_app/designExecutive/forms_name_details_page.dart';
import 'package:mdosthi_app/designExecutive/upload_data_page.dart';
import 'package:flutter/material.dart';
import '../login_page.dart';

class DesignExecutiveUtilPage extends StatefulWidget {
  const DesignExecutiveUtilPage({super.key});

  @override
  _DesignExecutiveUtilPageState createState() =>
      _DesignExecutiveUtilPageState();
}

class _DesignExecutiveUtilPageState extends State<DesignExecutiveUtilPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Executive Page'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DisplayFormsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder, size: 30),
                      label: const Text('Display Forms'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DisplayFieldsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.format_list_bulleted, size: 30),
                      label: const Text('Display Fields'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FormsNameDetailsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.create, size: 30),
                      label: const Text('Create Form'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DesignDataUploadPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.create, size: 30),
                      label: const Text('Upload Data'),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
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
