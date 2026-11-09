import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mdosthi_app/backend/database_helper.dart';
import 'package:mdosthi_app/log/logger.dart';
import 'package:mdosthi_app/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DataDownloadPage extends StatefulWidget {
  const DataDownloadPage({super.key});
  static List<dynamic> zones_allocated = [],
      forms_allocated = [],
      services_available = [];

  @override
  State<DataDownloadPage> createState() => DataDownloadPageState();
}

class DataDownloadPageState extends State<DataDownloadPage> {
  @override
  void initState() {
    super.initState();
  }
  static Future<void> reLogin() async
  {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/login";
    print(url);
    Map<String, dynamic> payload = {"username": LoginPage.username, "password": LoginPage.password};
    String jsonPayload = jsonEncode(payload);
    const int timeoutDuration = 10;

    final db = DatabaseHelper.instance;
    try {
      // Log message before API call
      // logMessage('Attempting login...');
      var response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: timeoutDuration));

      if (response.statusCode == 200) {
        // logMessage('Login successful!');

        // if (newUsername.isNotEmpty && !userNamesList.contains(newUsername))
        
        
        
        var json = jsonDecode(response.body);
        String userType = "";
        LoginPage.jwtToken = json["jwtToken"];
        // setState(() {
        //   LoginPage.jwtToken = json["jwtToken"];
          
        // });

    }
    
    } catch (e) {}

  }

  static Future<void> download_villages() async {
    // final databaseHelper = DatabaseHelper.instance;
    // await databaseHelper.check_service_enrollment();
    await getAllocatedZone();
    for (String zone in DataDownloadPage.zones_allocated) {
      await getZoneInfo(zone);
    }
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Successfully Downloaded Villages'),
    //   ),
    // );
  }

  static Future<void> getAllocatedZone() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-allocated-zone";
    Map<String, dynamic> payload = {"userid": LoginPage.userId};
    String jsonPayload = jsonEncode(payload);
    log.info('url : $url, json payload : $jsonPayload');
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      DataDownloadPage.zones_allocated.clear();

      var json = jsonDecode(response.body);
      // setState(() {
      DataDownloadPage.zones_allocated = json['zone-id'];
      // });

      List<dynamic> zoneIdList = json['zone-id'];
      for(var iterator in zoneIdList){
        print(iterator);
        final c = await DatabaseHelper.instance.insertAllocatedZone({
        'zone_id': iterator,
        'userid': LoginPage.userId        
      });
      print('done : $c');
      }



    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getZoneInfo(String zone) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-zone-info";
    Map<String, dynamic> payload = {"zone_id": zone};
    String jsonPayload = jsonEncode(payload);
    log.info('url : $url, json payload : $jsonPayload');

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // print(json);
      final databaseHelper = DatabaseHelper.instance;
      int flag = await databaseHelper.storeTheZones(json['zone-info']);
      // print('$flag');
      log.info('Status : $flag');
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  //static Future<void> download_forms() async {
  //  await getAllocatedSurveyorForms();
  //  for (String surveyId in DataDownloadPage.forms_allocated) {
  //    await getSurveyInfo(surveyId);
  //    await getFieldInfo(surveyId);
  //  }
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Successfully Downloaded forms'),
    //   ),
    // );
  //}

  static Future<void> download_forms() async {
  await reLogin();  // Reuse your existing reLogin method
  
  String url = "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-all-forms";
  print('Downloading forms from: $url');
  
  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      
      if (json['status'] == 'success') {
        final databaseHelper = DatabaseHelper.instance;
        
        // Clear existing forms if needed
        // await databaseHelper.clearSurveyForms();
        
        for (var form in json['forms']) {
          await databaseHelper.storeTheSurveyForms({
            'name': form['name'],
            'sid': form['sid'],
            'creation_date': form['creation_date'],
            'description': form['description'],
            'template_source': form['template_source'],
            'details_source': form['details_source'],
            'upload_time': "1"  // Mark as synced
          });
        }
        print('Forms downloaded and stored successfully');
      } else {
        print('Error from server: ${json['message']}');
      }
    } else {
      print('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading forms: $e');
    rethrow;  // Rethrow to handle in UI
  }
}


  static Future<void> getAllocatedSurveyorForms() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-allocate-surveyor";
    Map<String, dynamic> payload = {"userid": LoginPage.userId};
    String jsonPayload = jsonEncode(payload);
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      DataDownloadPage.forms_allocated.clear();
      var json = jsonDecode(response.body);
      // setState(() {
      DataDownloadPage.forms_allocated = json['survey-ids'];
      // });
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
      // print('Error Connecting to the server : ${response.statusCode}');
    }
  }

  static Future<void> getSurveyInfo(String surveyId) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-survey-info";
    Map<String, dynamic> payload = {"sid": surveyId};
    String jsonPayload = jsonEncode(payload);
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      final databaseHelper = DatabaseHelper.instance;
      json['survey-info']['upload_time'] = "1";
      int flag = await databaseHelper.storeTheSurveyForms(json['survey-info']);
      // print(flag);
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getFieldInfo(String surveyId) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-FieldProject-info";
    Map<String, dynamic> payload = {"sid": surveyId};
    String jsonPayload = jsonEncode(payload);
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // print(json['FieldProject-info']);
      final databaseHelper = DatabaseHelper.instance;
      for (var element in json['FieldProject-info']) {
        element['upload_time'] = "1";
        var flag = await databaseHelper.insertFieldUtil(element);
        // print(flag);
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getSubjects() async {
    for (String zone in DataDownloadPage.zones_allocated) {
      await getBeneficiariesByZone(zone);
    }
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Successfully Downloaded Beneficiaries'),
    //   ),
    // );
  }

  static Future<void> saveFile(String base64File, String fileName) async {
    if (kIsWeb) return;
    List<int> imageBytes = base64.decode(base64File);
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String pathutil = join(documentDirectory.path, fileName);
    File file = File(pathutil);
    file.writeAsBytesSync(imageBytes);
  }

  static Future<String> getVillageName(String zoneID) async {
    String zoneName = '';
    final databaseHelper = DatabaseHelper.instance;
    List<Map<String, Object?>> villageList =
        await databaseHelper.getVillagefromZoneID(zoneID);

    // Parse the list of maps
    for (var item in villageList) {
      if (item['name'] != null && item['name'] is String) {
        zoneName += (item['name'] as String);
      }
    }
    return zoneName;
  }


  static Future<void> getBeneficiariesByZone(String zone) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-SubjectInfo-ByZone";
    Map<String, dynamic> payload = {"zone_id": zone};
    String jsonPayload = jsonEncode(payload);
    // print('the payload is $payload');
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      final databaseHelper = DatabaseHelper.instance;
      // print('the json data is $json');
      for (var subject in json['subject-log']) {
        // print('subject is $subject');
        if (subject['image'] != null &&
            subject['image'] != 'image' &&
            !subject['image'].endsWith(".jpg")) {
          saveFile(subject['image'], subject['subject_id'] + ".jpg");
        }
        if (subject['voice'] != null &&
            subject['voice'] != 'voice' &&
            !subject['voice'].endsWith(".mp3")) {
          saveFile(subject['voice'], subject['subject_id'] + '.mp3');
        }
        int flag = await databaseHelper.insertSubjectUtil({
          "subject_id": subject["subject_id"],
          "SubjectName": subject["subjectname"],
          "SpouseName": subject["spousename"],
          "ChildName": subject["childname"],
          "MaritalStatus": subject["maritalstatus"],
          "Village": subject["village"],
          "IDType": subject["idtype"],
          "IDNumber": subject["idnumber"],
          "Age": subject["age"],
          "Sex": subject["sex"],
          "Caste": subject["caste"],
          "Religion": subject["religion"],
          "Image": subject['subject_id'] + ".jpg",
          "Voice": subject['subject_id'] + ".mp3",
          "Occupation": subject["occupation"],
          "Zone_ID": subject["zone_id"],
          "Address": subject["address"],
          "Mobile": subject["mobile"],
          "Email": subject["email"],
          "upload_time": 1
        });
        // print(flag);
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getAllServices() async {
    await getServicesList();
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Successfully Downloaded Services'),
    //   ),
    // );
  }

  static Future<void> getServicesList() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-all-services";
    Map<String, dynamic> payload = {};
    String jsonPayload = jsonEncode(payload);
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // print(json['service-log']);
      final databaseHelper = DatabaseHelper.instance;
      for (var service in json['service-log']) {
        service['upload_time'] = "1";
        print('service is $service');
        int flag = await databaseHelper.insertServiceUtil(service);
        // print(service);
        // print(flag);
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //         'Error Connecting to the server : ${response.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getAllResponses() async {
    final databaseHelper = DatabaseHelper.instance;
    final subjects = await databaseHelper.getSubjectsSids();
    // print(subjects);
    String lastDate =
        await databaseHelper.getUpdateLastestDownloadUploadTime('download');

    for (var subject in subjects) {
      print('subject is : ${subject['subject_id']}');
      if (lastDate == "") { 
        await getResponseOfASubject(subject['subject_id']);
      }
      else{
        getResponseOfASubjectByInstanceTime(subject['subject_id'], lastDate);
      }
    }
    // await databaseHelper.check_responses_to_upload();
  }

  static Future<void> getResponseOfASubject(String subjectID) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-RecordLog-BySubjectId";
    Map<String, dynamic> payload = {"subject_id": subjectID};
    String jsonPayload = jsonEncode(payload);
    var result = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    final databaseHelper = DatabaseHelper.instance;
    if (result.statusCode == 200) {
      var json = jsonDecode(result.body);
      // print('json response is : $json');
      for (var response in json['record-log']) {
        print(response);
        // response['upload_time'] = "1";
        // response['InstanceTime'] = response['instance_time'];
         if (response['image'] != null &&
            response['image'] != 'image' &&
            !response['image'].endsWith(".jpg")) {
           saveFile(response['image'], "${"rid_"+response['rid']}.jpg");
         }
        if (response['voice'] != null &&
            response['voice'] != 'voice' &&
            !response['voice'].endsWith(".mp3")) {
          saveFile(response['voice'], '${"rid_"+response['rid']}.mp3');
        }
        int flag = await databaseHelper.insertResponseUtil({
          "rid": response['rid'],
          "subject_id": response['subject_id'],
          "survey_datetime": response['survey_datetime'],
          "sid": response['sid'],
          "image": "${"rid_"+response['rid']}.jpg",
          "voice": "${"rid_"+response['rid']}.mp3",
          "record_type": response['record_type'],
          "survey_data": response['survey_data'],
          "userid": response['userid'],
          "username": response['username'],
          "InstanceTime": response['instance_time'],
          "upload_time": 1,
        });
        // print(flag);
        final surveyData = jsonDecode(response['survey_data']);
        // print(survey_data);
        // print('recordLogbysubjectid $flag');

        surveyData.forEach((key, value) {
          getFieldEntriesOfASubject(key, response['rid']);
        });
        // for (var entry in survey_data) {
        //   print(entry);
        // }
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content:
      //         Text('Error Connecting to the server : ${result.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getResponseOfASubjectByInstanceTime(
      String subjectID, String lastDate) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-RecordLog-BySubjectId-InstanceTime";
    Map<String, dynamic> payload = {
      "subject_id": subjectID,
      "InstanceTime": lastDate
    };
    String jsonPayload = jsonEncode(payload);
    var result = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    final databaseHelper = DatabaseHelper.instance;
    if (result.statusCode == 200) {
      var json = jsonDecode(result.body);
      // print('json response is : $json');
      for (var response in json['record-log']) {
        print(response);
        // response['upload_time'] = "1";
        // response['InstanceTime'] = response['instance_time'];
        if (response['image'] != null &&
            response['image'] != 'image' &&
            !response['image'].endsWith(".jpg")) {
          saveFile(response['image'], "${"rid_" + response['rid']}.jpg");
        }
        if (response['voice'] != null &&
            response['voice'] != 'voice' &&
            !response['voice'].endsWith(".mp3")) {
          saveFile(response['voice'], '${"rid_" + response['rid']}.mp3');
        }
        int flag = await databaseHelper.insertResponseUtil({
          "rid": response['rid'],
          "subject_id": response['subject_id'],
          "survey_datetime": response['survey_datetime'],
          "sid": response['sid'],
          "image": "${"rid_" + response['rid']}.jpg",
          "voice": "${"rid_" + response['rid']}.mp3",
          "record_type": response['record_type'],
          "survey_data": response['survey_data'],
          "userid": response['userid'],
          "username": response['username'],
          "InstanceTime": response['instance_time'],
          "upload_time": 1,
        });
        // print(flag);
        final surveyData = jsonDecode(response['survey_data']);
        // print(survey_data);
        // print('recordLogbysubjectid $flag');

        surveyData.forEach((key, value) {
          getFieldEntriesOfASubject(key, response['rid']);
        });
        // for (var entry in survey_data) {
        //   print(entry);
        // }
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content:
      //         Text('Error Connecting to the server : ${result.statusCode}!!!'),
      //   ),
      // );
    }
  }

  static Future<void> getFieldEntriesOfASubject(String fid, String rid) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-FieldEntries-Value";
    Map<String, dynamic> payload = {
      "fid": fid,
      "rid": rid,
    };
    String jsonPayload = jsonEncode(payload);
    var result = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (result.statusCode == 200) {
      var json = jsonDecode(result.body);
      // print('entry : $json');
      final databaseHelper = DatabaseHelper.instance;
      int flag = await databaseHelper.insertFiedEntryUtil({
        "rid": rid,
        "fid": fid,
        "value": json['value'],
        "upload_time": 1,
      });
      // print('fieldEntry $flag');
      // print(flag);
    } else {}
  }

  static Future<void> getAllServiceEnrollments() async {
    final databaseHelper = DatabaseHelper.instance;
    List<String> services = await databaseHelper.getAllServices_serivce_id();
    for (String service_id in services) {
      getServiceEnrollmentList(service_id);
    }
  }

  static Future<void> getServiceEnrollmentList(String serviceId) async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-AllServiceEnrollment-byServiceId";

    Map<String, dynamic> payload = {
      "service_id": serviceId,
    };
    String jsonPayload = jsonEncode(payload);
    var result = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonPayload,
    );
    if (result.statusCode == 200) {
      var json = jsonDecode(result.body);
      // print('entry : $json');
      final databaseHelper = DatabaseHelper.instance;
      for (var row in json['service-enrollment-logs']) {
        row['upload_time'] = 1;
        var flag = await databaseHelper.serviceEnrollementofSubject(row);
        // print('serviceEnrollmentList $flag');
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Download'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await download_villages();
                // DatabaseHelper.instance.checkZones();
                // print('Download Villages');
              },
              child: const Text('Download Villages'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await download_forms();
              },
              child: const Text('Download Forms'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await getSubjects();
                // DatabaseHelper.instance.checkSubjects();
                // print('Download Beneficiaries');
              },
              child: const Text('Download Beneficiaries'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await getAllServices();
                // print('Download Services');
              },
              child: const Text('Download Services'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await getAllResponses();
              },
              child: const Text('Download Responses'),
            ),
          ],
        ),
      ),
    );
  }
}
