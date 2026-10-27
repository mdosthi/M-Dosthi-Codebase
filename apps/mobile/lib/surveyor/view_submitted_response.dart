// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:app_001/login_page.dart';
// import 'package:flutter/material.dart';
// import 'form_list_page.dart';
// import '../service/language_service.dart';

// class ViewSubmittedResponse extends StatefulWidget {
//   final String rid;

//   const ViewSubmittedResponse({
//     super.key,
//     required this.rid,
//   });

//   @override
//   _ViewSubmittedResponseState createState() => _ViewSubmittedResponseState();
// }

// class _ViewSubmittedResponseState extends State<ViewSubmittedResponse> {
//   bool isLoading = true;
//   Map<String, dynamic>? responseData;
//   String? error;
//   final languageService = LanguageService();

//   @override
//   void initState() {
//     super.initState();
//     fetchResponse();
//   }

//   Future<void> fetchResponse() async {
//     try {
//       String url =
//           "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-form-response";

//       var response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${LoginPage.jwtToken}',
//         },
//         body: jsonEncode({
//           'rid': widget.rid,
//         }),
//       );

//       if (response.statusCode == 200) {
//         var json = jsonDecode(response.body);
//         if (json['status'] == 'success') {
//           setState(() {
//             responseData = json['response'];
//             isLoading = false;
//           });
//         } else {
//           throw Exception(json['message']);
//         }
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   // Method to get score interpretation based on form type and score
//   String getScoreInterpretation(String formName, int score) {
//     String formPrefix = formName.toLowerCase();

//     if (formPrefix == 'ftnd') {
//       if (score <= 2) {
//         return languageService.getText('ftnd_very_low_dependence');
//       }
//       if (score <= 4) return languageService.getText('ftnd_low_dependence');
//       if (score == 5) {
//         return languageService.getText('ftnd_moderate_dependence');
//       }
//       if (score <= 7) return languageService.getText('ftnd_high_dependence');
//       return languageService.getText('ftnd_very_high_dependence');
//     } else if (formPrefix == 'phq9') {
//       if (score <= 4) return languageService.getText('phq9_minimal_depression');
//       if (score <= 9) return languageService.getText('phq9_mild_depression');
//       if (score <= 14) {
//         return languageService.getText('phq9_moderate_depression');
//       }
//       if (score <= 19) {
//         return languageService.getText('phq9_moderately_severe_depression');
//       }
//       return languageService.getText('phq9_severe_depression');
//     } else if (formPrefix == 'qsu') {
//       if (score <= 30) return languageService.getText('qsu_low_craving');
//       if (score <= 50) return languageService.getText('qsu_moderate_craving');
//       return languageService.getText('qsu_high_craving');
//     }

//     return '';
//   }

//   // Method to get color based on score severity
//   // Color getScoreColor(String formName, int score) {
//   //   String formPrefix = formName.toLowerCase();

//   //   if (formPrefix == 'ftnd') {
//   //     if (score <= 4) return Colors.green;
//   //     if (score <= 6) return Colors.orange;
//   //     return Colors.red;
//   //   } else if (formPrefix == 'phq9') {
//   //     if (score <= 4) return Colors.green;
//   //     if (score <= 9) return Colors.lightGreen;
//   //     if (score <= 14) return Colors.orange;
//   //     if (score <= 19) return Colors.deepOrange;
//   //     return Colors.red;
//   //   } else if (formPrefix == 'qsu') {
//   //     if (score <= 30) return Colors.green;
//   //     if (score <= 50) return Colors.orange;
//   //     return Colors.red;
//   //   }

//   //   return Colors.grey;
//   // }

//   Widget buildScoreCard(String formName, int score) {
//     final interpretation = getScoreInterpretation(formName, score);
//     //final scoreColor = getScoreColor(formName, score);

//     return Card(
//       elevation: 4,
//       //color: scoreColor.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               languageService.getText('your_score'),
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 //color: scoreColor,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 score.toString(),
//                 style: const TextStyle(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: Color.fromARGB(255, 5, 0, 0),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             if (interpretation.isNotEmpty)
//               Text(
//                 interpretation,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   //color: scoreColor,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   String getQuestionTranslationKey(String question, String formName) {
//     String formPrefix = formName.toLowerCase();
//     String cleanQuestion = question.trim().toLowerCase();

//     if (formPrefix == 'ftnd') {
//       if (cleanQuestion.contains('wake up') ||
//           cleanQuestion.contains('first cigarette')) {
//         return 'ftnd_q1';
//       } else if (cleanQuestion.contains('difficult to refrain')) {
//         return 'ftnd_q2';
//       } else if (cleanQuestion.contains('hate most to give up')) {
//         return 'ftnd_q3';
//       } else if (cleanQuestion.contains('cigarettes/day') ||
//           cleanQuestion.contains('how many cigarettes')) {
//         return 'ftnd_q4';
//       } else if (cleanQuestion.contains('more frequently') ||
//           cleanQuestion.contains('first hours')) {
//         return 'ftnd_q5';
//       } else if (cleanQuestion.contains('so ill') ||
//           cleanQuestion.contains('in bed most')) {
//         return 'ftnd_q6';
//       }
//     } else if (formPrefix == 'phq9') {
//       if (cleanQuestion.contains('little interest') ||
//           cleanQuestion.contains('pleasure in doing')) {
//         return 'phq9_q1';
//       } else if (cleanQuestion.contains('feeling down') ||
//           cleanQuestion.contains('depressed')) {
//         return 'phq9_q2';
//       } else if (cleanQuestion.contains('trouble falling') ||
//           cleanQuestion.contains('sleeping')) {
//         return 'phq9_q3';
//       } else if (cleanQuestion.contains('tired') ||
//           cleanQuestion.contains('little energy')) {
//         return 'phq9_q4';
//       } else if (cleanQuestion.contains('poor appetite') ||
//           cleanQuestion.contains('overeating')) {
//         return 'phq9_q5';
//       } else if (cleanQuestion.contains('feeling bad about yourself') ||
//           cleanQuestion.contains('failure')) {
//         return 'phq9_q6';
//       } else if (cleanQuestion.contains('trouble concentrating') ||
//           cleanQuestion.contains('reading')) {
//         return 'phq9_q7';
//       } else if (cleanQuestion.contains('moving or speaking') ||
//           cleanQuestion.contains('fidgety')) {
//         return 'phq9_q8';
//       } else if (cleanQuestion.contains('thoughts') ||
//           cleanQuestion.contains('better off dead')) {
//         return 'phq9_q9';
//       } else if (cleanQuestion.contains('difficult') ||
//           cleanQuestion.contains('problems made it')) {
//         return 'phq9_q10';
//       }
//     } else if (formPrefix == 'qsu') {
//       if (cleanQuestion.contains('desire for a cigarette')) {
//         return 'qsu_q1';
//       } else if (cleanQuestion.contains('nothing would be better')) {
//         return 'qsu_q2';
//       } else if (cleanQuestion.contains('if it were possible')) {
//         return 'qsu_q3';
//       } else if (cleanQuestion.contains('control things better')) {
//         return 'qsu_q4';
//       } else if (cleanQuestion.contains('all i want right now')) {
//         return 'qsu_q5';
//       } else if (cleanQuestion.contains('urge for a cigarette')) {
//         return 'qsu_q6';
//       } else if (cleanQuestion.contains('taste good now')) {
//         return 'qsu_q7';
//       } else if (cleanQuestion.contains('do almost anything')) {
//         return 'qsu_q8';
//       } else if (cleanQuestion.contains('less depressed')) {
//         return 'qsu_q9';
//       } else if (cleanQuestion.contains('smoke as soon as possible')) {
//         return 'qsu_q10';
//       }
//     }

//     return '${formPrefix}_${question.toLowerCase().replaceAll(' ', '_')}';
//   }

//   String getAnswerTranslation(String answer, String formName) {
//     String cleanAnswer = answer.trim().toLowerCase();

//     // Handle FTND answers
//     if (cleanAnswer.contains('after 60 minutes')) {
//       return languageService.getText('after_60_minutes');
//     }
//     if (cleanAnswer.contains('31-60 minutes') ||
//         cleanAnswer.contains('31 - 60 minutes')) {
//       return languageService.getText('31_60_minutes');
//     }
//     if (cleanAnswer.contains('6-30 minutes') ||
//         cleanAnswer.contains('6 - 30 minutes')) {
//       return languageService.getText('6_30_minutes');
//     }
//     if (cleanAnswer.contains('within 5 minutes')) {
//       return languageService.getText('within_5_minutes');
//     }
//     if (cleanAnswer == 'yes') return languageService.getText('yes');
//     if (cleanAnswer == 'no') return languageService.getText('no');
//     if (cleanAnswer.contains('all others')) {
//       return languageService.getText('all_others');
//     }
//     if (cleanAnswer.contains('first') && cleanAnswer.contains('morning')) {
//       return languageService.getText('first_morning');
//     }
//     if (cleanAnswer.contains('10 or less')) {
//       return languageService.getText('10_or_less');
//     }
//     if (cleanAnswer.contains('11-20')) return languageService.getText('11_20');
//     if (cleanAnswer.contains('21-30')) return languageService.getText('21_30');
//     if (cleanAnswer.contains('31 or more')) {
//       return languageService.getText('31_or_more');
//     }

//     // Handle PHQ-9 answers
//     if (cleanAnswer.contains('not at all')) {
//       return languageService.getText('not_at_all');
//     }
//     if (cleanAnswer.contains('several days')) {
//       return languageService.getText('several_days');
//     }
//     if (cleanAnswer.contains('more than half the days')) {
//       return languageService.getText('more_than_half');
//     }
//     if (cleanAnswer.contains('nearly every day')) {
//       return languageService.getText('nearly_every_day');
//     }
//     if (cleanAnswer.contains('not difficult at all')) {
//       return languageService.getText('not_difficult');
//     }
//     if (cleanAnswer.contains('somewhat difficult')) {
//       return languageService.getText('somewhat_difficult');
//     }
//     if (cleanAnswer.contains('very difficult')) {
//       return languageService.getText('very_difficult');
//     }
//     if (cleanAnswer.contains('extremely difficult')) {
//       return languageService.getText('extremely_difficult');
//     }

//     // QSU scale answers
//     if (cleanAnswer.contains('strongly disagree')) {
//       return languageService.getText('strongly_disagree');
//     }
//     if (cleanAnswer.contains('neither agree nor disagree')) {
//       return languageService.getText('neither_agree');
//     }
//     if (cleanAnswer.contains('strongly agree')) {
//       return languageService.getText('strongly_agree');
//     }

//     return answer;
//   }

//   Widget buildQuestionAnswer(MapEntry<String, dynamic> entry, String formName) {
//     final questionKey = getQuestionTranslationKey(entry.key, formName);
//     final translatedQuestion = languageService.getText(questionKey);
//     final translatedAnswer =
//         getAnswerTranslation(entry.value.toString(), formName);

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               translatedQuestion,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(translatedAnswer),
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
//           if (isLoading) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           if (error != null) {
//             return Scaffold(
//               appBar: AppBar(title: Text(languageService.getText('error'))),
//               body: Center(child: Text(error!)),
//             );
//           }

//           final surveyData = jsonDecode(responseData!['survey_data']);
//           final formName = responseData!['form_name'];
//           final formNameTranslated =
//               languageService.getText(formName.toLowerCase()) ?? formName;

//           // Get the score from response data (may be null for older responses)
//           final int? score = responseData!['score'];

//           return Scaffold(
//             appBar: AppBar(
//               title: Text(languageService.getText('submitted_response')),
//               automaticallyImplyLeading: false,
//             ),
//             body: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${languageService.getText('form')}: $formNameTranslated',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${languageService.getText('submission_time')}: ${responseData!['survey_datetime']}',
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                           Text(
//                             '${languageService.getText('response_id')}: ${responseData!['rid']}',
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Score card display (only if score is available)
//                   if (score != null) ...[
//                     buildScoreCard(formName, score),
//                     const SizedBox(height: 20),
//                   ],
//                   Text(
//                     languageService.getText('your_responses'),
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   ...surveyData.entries
//                       .map((entry) => buildQuestionAnswer(entry, formName))
//                       .toList(),
//                   const SizedBox(height: 20),
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const FormListPage(),
//                           ),
//                           (route) => false,
//                         );
//                       },
//                       child: Text(languageService.getText('back_to_tests')),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         });
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_001/login_page.dart';
import 'package:flutter/material.dart';
import 'form_list_page.dart';
import '../service/language_service.dart';

class ViewSubmittedResponse extends StatefulWidget {
  final String rid;

  const ViewSubmittedResponse({
    super.key,
    required this.rid,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ViewSubmittedResponseState createState() => _ViewSubmittedResponseState();
}

class _ViewSubmittedResponseState extends State<ViewSubmittedResponse> {
  bool isLoading = true;
  Map<String, dynamic>? responseData;
  String? error;
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    fetchResponse();
  }

  Future<void> fetchResponse() async {
    try {
      String url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-form-response";

      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'rid': widget.rid,
        }),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          setState(() {
            responseData = json['response'];
            isLoading = false;
          });
        } else {
          throw Exception(json['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Method to get score interpretation based on form type and score
  String getScoreInterpretation(String formName, int score) {
    String formPrefix = formName.toLowerCase();

    if (formPrefix == 'ftnd') {
      if (score <= 2) {
        return languageService.getText('ftnd_very_low_dependence');
      }
      if (score <= 4) return languageService.getText('ftnd_low_dependence');
      if (score == 5) {
        return languageService.getText('ftnd_moderate_dependence');
      }
      if (score <= 7) return languageService.getText('ftnd_high_dependence');
      return languageService.getText('ftnd_very_high_dependence');
    } else if (formPrefix == 'phq9') {
      if (score <= 4) return languageService.getText('phq9_minimal_depression');
      if (score <= 9) return languageService.getText('phq9_mild_depression');
      if (score <= 14) {
        return languageService.getText('phq9_moderate_depression');
      }
      if (score <= 19) {
        return languageService.getText('phq9_moderately_severe_depression');
      }
      return languageService.getText('phq9_severe_depression');
    } else if (formPrefix == 'qsu') {
      if (score <= 30) return languageService.getText('qsu_low_craving');
      if (score <= 50) return languageService.getText('qsu_moderate_craving');
      return languageService.getText('qsu_high_craving');
    } else if (formPrefix == 'audit') {
      if (score <= 7) return languageService.getText('audit_low_risk');
      if (score <= 15) return languageService.getText('audit_increasing_risk');
      if (score <= 19) return languageService.getText('audit_higher_risk');
      return languageService.getText('audit_possible_dependence');
    } else if (formPrefix == 'gad-7' || formPrefix == 'gad7') {
      if (score <= 4) return languageService.getText('gad7_minimal_anxiety');
      if (score <= 9) return languageService.getText('gad7_mild_anxiety');
      if (score <= 14) return languageService.getText('gad7_moderate_anxiety');
      return languageService.getText('gad7_severe_anxiety');
    }

    return '';
  }

  Widget buildScoreCard(String formName, int score) {
    final interpretation = getScoreInterpretation(formName, score);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              languageService.getText('your_score'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Text(
                score.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 5, 0, 0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (interpretation.isNotEmpty)
              Text(
                interpretation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  String getQuestionTranslationKey(String question, String formName) {
    // Convert form name to lowercase for consistency
    String formPrefix = formName.toLowerCase();

    // Clean the question text to create a consistent key
    String cleanQuestion = question.trim().toLowerCase();

    // Handle known questions for specific forms
    if (formPrefix == 'ftnd') {
      if (cleanQuestion.contains('wake up') ||
          cleanQuestion.contains('first cigarette')) {
        return 'ftnd_q1';
      } else if (cleanQuestion.contains('difficult to refrain')) {
        return 'ftnd_q2';
      } else if (cleanQuestion.contains('hate most to give up')) {
        return 'ftnd_q3';
      } else if (cleanQuestion.contains('cigarettes/day') ||
          cleanQuestion.contains('how many cigarettes')) {
        return 'ftnd_q4';
      } else if (cleanQuestion.contains('more frequently') ||
          cleanQuestion.contains('first hours')) {
        return 'ftnd_q5';
      } else if (cleanQuestion.contains('so ill') ||
          cleanQuestion.contains('in bed most')) {
        return 'ftnd_q6';
      }
    } else if (formPrefix == 'phq9') {
      if (cleanQuestion.contains('little interest') ||
          cleanQuestion.contains('pleasure in doing')) {
        return 'phq9_q1';
      } else if (cleanQuestion.contains('feeling down') ||
          cleanQuestion.contains('depressed')) {
        return 'phq9_q2';
      } else if (cleanQuestion.contains('trouble falling') ||
          cleanQuestion.contains('sleeping')) {
        return 'phq9_q3';
      } else if (cleanQuestion.contains('tired') ||
          cleanQuestion.contains('little energy')) {
        return 'phq9_q4';
      } else if (cleanQuestion.contains('poor appetite') ||
          cleanQuestion.contains('overeating')) {
        return 'phq9_q5';
      } else if (cleanQuestion.contains('feeling bad about yourself') ||
          cleanQuestion.contains('failure')) {
        return 'phq9_q6';
      } else if (cleanQuestion.contains('trouble concentrating') ||
          cleanQuestion.contains('reading')) {
        return 'phq9_q7';
      } else if (cleanQuestion.contains('moving or speaking') ||
          cleanQuestion.contains('fidgety')) {
        return 'phq9_q8';
      } else if (cleanQuestion.contains('thoughts') ||
          cleanQuestion.contains('better off dead')) {
        return 'phq9_q9';
      } else if (cleanQuestion.contains('difficult') ||
          cleanQuestion.contains('problems made it')) {
        return 'phq9_q10';
      }
    } else if (formPrefix == 'qsu') {
      if (cleanQuestion.contains('desire for a cigarette')) {
        return 'qsu_q1';
      } else if (cleanQuestion.contains('nothing would be better')) {
        return 'qsu_q2';
      } else if (cleanQuestion.contains('if it were possible')) {
        return 'qsu_q3';
      } else if (cleanQuestion.contains('control things better')) {
        return 'qsu_q4';
      } else if (cleanQuestion.contains('all i want right now')) {
        return 'qsu_q5';
      } else if (cleanQuestion.contains('urge for a cigarette')) {
        return 'qsu_q6';
      } else if (cleanQuestion.contains('taste good now')) {
        return 'qsu_q7';
      } else if (cleanQuestion.contains('do almost anything')) {
        return 'qsu_q8';
      } else if (cleanQuestion.contains('less depressed')) {
        return 'qsu_q9';
      } else if (cleanQuestion.contains('smoke as soon as possible')) {
        return 'qsu_q10';
      }
    } else if (formPrefix == 'audit') {
      if (cleanQuestion.contains('how often') &&
          cleanQuestion.contains('drink containing alcohol')) {
        return 'audit_q1';
      } else if (cleanQuestion.contains('how many units') &&
          cleanQuestion.contains('typical day')) {
        return 'audit_q2';
      } else if (cleanQuestion.contains('6 or more units') ||
          cleanQuestion.contains('8 or more')) {
        return 'audit_q3';
      } else if (cleanQuestion.contains('not able to stop drinking')) {
        return 'audit_q4';
      } else if (cleanQuestion
          .contains('failed to do what was normally expected')) {
        return 'audit_q5';
      } else if (cleanQuestion.contains('alcoholic drink in the morning')) {
        return 'audit_q6';
      } else if (cleanQuestion.contains('guilt or remorse')) {
        return 'audit_q7';
      } else if (cleanQuestion.contains('unable to remember')) {
        return 'audit_q8';
      } else if (cleanQuestion.contains('injured') &&
          cleanQuestion.contains('drinking')) {
        return 'audit_q9';
      } else if (cleanQuestion.contains('concerned about your drinking') ||
          cleanQuestion.contains('suggested that you cut down')) {
        return 'audit_q10';
      }
    } else if (formPrefix == 'gad-7' || formPrefix == 'gad7') {
      if (cleanQuestion.contains('nervous') ||
          cleanQuestion.contains('anxious') ||
          cleanQuestion.contains('on edge')) {
        return 'gad7_q1';
      } else if (cleanQuestion.contains('not being able to stop') &&
          cleanQuestion.contains('worrying')) {
        return 'gad7_q2';
      } else if (cleanQuestion.contains('worrying too much')) {
        return 'gad7_q3';
      } else if (cleanQuestion.contains('trouble relaxing')) {
        return 'gad7_q4';
      } else if (cleanQuestion.contains('restless') &&
          cleanQuestion.contains('hard to sit still')) {
        return 'gad7_q5';
      } else if (cleanQuestion.contains('annoyed') ||
          cleanQuestion.contains('irritable')) {
        return 'gad7_q6';
      } else if (cleanQuestion.contains('afraid') &&
          cleanQuestion.contains('something awful')) {
        return 'gad7_q7';
      } else if (cleanQuestion.contains('difficult') &&
          cleanQuestion.contains('problems made it')) {
        return 'gad7_q8';
      }
    }

    // Fallback: use the form prefix with a standardized question key
    return '${formPrefix}_${question.toLowerCase().replaceAll(' ', '_')}';
  }

  String getAnswerTranslation(String answer, String formName) {
    // Try to translate common answer patterns
    String cleanAnswer = answer.trim().toLowerCase();

    // Handle FTND answers
    if (cleanAnswer.contains('after 60 minutes')) {
      return languageService.getText('after_60_minutes');
    }
    if (cleanAnswer.contains('31-60 minutes') ||
        cleanAnswer.contains('31 - 60 minutes')) {
      return languageService.getText('31_60_minutes');
    }
    if (cleanAnswer.contains('6-30 minutes') ||
        cleanAnswer.contains('6 - 30 minutes')) {
      return languageService.getText('6_30_minutes');
    }
    if (cleanAnswer.contains('within 5 minutes')) {
      return languageService.getText('within_5_minutes');
    }
    if (cleanAnswer == 'yes') return languageService.getText('yes');
    if (cleanAnswer == 'no') return languageService.getText('no');
    if (cleanAnswer.contains('all others')) {
      return languageService.getText('all_others');
    }
    if (cleanAnswer.contains('first') && cleanAnswer.contains('morning')) {
      return languageService.getText('first_morning');
    }
    if (cleanAnswer.contains('10 or less')) {
      return languageService.getText('10_or_less');
    }
    if (cleanAnswer.contains('11-20')) return languageService.getText('11_20');
    if (cleanAnswer.contains('21-30')) return languageService.getText('21_30');
    if (cleanAnswer.contains('31 or more')) {
      return languageService.getText('31_or_more');
    }

    // Handle PHQ-9 answers
    if (cleanAnswer.contains('not at all')) {
      return languageService.getText('not_at_all');
    }
    if (cleanAnswer.contains('several days')) {
      return languageService.getText('several_days');
    }
    if (cleanAnswer.contains('more than half the days')) {
      return languageService.getText('more_than_half');
    }
    if (cleanAnswer.contains('nearly every day')) {
      return languageService.getText('nearly_every_day');
    }
    if (cleanAnswer.contains('not difficult at all')) {
      return languageService.getText('not_difficult');
    }
    if (cleanAnswer.contains('somewhat difficult')) {
      return languageService.getText('somewhat_difficult');
    }
    if (cleanAnswer.contains('very difficult')) {
      return languageService.getText('very_difficult');
    }
    if (cleanAnswer.contains('extremely difficult')) {
      return languageService.getText('extremely_difficult');
    }

    // QSU scale answers
    if (cleanAnswer.contains('strongly disagree')) {
      return languageService.getText('strongly_disagree');
    }
    if (cleanAnswer.contains('neither agree nor disagree')) {
      return languageService.getText('neither_agree');
    }
    if (cleanAnswer.contains('strongly agree')) {
      return languageService.getText('strongly_agree');
    }

    // AUDIT answers - Frequency
    if (cleanAnswer.contains('never')) {
      return languageService.getText('never');
    }
    if (cleanAnswer.contains('monthly or less')) {
      return languageService.getText('monthly_or_less');
    }
    if (cleanAnswer.contains('2 to 4 times per month')) {
      return languageService.getText('2_to_4_times_per_month');
    }
    if (cleanAnswer.contains('2 to 3 times per week')) {
      return languageService.getText('2_to_3_times_per_week');
    }
    if (cleanAnswer.contains('4 times or more per week') ||
        cleanAnswer.contains('4 or more times per week')) {
      return languageService.getText('4_or_more_times_per_week');
    }
    if (cleanAnswer.contains('less than monthly')) {
      return languageService.getText('less_than_monthly');
    }
    if (cleanAnswer == 'monthly') {
      return languageService.getText('monthly');
    }
    if (cleanAnswer == 'weekly') {
      return languageService.getText('weekly');
    }
    if (cleanAnswer.contains('daily or almost daily')) {
      return languageService.getText('daily_or_almost_daily');
    }

    // AUDIT answers - Units
    if (cleanAnswer.contains('0 to 2')) {
      return languageService.getText('0_to_2');
    }
    if (cleanAnswer.contains('3 to 4')) {
      return languageService.getText('3_to_4');
    }
    if (cleanAnswer.contains('5 to 6')) {
      return languageService.getText('5_to_6');
    }
    if (cleanAnswer.contains('7 to 9')) {
      return languageService.getText('7_to_9');
    }
    if (cleanAnswer.contains('10 or more')) {
      return languageService.getText('10_or_more');
    }

    // AUDIT answers - Injury/Concern
    if (cleanAnswer.contains('yes') &&
        cleanAnswer.contains('not in') &&
        cleanAnswer.contains('last year')) {
      return languageService.getText('yes_but_not_in_last_year');
    }
    if (cleanAnswer.contains('yes') &&
        cleanAnswer.contains('during') &&
        cleanAnswer.contains('last year')) {
      return languageService.getText('yes_during_last_year');
    }

    // If no specific translation found, return the original answer
    return answer;
  }

  Widget buildQuestionAnswer(MapEntry<String, dynamic> entry, String formName) {
    final questionKey = getQuestionTranslationKey(entry.key, formName);
    final translatedQuestion = languageService.getText(questionKey);
    final translatedAnswer =
        getAnswerTranslation(entry.value.toString(), formName);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translatedQuestion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(translatedAnswer),
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
          if (isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (error != null) {
            return Scaffold(
              appBar: AppBar(title: Text(languageService.getText('error'))),
              body: Center(child: Text(error!)),
            );
          }

          final surveyData = jsonDecode(responseData!['survey_data']);
          final formName = responseData!['form_name'];
          final formNameTranslated =
              languageService.getText(formName.toLowerCase()) ?? formName;

          // Get the score from response data (may be null for older responses)
          final int? score = responseData!['score'];

          return Scaffold(
            appBar: AppBar(
              title: Text(languageService.getText('submitted_response')),
              automaticallyImplyLeading: false,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${languageService.getText('form')}: $formNameTranslated',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${languageService.getText('submission_time')}: ${responseData!['survey_datetime']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${languageService.getText('response_id')}: ${responseData!['rid']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Score card display (only if score is available)
                  if (score != null) ...[
                    buildScoreCard(formName, score),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    languageService.getText('your_responses'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...surveyData.entries
                      .map((entry) => buildQuestionAnswer(entry, formName))
                      .toList(),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FormListPage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(languageService.getText('back_to_tests')),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
