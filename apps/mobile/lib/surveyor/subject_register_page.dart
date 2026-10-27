import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:camera/camera.dart';
import 'package:app_001/login_page.dart';
import 'package:app_001/surveyor/hamburger_menu.dart';
import 'package:app_001/surveyor/survery_page_util.dart';
import 'package:app_001/utils/NetworkSpeedChecker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:record/record.dart';

import 'form_details.dart';
import 'package:app_001/surveyor/subject_selection_survey.dart';

import '../backend/database_helper.dart';
import '../Audio/audio_player.dart';
import '../Audio/audio_recorder.dart';

Map<String, dynamic> villageID2Name = {};
Map<String, dynamic> villageName2ID = {};

class SubjectRegisterPage extends StatefulWidget {
  const SubjectRegisterPage({super.key});

  @override
  _SubjectRegisterPageState createState() => _SubjectRegisterPageState();
}

class _SubjectRegisterPageState extends State<SubjectRegisterPage> {
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController maritalStatusController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController idTypeController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController spouseNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController casteController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController voiceController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController zoneidController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> _controllers = [TextEditingController()];
Map<String, String>? dropDownIndex={};

  File? _image;

  bool showPlayer = false;
  String? audioPath;
  // Future<void> _getImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  //   setState(() {
  //     if (pickedFile != null) {
  //       _image = File(pickedFile.path);
  //     }
  //   });
  // }

  @override
  void initState() {
    showPlayer = false;

    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> moveAudioFile(
      String? sourceFilePath, String destinationFilePath) async {
    if (sourceFilePath == null) return;
    File sourceFile = File(sourceFilePath);
    File destinationFile = File(destinationFilePath);

    sourceFile.rename(destinationFile.path).then((_) {
      print('File moved successfully.');
    }).catchError((error) {
      print('Error moving file: $error');
    });
  }

  Future<void> addSubject() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    // _image.
    // print(te);
    // print('done');
    if(subjectNameController.text.trim()=="")
    {
      await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error occured'),
                              content: const Text(
                                  'Beneficiary name is empty !'),
                              actions: [
                                TextButton(
                                  //onPressed: () => Navigator.pop(context),
                                  onPressed: () {
                                    //Navigator.pop(context);
                                    // Ensure the progress dialog is closed if still open
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
      return;
    }
    String subjectName = subjectNameController.text.trim();
    String spouseName = spouseNameController.text.trim();
    String childName = childNameController.text.trim();
    String maritalStatus = maritalStatusController.text;
    //String village = villageController.text;
    String idType = idTypeController.text;
    String idNumber = idNumberController.text;
    String mobile = mobileController.text;
    String address = addressController.text;
    String age = ageController.text;
    String sex = sexController.text;
    String caste = casteController.text;
    String religion = religionController.text;
    String occupation = occupationController.text;
    //String zoneid = zoneidController.text;
    print(zoneidController.text);
    if(zoneidController.text=="")
    {
      await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error occured'),
                              content: const Text(
                                  'Village not selected !'),
                              actions: [
                                TextButton(
                                  //onPressed: () => Navigator.pop(context),
                                  onPressed: () {
                                    //Navigator.pop(context);
                                    // Ensure the progress dialog is closed if still open
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
      return;
    }
    String village = zoneidController.text;
    String zoneid = villageName2ID[zoneidController.text];
    
    
    String email = emailController.text;
    int count = 1 + (await DatabaseHelper.instance.getCountForZone(zoneid));
    String subjectID = "$count";
    List<String> names = _controllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    String relatives = names.join(', ');

    String image = "";
    String voice = "";

    if (!kIsWeb) {
      Directory documentDirectory = await getApplicationDocumentsDirectory();
      String filename = "$subjectID.jpg";
      String voiceFile = "$subjectID.mp3";
      String pathutil = path.join(documentDirectory.path, filename);
      print(pathutil);
      await _image?.copy(pathutil);
      image = filename;
      voice = voiceFile;
      await moveAudioFile(audioPath, path.join(documentDirectory.path, voiceFile));
    }

    await DatabaseHelper.instance.insertSubject({
      'subject_id': subjectID,
      'SubjectName': subjectName,
      'SpouseName': spouseName,
      'ChildName': childName,
      'MaritalStatus': maritalStatus,
      'Village': village,
      'IDType': idType,
      'IDNumber': idNumber,
      'Mobile': mobile,
      'Address': address,
      'Age': age,
      'Sex': sex,
      'Caste': caste,
      'Image': image,
      'Voice': voice,
      'Religion': religion,
      'Occupation': occupation,
      'Zone_ID': zoneid,
      'Email': email,
      'Relatives': relatives,
      'upload_time': 0,
    });
    _clearFields();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beneficiary Enrolled successfully'),
      ),
    );

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => FormDataTablePage(
    //         village: village, nextPage: "service registration"),
    //   ),
    // );

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FamilyDataTablePage(
              formName: globalFormName,
              village: globalVillage,
              nextPage: 'Service registration')),
    );
  }

  // void tempFun() async {
  //   Directory documentDirectory = await getApplicationDocumentsDirectory();
  //   String filename = subjectNameController.text + ".jpg";

  //   final pathutil = path.join(documentDirectory.path, filename);
  //   print(pathutil);
  //   final f = File(pathutil);
  //   final  fileContent = await f.readAsBytes();

  //   print(f);
  //   print(fileContent);
  //   setState(() {
  //     _tempimage = f;
  //   });
  //   print('executed :: : ');
  // }

  void _clearFields() {
    subjectNameController.clear();
    childNameController.clear();
    mobileController.clear();
    maritalStatusController.clear();
    villageController.clear();
    idTypeController.clear();
    idNumberController.clear();
    addressController.clear();
    spouseNameController.clear();
    ageController.clear();
    sexController.clear();
    casteController.clear();
    imageController.clear();
    voiceController.clear();
    religionController.clear();
    occupationController.clear();
    zoneidController.clear();
    emailController.clear();
    _controllers.clear();
    // _image.delete()
  }

  Widget _buildSmallTextField(
      TextEditingController controller, String labelText,
      {TextInputType? keyboardType}) {
    return SizedBox(
      width: 200,
      height: 50,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Widget _buildFormField(String labelText, TextEditingController controller,
  //     {TextInputType? keyboardType}) {
  //   return Container(
  //     margin: EdgeInsets.symmetric(
  //         vertical: 10), // Adjust vertical margin as needed
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               width: 100, // Adjust the width according to your preference
  //               child: Text(
  //                 labelText,
  //                 style: TextStyle(fontSize: 18),
  //               ),
  //             ),
  //             SizedBox(
  //               width: 20, // Adjust the space between label and text field
  //             ),
  //             Expanded(
  //               child: TextField(
  //                 controller: controller,
  //                 keyboardType: keyboardType,
  //                 decoration: InputDecoration(
  //                   isDense: true,
  //                   hintText: 'Enter $labelText',
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFormField(String labelText, TextEditingController controller,
  //     {TextInputType? keyboardType, bool isDropdown = false}) {
  //     return FutureBuilder<List<String>>(
  //       future: getStringListOfZoneID(), // Wait for the future to complete
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return const CircularProgressIndicator(); // Show loading indicator while waiting
  //         }
  //         if (snapshot.hasError) {
  //           return Text('Error: ${snapshot.error}');
  //         }
  //         final List<String>? dropdownItems = snapshot.data;
  //         return Container(
  //           margin: const EdgeInsets.symmetric(vertical: 10),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Row(
  //                 children: [
  //                   SizedBox(
  //                     width: 100,
  //                     child: Text(
  //                       labelText,
  //                       style: const TextStyle(fontSize: 18),
  //                     ),
  //                   ),
  //                   const SizedBox(
  //                     width: 20,
  //                   ),
  //                   Expanded(
  //                     child: isDropdown
  //                         ? DropdownButtonFormField<String>(
  //                             value: dropDownIndex?["zone"],
  //                             items: dropdownItems?.map((String value) {
  //                               return DropdownMenuItem<String>(
  //                                 value: value,
  //                                 child: Text(value),
  //                               );
  //                             }).toList(),
  //                             onChanged: (String? newValue) {
  //                               setState(() {
  //                                 dropDownIndex?["zone"] = newValue ?? '';
  //                                 controller.text = newValue ?? '';
  //                               });
  //                             },
  //                             decoration: InputDecoration(
  //                               isDense: true,
  //                               hintText: 'Select $labelText',
  //                               border: const OutlineInputBorder(),
  //                             ),
  //                           )
  //                         : TextField(
  //                             controller: controller,
  //                             keyboardType: keyboardType,
  //                             decoration: InputDecoration(
  //                               isDense: true,
  //                               hintText: 'Enter $labelText',
  //                               border: const OutlineInputBorder(),
  //                             ),
  //                           ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  // }

Widget _buildFormField(String labelText, TextEditingController controller,
      {TextInputType? keyboardType,
      bool isDropdown = false,
      List<String>? staticDropdownItems}) {
    Future<List<String>> getDropdownItems() async {
      if (staticDropdownItems != null) {
        return staticDropdownItems;
      } else {
        return await getStringListOfZoneID();
      }
    }

    return FutureBuilder<List<String>>(
      future: getDropdownItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show loading indicator while waiting
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final List<String>? dropdownItems = snapshot.data;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      labelText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: isDropdown
                        ? DropdownButtonFormField<String>(
                            initialValue:
                                dropdownItems?.contains(controller.text) == true
                                    ? controller.text
                                    : null,
                            items: dropdownItems?.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                dropDownIndex?["zone"] = newValue ?? '';
                                controller.text = newValue ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Select $labelText',
                              border: const OutlineInputBorder(),
                            ),
                          )
                        : TextField(
                            controller: controller,
                            keyboardType: keyboardType,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Enter $labelText',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /*Future<List<String>> getStringListOfZoneID() async {
    // List<String> stringList = ['Zone 1', 'Zone 2', 'Zone 3'];
    //await mappingOfVillageAndID();
    List<dynamic> dropDownList = DataDownloadPage.zones_allocated;
    List<String> zoneName = [];
    for (var i = 0; i < dropDownList.length; i++) {
      String villageName =
          await DataDownloadPageState.getVillageName(dropDownList[i]);
      String villageID = dropDownList[i];
      villageID2Name[villageID] = villageName;
      villageName2ID[villageName] = villageID;
      zoneName.add(villageID2Name[dropDownList[i]]);
    }
    print("zoneName");
    print(dropDownList);
    print(zoneName);
    return zoneName;
  }*/

  

  Future<List<String>> getStringListOfZoneID() async {

    List<String> zoneName = [];
    //String userid="svyVARN0000";
    String userid=LoginPage.userId;
    

    final db = await DatabaseHelper.instance.database;
    
    final List<Map<String, Object?>> result = await db.rawQuery('''
      SELECT allocateZone.zone_id, zone.name FROM allocateZone INNER JOIN Zone ON allocateZone.zone_id = Zone.zone_id 
      WHERE allocateZone.userid = ?
    ''', [userid]);

    for (var i = 0; i < result.length; i++) {
        Map<String, Object?> res=result[i];
        String villageName = res['name'].toString();
            
        String villageID = res['zone_id'].toString();
        villageID2Name[villageID] = villageName;
        villageName2ID[villageName] = villageID;
        zoneName.add(villageName);
      }

    print("zoneName");
    print(zoneName);
    print(villageID2Name);
    print(villageName2ID);

    return zoneName;
  }

  Widget _buildDropdownWidget() {

//String? dropDownIndex;
    //dropDownIndex?[question]='';
     //List<String> options_list=['One', 'Two', 'Free', 'Four'];
     //dropDownList=options_list;
      List<dynamic> dropDownList= ["General", "OBC (Creamy Layer)", "OBC (Non Creamy Layer)","Schedule Caste","Schedule Tribe","Not Stated"];
      return DropdownButton(
        
     icon: const Icon(Icons.expand_circle_down),
     elevation: 16,
     dropdownColor: Colors.white,
     hint: const Text("select"),
     enableFeedback: true,
     iconSize: 16,
     borderRadius: BorderRadius.circular(16),
     style: const TextStyle(color: Colors.deepPurple),
     underline: Container(
      height: 2,
      color: Colors.deepPurpleAccent,
     ),     
  items: dropDownList.map((value) => DropdownMenuItem(value: value,child: Text(value),)).toList(),
  onChanged: (dynamic index) {
      setState(() {
        //dropDownIndex[question] = index;
        if(index!=null)
        {
          
          setState(() {
            dropDownIndex?["zone"] = index;
          zoneidController.text=index;  
          });
          }
        //responses[question] = index;
        
        print('Selected Option : $index');
      });
  },
  value: dropDownIndex?["zone"],
      );
    }

  @override
  Widget build(BuildContext context) {
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
        pageTitles: const ['Home', 'Log out', 'Bandwidth'],
      ),
      appBar: AppBar(
        title: const Text('Beneficiary Enrollment Page'),
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Enroll New Beneficiary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField('Beneficiary Name*', subjectNameController),
                  _buildFormField('Spouse Name', spouseNameController),
                  _buildFormField('Child Name', childNameController),
                  _buildFormField('Marital Status', maritalStatusController,
                  isDropdown: true, staticDropdownItems: ["Married","Unmarried","Other"]),
                  //_buildFormField('Village', villageController),
                  _buildFormField('ID Type', idTypeController),
                  _buildFormField('ID Number', idNumberController),
                  _buildFormField('Mobile', mobileController,
                      keyboardType: TextInputType.phone),
                  _buildFormField('Address', addressController),
                  _buildFormField('Age', ageController,
                      keyboardType: TextInputType.number),
                  _buildFormField('Sex', sexController,
                  isDropdown: true, staticDropdownItems: ["Male","Female","Others"]),
                  // _buildFormField('Caste', casteController),
                  _buildFormField('Caste', casteController,
                      isDropdown: true, staticDropdownItems: ["General", "OBC (Creamy Layer)", "OBC (Non Creamy Layer)","Schedule Caste","Schedule Tribe","Not Stated"]),
                  // _buildFormField('Image', imageController),
                  // _buildFormField('Voice', voiceController),
                  _buildFormField('Religion', religionController,
                  isDropdown: true, staticDropdownItems: ["Hinduism","Buddhism","Christianity","Islam","Jainism","Sikhism","Other"]),
                  _buildFormField('Occupation', occupationController),
                  //_buildFormField('Occupation', occupationController),
                  _buildFormField('Village Name*', zoneidController,
                      isDropdown: true),
                  //_buildFormField('Zone ID', zoneidController),
                  //_buildDropdownWidget(),
                  _buildFormField('Email', emailController,
                      keyboardType: TextInputType.emailAddress),
                  //
                  // Text(
                  //   'Relatives',
                  //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  // ),
                  const SizedBox(height: 8),
                  Column(
                    children: _controllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Relative ${index + 1}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                onChanged: (value) {
                                  // Check if the last text field is not empty and the limit is not reached, then add a new one
                                  if (_controllers.length < 5 &&
                                      index == _controllers.length - 1 &&
                                      value.isNotEmpty) {
                                    setState(() {
                                      _controllers.add(TextEditingController());
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Enter name',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     List<String> names = _controllers
                  //         .map((controller) => controller.text.trim())
                  //         .where((name) => name.isNotEmpty)
                  //         .toList();
                  //     // Join the list of names with a delimiter (comma in this case)
                  //     String namesString = names.join(', ');
                  //     // Use the 'namesString' variable where you need it
                  //     print(namesString);
                  //   },
                  //   child: Text('Submit'),
                  // ),
                  //
                  _image == null
                      ? const Text('No image selected.')
                      : Text('Image_${subjectNameController.text}'),
                  // Image.file(
                  //     _image!,
                  //     height: 100,
                  //     width: 100,
                  //   ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _getImageFromCamera,
                    child: const Text("Take a Picture"),
                  ),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: showPlayer
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: AudioPlayer(
                                source: audioPath!,
                                onDelete: () {
                                  setState(() => showPlayer = false);
                                },
                              ),
                            )
                          : Recorder(
                              onStop: (path) {
                                print('Recorded file path: $path');
                                setState(() {
                                  audioPath = path;
                                  showPlayer = true;
                                });
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      addSubject();
                    },
                    icon: const Icon(Icons.person, size: 30),
                    label: const Text('Register Beneficiary'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
