// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:app_001/login_page.dart';
// import '../service/language_service.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// class PastResponsesPage extends StatefulWidget {
//   final String sid;
//   final String formName;

//   // ignore: use_super_parameters
//   const PastResponsesPage({
//     Key? key,
//     required this.sid,
//     required this.formName,
//   }) : super(key: key);

//   @override
//   State<PastResponsesPage> createState() => _PastResponsesPageState();
// }

// class _PastResponsesPageState extends State<PastResponsesPage> {
//   final languageService = LanguageService();
//   List<Map<String, dynamic>> responses = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadResponses();
//   }

//   Future<void> loadResponses() async {
//     try {
//       String url =
//           "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-RecordLog-BySid";

//       var response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${LoginPage.jwtToken}',
//         },
//         body: jsonEncode({'sid': widget.sid}),
//       );

//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['status'] == 'success') {
//           List<Map<String, dynamic>> apiResponses =
//               List<Map<String, dynamic>>.from(jsonResponse['record-log']);

//           apiResponses.sort((a, b) => DateTime.parse(b['survey_datetime'])
//               .compareTo(DateTime.parse(a['survey_datetime'])));

//           setState(() {
//             responses = apiResponses;
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             responses = [];
//             isLoading = false;
//           });
//         }
//       } else {
//         throw Exception('Failed to load responses');
//       }
//     } catch (e) {
//       print('Error loading responses: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   String formatDateTime(String dateTime) {
//     try {
//       final date = DateTime.parse(dateTime);
//       return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
//     } catch (e) {
//       return dateTime;
//     }
//   }

//   String getTranslationKey(String text) {
//     String formPrefix = widget.formName.toLowerCase();
//     // Convert the question text into a translation key
//     // For example, "How soon after you wake up..." becomes "ftnd_q1"
//     switch (formPrefix) {
//       case 'ftnd':
//         switch (text) {
//           case 'How soon after you wake up do you smoke your first cigarette?':
//             return 'ftnd_q1';
//           case 'Do you find it difficult to refrain from smoking in places where it is forbidden, e.g., in church, at the library, cinema, etc?':
//             return 'ftnd_q2';
//           case 'Which cigarette would you hate most to give up?':
//             return 'ftnd_q3';
//           case 'How many cigarettes/day do you smoke?':
//             return 'ftnd_q4';
//           case 'Do you smoke more frequently during the first hours of waking than during the rest of the day?':
//             return 'ftnd_q5';
//           case 'Do you smoke if you are so ill that you are in bed most of the day?':
//             return 'ftnd_q6';
//         }
//         break;
//       case 'qsu':
//         switch (text) {
//           case 'I have a desire for a cigarette right now.':
//             return 'qsu_q1';
//           case 'Nothing would be better than smoking a cigarette right now':
//             return 'qsu_q2';
//           case 'If it were possible, I probably would smoke now.':
//             return 'qsu_q3';
//           case 'I could control things better right now if I could smoke.':
//             return 'qsu_q4';
//           case 'All I want right now is a cigarette.':
//             return 'qsu_q5';
//           case 'I have an urge for a cigarette.':
//             return 'qsu_q6';
//           case 'A cigarette would taste good now.':
//             return 'qsu_q7';
//           case 'I would do almost anything for a cigarette now.':
//             return 'qsu_q8';
//           case 'Smoking would make me less depressed.':
//             return 'qsu_q9';
//           case 'I am going to smoke as soon as possible.':
//             return 'qsu_q10';
//         }
//         break;
//       case 'phq9':
//         switch (text) {
//           case 'Little interest or pleasure in doing things':
//             return 'phq9_q1';
//           case 'Feeling down, depressed, or hopeless':
//             return 'phq9_q2';
//           // Add all PHQ9 cases
//         }
//         break;
//     }
//     // If no matching key found, use the original question with form prefix
//     return '${widget.formName.toLowerCase()}_${text.replaceAll(' ', '_').toLowerCase()}';
//   }

//   Widget buildResponseCard(Map<String, dynamic> response) {
//     final surveyData = json.decode(response['survey_data'] as String);

//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       child: ExpansionTile(
//         title: Text(
//           '${languageService.getText('submission')} ${responses.indexOf(response) + 1}',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           formatDateTime(response['survey_datetime']),
//           style: const TextStyle(color: Colors.grey),
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: surveyData.entries.map<Widget>((entry) {
//                 final translationKey = getTranslationKey(entry.key);
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         languageService.getText(translationKey),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         entry.value.toString(),
//                         style: const TextStyle(fontSize: 15),
//                       ),
//                       const Divider(),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: languageService,
//       builder: (context, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text(
//                 '${widget.formName} - ${languageService.getText('past_tests')}'),
//           ),
//           body: isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : responses.isEmpty
//                   ? Center(
//                       child: Text(
//                         languageService.getText('no_past_responses'),
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: responses.length,
//                       itemBuilder: (context, index) {
//                         return buildResponseCard(responses[index]);
//                       },
//                     ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:app_001/login_page.dart';
import '../service/language_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PastResponsesPage extends StatefulWidget {
  final String sid;
  final String formName;

  const PastResponsesPage({
    super.key,
    required this.sid,
    required this.formName,
  });

  @override
  State<PastResponsesPage> createState() => _PastResponsesPageState();
}

class _PastResponsesPageState extends State<PastResponsesPage> {
  final languageService = LanguageService();
  List<Map<String, dynamic>> responses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadResponses();
  }

  Future<void> loadResponses() async {
    try {
      setState(() => isLoading = true);

      // Fetch responses specifically for the current patient AND the current form
      String url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-RecordLog-BySid";

      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'sid': widget.sid,
          'pat_id': LoginPage.patid // Add patient ID to filter responses
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['record-log'] != null) {
          // Convert to list of maps and filter by patient ID
          List<Map<String, dynamic>> apiResponses =
              List<Map<String, dynamic>>.from(jsonResponse['record-log']);

          // Filter to include only records for this patient
          apiResponses = apiResponses
              .where((record) => record['subject_id'] == LoginPage.patid)
              .toList();

          // Sort by datetime (most recent first)
          apiResponses.sort((a, b) => DateTime.parse(b['survey_datetime'])
              .compareTo(DateTime.parse(a['survey_datetime'])));

          print(
              'Found ${apiResponses.length} responses for patient ${LoginPage.patid} and form ${widget.formName}');

          setState(() {
            responses = apiResponses;
            isLoading = false;
          });
        } else {
          print('No records found or invalid response format');
          setState(() {
            responses = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load responses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading responses: $e');
      setState(() {
        responses = [];
        isLoading = false;
      });
    }
  }

  String formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  String getTranslationKey(String question) {
    // Convert question to translation key based on the form type
    String formPrefix = widget.formName.toLowerCase();

    // Clean the question text to create a consistent key
    String cleanQuestion = question.trim().toLowerCase();

    // Handle known questions for specific forms
    if (formPrefix == 'ftnd') {
      if (cleanQuestion.contains('wake up') &&
          cleanQuestion.contains('first cigarette')) {
        return 'ftnd_q1';
      } else if (cleanQuestion.contains('difficult to refrain')) {
        return 'ftnd_q2';
      }
      // Add more mappings for FTND questions
    } else if (formPrefix == 'phq9') {
      if (cleanQuestion.contains('little interest')) {
        return 'phq9_q1';
      } else if (cleanQuestion.contains('feeling down')) {
        return 'phq9_q2';
      }
      // Add more mappings for PHQ9 questions
    } else if (formPrefix == 'qsu') {
      if (cleanQuestion.contains('desire for a cigarette')) {
        return 'qsu_q1';
      } else if (cleanQuestion.contains('nothing would be better')) {
        return 'qsu_q2';
      }
      // Add more mappings for QSU questions
    }

    // Fallback to a generic key format
    return '${formPrefix}_${question.replaceAll(' ', '_').toLowerCase()}';
  }

  Widget buildResponseCard(Map<String, dynamic> response) {
    Map<String, dynamic> surveyData = {};

    try {
      surveyData = json.decode(response['survey_data'] as String);
    } catch (e) {
      print('Error parsing survey data: $e');
      surveyData = {'Error': 'Could not parse response data'};
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(
          '${languageService.getText('submission')} ${responses.indexOf(response) + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          formatDateTime(response['survey_datetime']),
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: surveyData.entries.map<Widget>((entry) {
                // Get the translation key for this question
                final translationKey = getTranslationKey(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.getText(translationKey),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
                '${widget.formName} - ${languageService.getText('past_tests')}'),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : responses.isEmpty
                  ? Center(
                      child: Text(
                        languageService.getText('no_past_responses'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: responses.length,
                      itemBuilder: (context, index) {
                        return buildResponseCard(responses[index]);
                      },
                    ),
        );
      },
    );
  }
}
