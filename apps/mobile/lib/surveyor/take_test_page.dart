// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:app_001/backend/database_helper.dart';
// import 'package:http/http.dart' as http;
// import 'package:app_001/login_page.dart';
// import 'package:app_001/surveyor/past_responses_page.dart';
// import 'package:app_001/surveyor/view_submitted_response.dart';
// import '../service/language_service.dart';

// class TakeTestPage extends StatefulWidget {
//   final Map<String, dynamic> form;

//   const TakeTestPage({
//     Key? key,
//     required this.form,
//   }) : super(key: key);

//   @override
//   State<TakeTestPage> createState() => _TakeTestPageState();
// }

// class _TakeTestPageState extends State<TakeTestPage> {
//   List<Map<String, dynamic>> questions = [];
//   Map<String, dynamic> responses = {};
//   bool isLoading = true;
//   final languageService = LanguageService();

//   @override
//   void initState() {
//     super.initState();
//     loadQuestions();
//   }

//   void loadQuestions() {
//     try {
//       print('Loading form: ${widget.form['name']}');
//       final templateSourceJson = widget.form['template_source'];

//       if (templateSourceJson == null) {
//         setState(() {
//           questions = [];
//           isLoading = false;
//         });
//         return;
//       }

//       try {
//         final parsed = jsonDecode(templateSourceJson);
//         if (parsed != null && parsed['template_source'] != null) {
//           final questionsList =
//               List<Map<String, dynamic>>.from(parsed['template_source']);

//           setState(() {
//             questions = questionsList;
//             for (var question in questions) {
//               String questionText = question['attrname'];
//               String questionType = question['attrtype'];

//               if (questionType == 'single') {
//                 responses[questionText] = '';
//               } else if (questionType == 'multiple') {
//                 responses[questionText] = [];
//               } else {
//                 responses[questionText] = '';
//               }
//             }
//             isLoading = false;
//           });
//         }
//       } catch (parseError) {
//         print('Error parsing template source JSON: $parseError');
//         setState(() {
//           questions = [];
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading questions: $e');
//       setState(() {
//         questions = [];
//         isLoading = false;
//       });
//     }
//   }

//   String getTranslationKey(String text) {
//     String formName = widget.form['name'];
//     switch (formName) {
//       case 'FTND':
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

//       case 'QSU':
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

//       case 'PHQ9':
//         switch (text) {
//           case 'Little interest or pleasure in doing things':
//             return 'phq9_q1';
//           case 'Feeling down, depressed, or hopeless':
//             return 'phq9_q2';
//           case 'Trouble falling or staying asleep, or sleeping too much':
//             return 'phq9_q3';
//           case 'Feeling tired or having little energy':
//             return 'phq9_q4';
//           case 'Poor appetite or overeating':
//             return 'phq9_q5';
//           case 'Feeling bad about yourself or that you are a failure or have let yourself or your family down':
//             return 'phq9_q6';
//           case 'Trouble concentrating on things, such as reading the newspaper or watching television':
//             return 'phq9_q7';
//           case 'Moving or speaking so slowly that other people could have noticed. Or the opposite being so figety or restless that you have been moving around a lot more than usual':
//             return 'phq9_q8';
//           case 'Thoughts that you would be better off dead, or of hurting yourself':
//             return 'phq9_q9';
//           case 'If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people?':
//             return 'phq9_q10';
//         }
//         break;
//     }
//     return text; // Return original text if no translation key found
//   }

//   String getOptionTranslationKey(String option) {
//     switch (option) {
//       case 'After 60 Minutes':
//         return 'after_60_minutes';
//       case '31 - 60 minutes':
//         return '31_60_minutes';
//       case '6-30 minutes':
//         return '6_30_minutes';
//       case 'Within 5 minutes':
//         return 'within_5_minutes';
//       case 'Yes':
//         return 'yes';
//       case 'No':
//         return 'no';
//       case 'All others':
//         return 'all_others';
//       case 'The first one in the morning':
//         return 'first_morning';
//       case '10 or less':
//         return '10_or_less';
//       case '11-20':
//         return '11_20';
//       case '21-30':
//         return '21_30';
//       case '31 or more':
//         return '31_or_more';
//       case 'Not difficult at all':
//         return 'not_difficult';
//       case 'Somewhat difficult':
//         return 'somewhat_difficult';
//       case 'Very difficult':
//         return 'very_difficult';
//       case 'Extremely difficult':
//         return 'extremely_difficult';
//       default:
//         return option;
//     }
//   }

//   Future<bool> validateAndSaveResponse() async {
//     bool allRequiredQuestionsAnswered = true;

//     for (var question in questions) {
//       final req = question['attrreq'];
//       final questionText = question['attrname'];
//       final response = responses[questionText];

//       if ((req == 'true' || req == 1 || req == '1') &&
//           (response == null || response.toString().isEmpty)) {
//         allRequiredQuestionsAnswered = false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 '${languageService.getText("please_answer")}: ${languageService.getText(getTranslationKey(questionText))}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         break;
//       }
//     }

//     return allRequiredQuestionsAnswered;
//   }

//   Future<void> saveResponses() async {
//     try {
//       final responsesJson = json.encode(responses);
//       final sid = widget.form['sid'];
//       DateTime now = DateTime.now();
//       final formattedDatetime = now.toUtc().toIso8601String();

//       String url =
//           "${LoginPage.protocol}://${LoginPage.domainName}/api/user/submit-form-response";

//       var response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${LoginPage.jwtToken}',
//         },
//         body: jsonEncode({
//           'pat_id': LoginPage.patid,
//           'sid': sid,
//           'survey_datetime': formattedDatetime,
//           'record_type': '0',
//           'survey_data': responsesJson,
//           'userid': LoginPage.userId,
//           'username': LoginPage.username,
//           'image': 'null',
//           'voice': 'null'
//         }),
//       );

//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['status'] == 'success') {
//           await DatabaseHelper.instance.insertResponse({
//             'rid': jsonResponse['rid'],
//             'subject_id': LoginPage.patid,
//             'survey_datetime': formattedDatetime,
//             'sid': sid,
//             'record_type': 0,
//             'survey_data': responsesJson,
//             'userid': LoginPage.userId,
//             'username': LoginPage.username,
//             'upload_time': 1,
//             'image': 'null',
//             'voice': 'null'
//           });

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content:
//                   Text(languageService.getText('test_submitted_successfully')),
//               backgroundColor: Colors.green,
//             ),
//           );

//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ViewSubmittedResponse(
//                 rid: jsonResponse['rid'],
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('Error submitting test: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//               Text('${languageService.getText("error_submitting_test")}: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget buildQuestionWidget(Map<String, dynamic> question) {
//     final questionText = question['attrname'];
//     final questionType = question['attrtype'];
//     final required = question['attrreq'] == 'true' || question['attrreq'] == 1;
//     final unit = question['attrunit'] == "none" ? "" : question['attrunit'];
//     final String attrValues = question['attrvalues'] ?? '';

//     Widget buildQuestionTitle() {
//       String translatedQuestion =
//           languageService.getText(getTranslationKey(questionText));
//       String unitText =
//           unit.isNotEmpty ? ' (${languageService.getText(unit)})' : '';
//       String requiredText = required ? ' *' : '';

//       return Text(
//         translatedQuestion + unitText + requiredText,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       );
//     }

//     if (questionType == 'single' && attrValues.isNotEmpty) {
//       final List<String> options =
//           attrValues.split(';').where((option) => option.isNotEmpty).toList();

//       return Card(
//         margin: const EdgeInsets.all(8),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               buildQuestionTitle(),
//               const SizedBox(height: 8),
//               ...options.map((option) => RadioListTile<String>(
//                     title: Text(languageService
//                         .getText(getOptionTranslationKey(option))),
//                     value: option,
//                     groupValue: responses[questionText],
//                     onChanged: (value) {
//                       setState(() {
//                         responses[questionText] = value;
//                       });
//                     },
//                   )),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       margin: const EdgeInsets.all(8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             buildQuestionTitle(),
//             const SizedBox(height: 8),
//             TextFormField(
//               decoration: InputDecoration(
//                 border: const OutlineInputBorder(),
//                 hintText: languageService.getText('enter_answer'),
//               ),
//               onChanged: (value) {
//                 responses[questionText] = value;
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//         listenable: languageService,
//         builder: (context, child) {
//           return Scaffold(
//             appBar: AppBar(
//               title: Text(widget.form['name']),
//               actions: [
//                 TextButton.icon(
//                   icon: const Icon(Icons.history, color: Colors.green),
//                   label: Text(languageService.getText('show_tests'),
//                       style: const TextStyle(color: Colors.green)),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PastResponsesPage(
//                           sid: widget.form['sid'],
//                           formName: widget.form['name'],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             body: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : questions.isEmpty
//                     ? Center(
//                         child: Text(
//                           languageService.getText('no_questions_available'),
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : SingleChildScrollView(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               ...questions
//                                   .map((question) =>
//                                       buildQuestionWidget(question))
//                                   .toList(),
//                               const SizedBox(height: 20),
//                               ElevatedButton(
//                                 onPressed: () async {
//                                   bool isValid =
//                                       await validateAndSaveResponse();
//                                   if (isValid) {
//                                     await saveResponses();
//                                   }
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   padding: const EdgeInsets.all(16),
//                                 ),
//                                 child: Text(
//                                   languageService.getText('submit'),
//                                   style: const TextStyle(fontSize: 16),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//           );
//         });
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:app_001/backend/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:app_001/login_page.dart';
import 'package:app_001/surveyor/past_responses_page.dart';
import 'package:app_001/surveyor/view_submitted_response.dart';
import '../service/language_service.dart';

class TakeTestPage extends StatefulWidget {
  final Map<String, dynamic> form;

  const TakeTestPage({
    super.key,
    required this.form,
  });

  @override
  State<TakeTestPage> createState() => _TakeTestPageState();
}

class _TakeTestPageState extends State<TakeTestPage> {
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> responses = {};
  bool isLoading = true;
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  void loadQuestions() {
    try {
      print('Loading form: ${widget.form['name']}');
      final templateSourceJson = widget.form['template_source'];

      if (templateSourceJson == null) {
        setState(() {
          questions = [];
          isLoading = false;
        });
        return;
      }

      try {
        final parsed = jsonDecode(templateSourceJson);
        if (parsed != null && parsed['template_source'] != null) {
          final questionsList =
              List<Map<String, dynamic>>.from(parsed['template_source']);

          setState(() {
            questions = questionsList;
            for (var question in questions) {
              String questionText = question['attrname'];
              String questionType = question['attrtype'];

              if (questionType == 'single') {
                responses[questionText] = '';
              } else if (questionType == 'multiple') {
                responses[questionText] = [];
              } else {
                responses[questionText] = '';
              }
            }
            isLoading = false;
          });
        }
      } catch (parseError) {
        print('Error parsing template source JSON: $parseError');
        setState(() {
          questions = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        questions = [];
        isLoading = false;
      });
    }
  }

  String getTranslationKey(String text) {
    String formName = widget.form['name'];
    switch (formName) {
      case 'FTND':
        switch (text) {
          case 'How soon after you wake up do you smoke your first cigarette?':
            return 'ftnd_q1';
          case 'Do you find it difficult to refrain from smoking in places where it is forbidden, e.g., in church, at the library, cinema, etc?':
            return 'ftnd_q2';
          case 'Which cigarette would you hate most to give up?':
            return 'ftnd_q3';
          case 'How many cigarettes/day do you smoke?':
            return 'ftnd_q4';
          case 'Do you smoke more frequently during the first hours of waking than during the rest of the day?':
            return 'ftnd_q5';
          case 'Do you smoke if you are so ill that you are in bed most of the day?':
            return 'ftnd_q6';
        }
        break;

      case 'QSU':
        switch (text) {
          case 'I have a desire for a cigarette right now.':
            return 'qsu_q1';
          case 'Nothing would be better than smoking a cigarette right now':
            return 'qsu_q2';
          case 'If it were possible, I probably would smoke now.':
            return 'qsu_q3';
          case 'I could control things better right now if I could smoke.':
            return 'qsu_q4';
          case 'All I want right now is a cigarette.':
            return 'qsu_q5';
          case 'I have an urge for a cigarette.':
            return 'qsu_q6';
          case 'A cigarette would taste good now.':
            return 'qsu_q7';
          case 'I would do almost anything for a cigarette now.':
            return 'qsu_q8';
          case 'Smoking would make me less depressed.':
            return 'qsu_q9';
          case 'I am going to smoke as soon as possible.':
            return 'qsu_q10';
        }
        break;

      case 'PHQ9':
        switch (text) {
          case 'Little interest or pleasure in doing things':
            return 'phq9_q1';
          case 'Feeling down, depressed, or hopeless':
            return 'phq9_q2';
          case 'Trouble falling or staying asleep, or sleeping too much':
            return 'phq9_q3';
          case 'Feeling tired or having little energy':
            return 'phq9_q4';
          case 'Poor appetite or overeating':
            return 'phq9_q5';
          case 'Feeling bad about yourself or that you are a failure or have let yourself or your family down':
            return 'phq9_q6';
          case 'Trouble concentrating on things, such as reading the newspaper or watching television':
            return 'phq9_q7';
          case 'Moving or speaking so slowly that other people could have noticed. Or the opposite being so figety or restless that you have been moving around a lot more than usual':
            return 'phq9_q8';
          case 'Thoughts that you would be better off dead, or of hurting yourself':
            return 'phq9_q9';
          case 'If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people?':
            return 'phq9_q10';
        }
        break;

      case 'AUDIT':
        switch (text) {
          case 'How often do you have a drink containing alcohol?':
            return 'audit_q1';
          case 'How many units of alcohol do you drink on a typical day when you are drinking?':
            return 'audit_q2';
          case 'How often have you had 6 or more units if female, or 8 or more if male, on a single occasion in the last year?':
            return 'audit_q3';
          case 'How often during the last year have you found that you were not able to stop drinking once you had started?':
            return 'audit_q4';
          case 'How often during the last year have you failed to do what was normally expected from you because of your drinking?':
            return 'audit_q5';
          case 'How often during the last year have you needed an alcoholic drink in the morning to get yourself going after a heavy drinking session?':
            return 'audit_q6';
          case 'How often during the last year have you had a feeling of guilt or remorse after drinking?':
            return 'audit_q7';
          case 'How often during the last year have you been unable to remember what happened the night before because you had been drinking?':
            return 'audit_q8';
          case 'Have you or somebody else been injured as a result of your drinking?':
            return 'audit_q9';
          case 'Has a relative or friend, doctor or other health worker been concerned about your drinking or suggested that you cut down?':
            return 'audit_q10';
        }
        break;

      case 'GAD-7':
        //case 'GAD7':
        switch (text) {
          case 'Feeling nervous, anxious, or on edge':
            return 'gad7_q1';
          case 'Not being able to stop or control worrying':
            return 'gad7_q2';
          case 'Worrying too much about different things':
            return 'gad7_q3';
          case 'Trouble relaxing':
            return 'gad7_q4';
          case 'Being so restless that it is hard to sit still':
            return 'gad7_q5';
          case 'Becoming easily annoyed or irritable':
            return 'gad7_q6';
          case 'Feeling afraid as if something awful might happen':
            return 'gad7_q7';
          case 'If you checked off any problems, how difficult have these made it for you to do your work, take care of things at home, or get along with other people?':
            return 'gad7_q8';
        }
        break;
    }
    return text; // Return original text if no translation key found
  }

  String getOptionTranslationKey(String option) {
    switch (option) {
      // FTND Options
      case 'After 60 Minutes':
        return 'after_60_minutes';
      case '31 - 60 minutes':
        return '31_60_minutes';
      case '6-30 minutes':
        return '6_30_minutes';
      case 'Within 5 minutes':
        return 'within_5_minutes';
      case 'Yes':
        return 'yes';
      case 'No':
        return 'no';
      case 'All others':
        return 'all_others';
      case 'The first one in the morning':
        return 'first_morning';
      case '10 or less':
        return '10_or_less';
      case '11-20':
        return '11_20';
      case '21-30':
        return '21_30';
      case '31 or more':
        return '31_or_more';

      // PHQ-9 and GAD-7 Shared Options
      case 'Not at all':
        return 'not_at_all';
      case 'Several days':
        return 'several_days';
      case 'More than half the days':
        return 'more_than_half';
      case 'Nearly every day':
        return 'nearly_every_day';
      case 'Not difficult at all':
        return 'not_difficult';
      case 'Somewhat difficult':
        return 'somewhat_difficult';
      case 'Very difficult':
        return 'very_difficult';
      case 'Extremely difficult':
        return 'extremely_difficult';

      // AUDIT Options - Frequency
      case 'Never':
        return 'never';
      case 'Monthly or less':
        return 'monthly_or_less';
      case '2 to 4 times per month':
        return '2_to_4_times_per_month';
      case '2 to 3 times per week':
        return '2_to_3_times_per_week';
      case '4 times or more per week':
        return '4_or_more_times_per_week';

      // AUDIT Options - Units
      case '0 to 2':
        return '0_to_2';
      case '3 to 4':
        return '3_to_4';
      case '5 to 6':
        return '5_to_6';
      case '7 to 9':
        return '7_to_9';
      case '10 or more':
        return '10_or_more';

      // AUDIT Options - Less Frequent
      case 'Less than monthly':
        return 'less_than_monthly';
      case 'Monthly':
        return 'monthly';
      case 'Weekly':
        return 'weekly';
      case 'Daily or almost daily':
        return 'daily_or_almost_daily';

      // AUDIT Options - Injury/Concern Questions
      case 'Yes but not in the last year':
      case 'Yes, but not in the last year':
        return 'yes_but_not_in_last_year';
      case 'Yes during the last year':
      case 'Yes, during the last year':
        return 'yes_during_last_year';

      default:
        return option;
    }
  }

  Future<bool> validateAndSaveResponse() async {
    bool allRequiredQuestionsAnswered = true;

    for (var question in questions) {
      final req = question['attrreq'];
      final questionText = question['attrname'];
      final response = responses[questionText];

      if ((req == 'true' || req == 1 || req == '1') &&
          (response == null || response.toString().isEmpty)) {
        allRequiredQuestionsAnswered = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${languageService.getText("please_answer")}: ${languageService.getText(getTranslationKey(questionText))}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }
    }

    return allRequiredQuestionsAnswered;
  }

  Future<void> saveResponses() async {
    try {
      final responsesJson = json.encode(responses);
      final sid = widget.form['sid'];
      DateTime now = DateTime.now();
      final formattedDatetime = now.toUtc().toIso8601String();

      String url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/submit-form-response";

      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'pat_id': LoginPage.patid,
          'sid': sid,
          'survey_datetime': formattedDatetime,
          'record_type': '0',
          'survey_data': responsesJson,
          'userid': LoginPage.userId,
          'username': LoginPage.username,
          'image': 'null',
          'voice': 'null'
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (!kIsWeb) {
            try {
              await DatabaseHelper.instance.insertResponse({
                'rid': jsonResponse['rid'],
                'subject_id': LoginPage.patid,
                'survey_datetime': formattedDatetime,
                'sid': sid,
                'record_type': 0,
                'survey_data': responsesJson,
                'userid': LoginPage.userId,
                'username': LoginPage.username,
                'upload_time': 1,
                'image': 'null',
                'voice': 'null'
              });
            } catch (dbError) {
              print('TakeTestPage: Database error saving response locally: $dbError');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(languageService.getText('test_submitted_successfully')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewSubmittedResponse(
                rid: jsonResponse['rid'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${languageService.getText("error_submitting_test")}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final questionText = question['attrname'];
    final questionType = question['attrtype'];
    final required = question['attrreq'] == 'true' || question['attrreq'] == 1;
    final unit = question['attrunit'] == "none" ? "" : question['attrunit'];
    final String attrValues = question['attrvalues'] ?? '';

    Widget buildQuestionTitle() {
      String translatedQuestion =
          languageService.getText(getTranslationKey(questionText));
      String unitText =
          unit.isNotEmpty ? ' (${languageService.getText(unit)})' : '';
      String requiredText = required ? ' *' : '';

      return Text(
        translatedQuestion + unitText + requiredText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (questionType == 'single' && attrValues.isNotEmpty) {
      final List<String> options =
          attrValues.split(';').where((option) => option.isNotEmpty).toList();

      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildQuestionTitle(),
              const SizedBox(height: 8),
              ...options.map((option) => RadioListTile<String>(
                    title: Text(languageService
                        .getText(getOptionTranslationKey(option))),
                    value: option,
                    groupValue: responses[questionText],
                    onChanged: (value) {
                      setState(() {
                        responses[questionText] = value;
                      });
                    },
                  )),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildQuestionTitle(),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: languageService.getText('enter_answer'),
              ),
              onChanged: (value) {
                responses[questionText] = value;
              },
            ),
          ],
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
            appBar: AppBar(
              title: Text(widget.form['name']),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.history, color: Colors.green),
                  label: Text(languageService.getText('show_tests'),
                      style: const TextStyle(color: Colors.green)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastResponsesPage(
                          sid: widget.form['sid'],
                          formName: widget.form['name'],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                    ? Center(
                        child: Text(
                          languageService.getText('no_questions_available'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...questions
                                  .map((question) =>
                                      buildQuestionWidget(question))
                                  ,
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  bool isValid =
                                      await validateAndSaveResponse();
                                  if (isValid) {
                                    await saveResponses();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: Text(
                                  languageService.getText('submit'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          );
        });
  }
}
