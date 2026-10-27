import 'package:flutter/material.dart';
import 'create_forms_page.dart';
import '../backend/database_helper.dart';


// import '../login_page.dart';

class FormsNameDetailsPage extends StatefulWidget {
  const FormsNameDetailsPage({super.key});

  @override
  State<FormsNameDetailsPage> createState() => _FormsNameDetailsPageState();
}

class _FormsNameDetailsPageState extends State<FormsNameDetailsPage> {
  final TextEditingController formNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void init() {
    super.initState();
    DatabaseHelper.instance.initDatabase();
  }

  Widget _buildSmallTextField(
      TextEditingController controller, String labelText) {
    return SizedBox(
      width: 200, // Set the desired width
      height: 50,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service Details'),
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Enter Form Details'),
                const SizedBox(
                  height: 10,
                ),
                _buildSmallTextField(formNameController, 'Form Name'),
                const SizedBox(
                  height: 10,
                ),
                _buildSmallTextField(descriptionController, 'Description'),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFormsPage(
                          formNameController.text,
                          descriptionController.text,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.create, size: 30), // Add a "create" icon
                  label: const Text('Create Service Form'),
                ),
              ],
            )),
          ),
          // Positioned(
          //   top: 10, // Adjust top position as needed
          //   right: 10, // Adjust right position as needed
          //   child: ElevatedButton.icon(
          //     onPressed: () {
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => LoginPage(),
          //         ),
          //       );
          //     },
          //     icon: Icon(Icons.logout, size: 30), // Add a logout icon
          //     label: Text('Logout'),
          //   ),
          // ),
        ],
      ),
    );
  }
}
