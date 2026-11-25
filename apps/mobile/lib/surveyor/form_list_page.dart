// import 'dart:convert';
// import 'package:mdosthi_app/surveyor/take_test_page.dart';
// import 'package:flutter/material.dart';
// import 'package:mdosthi_app/backend/database_helper.dart';
// import 'package:mdosthi_app/login_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:mdosthi_app/surveyor/hamburger_menu.dart';
// import 'package:mdosthi_app/surveyor/survery_page_util.dart';
// import 'package:mdosthi_app/utils/NetworkSpeedChecker.dart';
// import '../service/language_service.dart';

// class FormListPage extends StatefulWidget {
//   const FormListPage({super.key});

//   @override
//   State<FormListPage> createState() => _FormListPageState();
// }

// class _FormListPageState extends State<FormListPage> {
//   List<Map<String, dynamic>> formList = [];
//   List<Map<String, dynamic>> filteredList = [];
//   TextEditingController searchController = TextEditingController();
//   bool isLoading = true;
//   final languageService = LanguageService();

//   @override
//   void initState() {
//     super.initState();
//     loadPrescribedForms();
//   }

//   Future<void> loadPrescribedForms() async {
//     try {
//       setState(() => isLoading = true);

//       String url =
//           "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-prescribed-forms-for-patient";

//       var response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${LoginPage.jwtToken}',
//         },
//         body: jsonEncode({
//           "pat_id": LoginPage.patid,
//         }),
//       );

//       if (response.statusCode == 200) {
//         var json = jsonDecode(response.body);

//         if (json['status'] == 'success') {
//           final dbHelper = DatabaseHelper.instance;

//           for (var form in json['forms']) {
//             await dbHelper.storeTheSurveyForms({
//               'name': form['name'],
//               'sid': form['sid'],
//               'creation_date': form['creation_date'],
//               'description': form['description'],
//               'template_source': form['template_source'],
//               'details_source': form['details_source'],
//               'upload_time': "1"
//             });
//           }

//           final forms = await dbHelper.getForms();

//           if (mounted) {
//             setState(() {
//               formList = forms;
//               filteredList = forms;
//             });
//           }
//         }
//       } else {
//         throw Exception('Failed to load prescribed forms');
//       }
//     } catch (e) {
//       // ignore: avoid_print
//       print('Error loading prescribed forms: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 languageService.getText('error_loading_forms') + e.toString()),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   void filterForms(String query) {
//     setState(() {
//       filteredList = formList
//           .where((form) => form['name']
//               .toString()
//               .toLowerCase()
//               .contains(query.toLowerCase()))
//           .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//         listenable: languageService,
//         builder: (context, child) {
//           return Scaffold(
//             drawer: HamburgerMenu(
//               userName: LoginPage.userId,
//               email: LoginPage.username,
//               pages: const [
//                 SurveyorPageUtil(),
//                 LoginPage(),
//                 NetworkSpeedChecker(),
//               ],
//               icons: const [
//                 Icons.home,
//                 Icons.logout,
//                 Icons.network_cell_rounded,
//               ],
//               pageTitles: [
//                 languageService.getText('home'),
//                 languageService.getText('logout'),
//                 languageService.getText('bandwidth'),
//               ],
//             ),
//             appBar: AppBar(
//               title: Text(languageService.getText('prescribed_tests')),
//               actions: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.arrow_back_rounded),
//                 ),
//               ],
//             ),
//             body: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: TextField(
//                           controller: searchController,
//                           onChanged: filterForms,
//                           decoration: InputDecoration(
//                             labelText: languageService.getText('search_forms'),
//                             prefixIcon: const Icon(Icons.search),
//                             border: const OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: filteredList.isEmpty
//                             ? Center(
//                                 child: Text(
//                                   languageService.getText('no_forms_available'),
//                                   style: const TextStyle(fontSize: 16),
//                                 ),
//                               )
//                             : ListView.builder(
//                                 itemCount: filteredList.length,
//                                 itemBuilder: (context, index) {
//                                   final form = filteredList[index];
//                                   return Card(
//                                     margin: const EdgeInsets.symmetric(
//                                         horizontal: 8.0, vertical: 4.0),
//                                     child: ListTile(
//                                       title: Text(
//                                         languageService.getText(form['name']
//                                             .toString()
//                                             .toLowerCase()),
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       subtitle: Text(languageService.getText(
//                                           '${form['name'].toString().toLowerCase()}_title')),
//                                       trailing:
//                                           const Icon(Icons.arrow_forward_ios),
//                                       onTap: () async {
//                                         try {
//                                           final dbHelper =
//                                               DatabaseHelper.instance;
//                                           final formData = await dbHelper
//                                               .getFormWithSid(form['sid']);

//                                           if (formData.isNotEmpty) {
//                                             Navigator.push(
//                                               // ignore: use_build_context_synchronously
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder: (context) =>
//                                                     TakeTestPage(
//                                                   form: formData.first,
//                                                 ),
//                                               ),
//                                             );
//                                           } else {
//                                             // ignore: use_build_context_synchronously
//                                             ScaffoldMessenger.of(context)
//                                                 .showSnackBar(
//                                               SnackBar(
//                                                 content: Text(
//                                                     languageService.getText(
//                                                         'error_loading_form_data')),
//                                                 backgroundColor: Colors.red,
//                                               ),
//                                             );
//                                           }
//                                         } catch (e) {
//                                           // ignore: avoid_print
//                                           print('Error in onTap: $e');
//                                           // ignore: use_build_context_synchronously
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             SnackBar(
//                                               content: Text(languageService
//                                                       .getText('error') +
//                                                   e.toString()),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                         }
//                                       },
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//           );
//         });
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../login_page.dart';
import '../service/language_service.dart';
import 'take_test_page.dart';
import 'hamburger_menu.dart';
import 'survery_page_util.dart';
import '../utils/NetworkSpeedChecker.dart';

class FormListPage extends StatefulWidget {
  const FormListPage({super.key});

  @override
  State<FormListPage> createState() => _FormListPageState();
}

class _FormListPageState extends State<FormListPage> {
  final languageService = LanguageService();

  List<Map<String, dynamic>> availableForms = [];
  List<Map<String, dynamic>> filteredForms = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFormsFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormsFromAPI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-prescribed-forms-for-patient";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          setState(() {
            availableForms = (jsonResponse['forms'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            filteredForms = availableForms;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        errorMessage = 'Failed to load forms';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterForms(String query) {
    setState(() {
      filteredForms = query.isEmpty
          ? availableForms
          : availableForms.where((form) {
              final name = form['name'].toString().toLowerCase();
              final desc = (form['description'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase()) ||
                  desc.contains(query.toLowerCase());
            }).toList();
    });
  }

  Widget _buildFormCard(Map<String, dynamic> form) {
    final formName = form['name'] ?? '';
    final translatedName = languageService.getText(formName.toLowerCase());
    final translatedDesc =
        languageService.getText('${formName.toLowerCase()}_title');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.assignment),
        title: Text(translatedName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          translatedDesc != '${formName.toLowerCase()}_title'
              ? translatedDesc
              : (form['description'] ?? ''),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TakeTestPage(form: form),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageService,
      builder: (_, __) {
        return Scaffold(
          drawer: HamburgerMenu(
            userName: LoginPage.userId,
            email: LoginPage.username,
            pages: const [
              SurveyorPageUtil(),
              LoginPage(),
              NetworkSpeedChecker(),
            ],
            icons: const [
              Icons.home,
              Icons.logout,
              Icons.network_cell_rounded,
            ],
            pageTitles: [
              languageService.getText('home'),
              languageService.getText('logout'),
              languageService.getText('bandwidth'),
            ],
          ),
          appBar: AppBar(
            title: Text(languageService.getText('prescribed_tests')),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadFormsFromAPI,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterForms,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: languageService.getText('search_forms'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!))
                        : filteredForms.isEmpty
                            ? Center(
                                child: Text(languageService
                                    .getText('no_forms_available')),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadFormsFromAPI,
                                child: ListView.builder(
                                  itemCount: filteredForms.length,
                                  itemBuilder: (_, i) =>
                                      _buildFormCard(filteredForms[i]),
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
