//Author: Soumyajit Das, Koustav Ghosh
//Date: 20/07/2024

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_001/Audio/audio_player.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../backend/database_helper.dart';
import 'package:path/path.dart' as path;
import 'package:app_001/admin/edit_survey_data_page.dart';

import 'package:app_001/admin/admin_page_util.dart';

class DisplaySurveyResponses extends StatefulWidget {
  const DisplaySurveyResponses({super.key});

  @override
  State<DisplaySurveyResponses> createState() => _DisplaySurveyResponsesState();
}

class _DisplaySurveyResponsesState extends State<DisplaySurveyResponses> {
  List<Map<String, dynamic>> responsesList = [];
  List<Map<String, dynamic>> filteredResponsesList = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  void _loadResponses() async {
    final res = await DatabaseHelper.instance.getResponses();
    // print("res!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    for (var row in res) {
      print("rowwwwwwwwwwwwwwwwwwwwwwwwwwwwww :");
      // print("Doneeeeeeeeeeeeeeeeeeeee");
      print(row);
    }

    
    setState(() {
      responsesList = res;
      filteredResponsesList = res;
    });
  }

  void _filterResponses(String query) {
    setState(() {
      filteredResponsesList = responsesList.where((response) {
        final subjectName = response['SubjectName'].toString().toLowerCase();
        final formName = response['FormName'].toString().toLowerCase();
        return subjectName.contains(query.toLowerCase()) ||
            formName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget TextFieldSubject(Map<String, dynamic> form_) {
    String name = form_['SubjectName'];
    if (form_['SpouseName'] != null) {
      name += "/${form_['SpouseName']}";
    }
    if (form_['ChildName'] != null) {
      name += "/${form_['ChildName']}";
    }
    return Text(name);
  }
  
  void _navigateToAdminPage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              const AdminPageUtil()), 
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Display Responses'),
      // ),
      appBar: AppBar(
        title: const Text('Display Responses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToAdminPage,
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                _filterResponses(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by beneficiary or service name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(
                        label: Text('Beneficiary Name/Spouse Name/Child Name')),
                    DataColumn(label: Text('Service Name')),
                    DataColumn(label: Text('Mobile')),
                    DataColumn(label: Text('Age')),
                    DataColumn(label: Text('Village')),
                    DataColumn(label: Text('Survey Datetime')),
                    DataColumn(label: Text('Survey Data')),
                    DataColumn(label: Text('Biometric')),
                  ],
                  rows: filteredResponsesList
                      .map(
                        (form_) => DataRow(
                          cells: <DataCell>[
                            DataCell(TextFieldSubject(form_)),
                            DataCell(Text(form_['FormName'].toString())),
                            DataCell(Text(form_['Mobile'].toString())),
                            DataCell(Text(form_['Age'].toString())),
                            DataCell(Text(form_['Village'].toString())),
                            DataCell(Text(form_['survey_datetime'].toString())),
                            DataCell(
                              GestureDetector(
                                child: const Text('Edit the response'),
                                onTap: () {
                                  String templateSource =
                                      form_['survey_data'].toString();
                                  String rid = form_['rid'];
                                  String sid = form_['sid'];
                                  String recordType = form_['record_type'].toString();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SurveyData(templateSource, rid, sid,recordType),
                                    ),
                                  );
                                },
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                child: const Text('View Biometric'),
                                onTap: () async {
                                  if (kIsWeb) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Biometrics Not Available'),
                                        content: const Text('Biometrics are not supported on the web platform.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  final filepath =
                                      await getApplicationDocumentsDirectory();
                                  showDialog(
                                    context: context,
                                    builder: (_) => biometricDialogue(
                                      path.join(filepath.path,
                                          form_['image'].toString()),
                                      path.join(filepath.path,
                                          form_['voice'].toString()),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget biometricDialogue(String imagePath, String? audioPath) {
    // Check if both image and audio files exist
    bool imageExists = File(imagePath).existsSync();
    bool audioExists = File(audioPath!).existsSync();

    if (!imageExists && !audioExists) {
      // If neither image nor audio files exist, display "Image and Audio not present" message
      return Dialog(
        child: Container(
          width: 200,
          height: 250,
          alignment: Alignment.center,
          child: const Text('Image and Audio are not available'),
        ),
      );
    } else {
      // If at least one of the files exists, display the dialog with image and audio
      return Dialog(
        child: SizedBox(
          width: 200,
          height: 270,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageExists)
                Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              if (!imageExists)
                const SizedBox(
                  height: 50,
                ),
              if (!imageExists) const Text('Image is not available'),
              if (!imageExists)
                const SizedBox(
                  height: 50,
                ),
              const SizedBox(height: 10),
              if (audioExists)
                Container(
                  width: 200,
                  height: 80,
                  alignment: Alignment.center,
                  child: AudioPlayer(
                    source: audioPath,
                    onDelete: () {},
                  ),
                ),
              const SizedBox(height: 10),
              if (!audioExists) const Text('Audio is not available'),
            ],
          ),
        ),
      );
    }
  }
}
