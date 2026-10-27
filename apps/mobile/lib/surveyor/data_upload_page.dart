import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_001/backend/database_helper.dart';
import 'package:app_001/log/logger.dart';
import 'package:app_001/login_page.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:app_001/main.dart';

class DataUploadPage extends StatefulWidget {
  const DataUploadPage({super.key});

  @override
  State<DataUploadPage> createState() => DataUploadPageState();
}

class DataUploadPageState extends State<DataUploadPage> {
  @override
  void initState() {
    super.initState();
  }

  static Future<File?> compressImage(String filename) async {
    if (kIsWeb) return null;
    try {
      Directory documentDirectory = await getApplicationDocumentsDirectory();

      var result = await FlutterImageCompress.compressAndGetFile(
        path.join(documentDirectory.path, filename),
        path.join(documentDirectory.path, "comp_$filename"),
        quality: 80,
      );
      if (result == null) return null;
      final res = File(result.path);
      print('compressed length : ${res.lengthSync()}');
      return res;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  static Future<void> uploadBeneficiaryDetails() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/create-subject-new";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getSubjectDetailstoUpload();
    // print(data);
    for (var subject in data) {
      // print(subject);
      Map<String, dynamic> payload = subject;
      Directory documentDirectory = await getApplicationDocumentsDirectory();
      String pathutil = path.join(documentDirectory.path, subject['Image']);
      print('pathutil: $pathutil');
      String base64Image = "";
      String base64Voice = "";
      String base64CompressedImage = "";
      if (!kIsWeb) {
        Directory documentDirectory = await getApplicationDocumentsDirectory();
        String pathutil = path.join(documentDirectory.path, subject['Image']);
        print('pathutil: $pathutil');
        if (await File(pathutil).exists()) {
          print('base64 ');
          final file = File(pathutil).readAsBytes();
          final compressedImage = await compressImage(subject['Image']);

          base64Image = base64Encode(await File(pathutil).readAsBytes());
          if (compressedImage != null) {
            base64CompressedImage =
                base64Encode(await compressedImage.readAsBytes());
          } else {
            base64CompressedImage = base64Image;
          }
          print('${base64Image.length}, ${base64CompressedImage.length}');
        }
        String pathutilVoice = path.join(documentDirectory.path, subject['Voice']);
        if (await File(pathutilVoice).exists()) {
          base64Voice = base64Encode(await File(pathutilVoice).readAsBytes());
        }
      }
      // print(payload);
      // print('object');
      String jsonPayload = jsonEncode({
        "subjectname": payload['SubjectName'],
        "spousename": payload['SpouseName'],
        "childname": payload['ChildName'],
        "maritalstatus": payload['MaritalStatus'],
        "village": payload['Village'],
        "idtype": payload['IDType'],
        "idnumber": payload['IDNumber'],
        "age": payload['Age'],
        "sex": payload['Sex'],
        "caste": payload['Caste'],
        "religion": payload['Religion'],
        // "image": base64Image,
        "image": base64CompressedImage,
        "voice": base64Voice,
        "occupation": payload['Occupation'],
        "zone_id": payload['Zone_ID'],
        "address": payload['Address'],
        "mobile": payload['Mobile'],
        "email": payload['Email']
      });
      // print(jsonPayload);
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
        uploadBeneficiaryDetailsCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        final flag = await databaseHelper
            .updateSubjectDetailsAfterUpload(subject['subject_id']);
        log.info('Response : $json\nLocal Update flag : $flag');
        print(flag);
        final flag1 = await databaseHelper.updateSubjectId(
            subject['subject_id'], json['subject_id']);
        // log.info('Update flag1 : $flag1');
        // print(flag1);
      } else {
        print('failed');
      }
    }
  }

  static Future<void> uploadResponsesUtil() async {
    await uploadResponses();
    await uploadUpdatedResponses();
    print("Uploaded response");
    await uploadFieldEntries();
    await uploadUpdatedFieldEntries();
    
    
    //await uploadUpdatedFieldEntries();
  }

  static Future<void> uploadResponses() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/create-record-log";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getRecordLogstoUpload();
    // print(data);
    for (var row in data) {
      print(row);
      // add voice and image
      Directory documentDirectory = await getApplicationDocumentsDirectory();
      String pathutil = path.join(documentDirectory.path, row['image']);
      String image = "";
      String compImage = "";
      // payload['Image'] = "";
      if (await File(pathutil).exists()) {
        image = base64Encode(await File(pathutil).readAsBytes());
        final compressedImageutil = await compressImage(row['image']);
        if (compressedImageutil != null) {
          compImage = base64Encode(await File(pathutil).readAsBytes());
        } else {
          compImage = image;
        }
      }
      String voice = "";
      if (!kIsWeb) {
        Directory documentDirectory = await getApplicationDocumentsDirectory();
        String pathutil = path.join(documentDirectory.path, row['image']);
        if (await File(pathutil).exists()) {
          image = base64Encode(await File(pathutil).readAsBytes());
          final compressedImageutil = await compressImage(row['image']);
          if (compressedImageutil != null) {
            compImage = base64Encode(await File(pathutil).readAsBytes());
          } else {
            compImage = image;
          }
        }
        String pathutilVoice = path.join(documentDirectory.path, row['voice']);
        if (await File(pathutilVoice).exists()) {
          voice = base64Encode(await File(pathutilVoice).readAsBytes());
        }
      }
      String jsonPayload = jsonEncode({
        "subject_id": row['subject_id'],
        "survey_data": row['survey_data'],
        "record_type": row['record_type'],
        "sid": row['sid'],
        // "image": image,
        "image": compImage,
        "voice": voice,
        "userid": row["userid"],
        "username": row["username"],
      });
      // print(jsonPayload);
      log.info('url : $url, json payload : $jsonPayload');
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonPayload,
      );
      // print(row['survey_data'].runtimeType);
      if (response.statusCode == 200) {
        uploadResponsesUtilCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        log.info('Response : $json');
        final flag =
            await databaseHelper.updateRecordLogAfterUpload(row['rid']);
        log.info('flag : $flag');
        await databaseHelper.updateRecordLogID(row['rid'], json['rid']);
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
  }


  static Future<void> uploadUpdatedResponses() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/update-record-log";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getUpdatedRecordLogstoUpload();
    // print(data);
    for (var row in data) {
      print(row);
      
      String jsonPayload = jsonEncode({
        "survey_data": row['survey_data'],
        "rid": row['rid'],
      });
      // print(jsonPayload);
      log.info('url : $url, json payload : $jsonPayload');
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonPayload,
      );
      print("uploadUpdatedResponses  : "'Response : ${response.statusCode}');
        // print(flag);
      // print(row['survey_data'].runtimeType);
      if (response.statusCode == 200) {
        uploadResponsesUtilCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        log.info('Response : $json');
        final flag =
            await databaseHelper.updateRecordLogAfterUpload(row['rid']);
        log.info('flag : $flag');
        await databaseHelper.updateRecordLogID(row['rid'], json['rid']);

        print("uploadUpdatedResponses  : "'Response : $json\nLocal Update : $flag');
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
  }

  static Future<void> uploadFieldEntries() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/create-field-entry";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getFieldEntriestoUpload();
    for (var entry in data) {
      Map<String, dynamic> payload = entry;
      print(payload);
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
        uploadResponsesUtilCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        final flag =
            await databaseHelper.updateFieldEntryAfterUpload(entry['id']);
        log.info('Response : $json\nLocal Update : $flag');
      } else {}
    }
  }

  static Future<void> uploadUpdatedFieldEntries() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/update-field-entry";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getUpdatedFieldEntriestoUpload();
    for (var entry in data) {
      Map<String, dynamic> payload = entry;
      print(payload);
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
        uploadResponsesUtilCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        final flag =
            await databaseHelper.updateFieldEntryAfterUpload(entry['id']);
        log.info('Response : $json\nLocal Update : $flag');
        print("uploadUpdatedFieldEntries  : "'Response : $json\nLocal Update : $flag');
      } else {}
    }
  }

  static Future<void> uploadServiceEnrollment() async {
    String url =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/create-serviceEnrollment-new";
    final databaseHelper = DatabaseHelper.instance;
    final data = await databaseHelper.getServiceEnrollmentstoUpload();
    print(data);
    for (var row in data) {
      Map<String, dynamic> payload = row;
      String jsonPayload = jsonEncode({
        "service_id": payload['service_id'],
        "subject_id": payload['subject_id'],
        "sid": payload['sid'],
        "start_date": payload['start_date'],
        "end_date": payload['end_date'],
      });
      print(jsonPayload);
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
        uploadServiceEnrollmentCount+=1;
        var json = jsonDecode(response.body);
        print(json);
        final flag =
            await databaseHelper.updateServiceEnrollmentAfterUpload(row['id']);
        log.info('Response : $json\nLocal Update Flag : $flag');
        print(flag);
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //         'Error Connecting to the server : ${response.statusCode}!!!'),
        //   ),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await uploadBeneficiaryDetails();
              },
              child: const Text('Upload new Beneficiaries'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await uploadResponsesUtil();
              },
              child: const Text('Upload responses'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await uploadServiceEnrollment();
              },
              child: const Text('Upload service enrollment'),
            ),
            const SizedBox(height: 20),
            ///////////////////////////////////////////////////////
          ],
        ),
      ),
    );
  }
}
