import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:app_001/log/logger.dart';
import 'package:app_001/login_page.dart';
import 'package:app_001/surveyor/family_details.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class Survey {
  final String name;
  final String description;
  final String templateSource;
  final String sid;

  Survey({
    required this.name,
    required this.description,
    required this.templateSource,
    required this.sid,
  });
}

class FormField {
  final String name;
  final String attributeType;
  final String attributeUnit;
  final bool isRequired;

  FormField({
    required this.name,
    required this.attributeType,
    required this.attributeUnit,
    required this.isRequired,
  });
}

class Field {
  final String name;
  final String attributeType;
  final String attributeUnit;
  final bool isRequired;

  Field({
    required this.name,
    required this.attributeType,
    required this.attributeUnit,
    required this.isRequired,
  });
}

class DatabaseHelper {
  // Define the table names and column names
  static const String surveyProjectTable = 'survey_project';
  static const String fieldProjectTable = 'field_project';

  // Define column names for the survey_project table
  static const String surveyName = 'Name';
  static const String surveyId = 'sid';
  static const String creationDate = 'creation_date';
  static const String description = 'Description';
  static const String templateSource = 'template_source';

  // Define column names for the field_project table
  static const String fieldName = 'Name';
  static const String fieldId = 'fid';
  static const String surveyIdFk = 'sid';
  static const String attributeName = 'attribute_name';
  static const String attributeDatatype = 'attribute_datatype';
  static const String attributeUnit = 'attribute_unit';
  static const String requiredValue = 'required_value';
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  Database? _database;
  String? _currentUserId;
  static bool _isDatabaseFactoryInitialized = false;

  Future<Database> get database async {
    if (_database != null && _currentUserId == LoginPage.userId) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    print("In database_helper.dart initdatabase function");
    if (!_isDatabaseFactoryInitialized) {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _isDatabaseFactoryInitialized = true;
    }

    if (_database != null && _currentUserId == LoginPage.userId) {
      return _database!;
    }

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    String path;
    if (kIsWeb) {
      path = '${LoginPage.userId}.db';
    } else {
      final dbpath = await getDatabasesPath();
      print('database path : $dbpath');
      path = join(dbpath, '${LoginPage.userId}.db');
    }
    print('final path : $path');
    _database = await openDatabase(path, version: 1, onCreate: _createDb);
    _currentUserId = LoginPage.userId;
    return _database!;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _currentUserId = null;
    }
  }

  Future<bool> _isTableExists(Database db, String tableName) async {
    final result = await db.rawQuery('''
    SELECT name FROM sqlite_master WHERE type='table' AND name=?
  ''', [tableName]);
    return result.isNotEmpty;
  }

  Future<void> clearSurveyForms() async {
  final db = await database;
  await db.delete('survey_project');
  }


  Future<void> _createDb(Database db, int version) async {
    
    print("In database_helper.dart _createdb function");

    await db.execute('''
          CREATE TABLE allocateZone (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id TEXT,
            userid TEXT,
            FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
            FOREIGN KEY (userid) REFERENCES users(Userid)
          )
        ''');
    print('created allocateZone');

    await db.execute('''
      CREATE TABLE login (
        loginid TEXT PRIMARY KEY,
        password TEXT,
        name TEXT,
        user_type TEXT,
        userid TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE users (
        Name TEXT,
        Userid TEXT PRIMARY KEY,
        Password TEXT,
        Age INTEGER,
        Sex TEXT,
        Center_code TEXT,
        User_Type TEXT,
        Address TEXT,
        Mobile TEXT UNIQUE,
        Email TEXT UNIQUE,
        Instance_time TEXT
      )
    ''');
    await db.execute('''
          CREATE TABLE Zone (
            name TEXT,
            zone_id TEXT PRIMARY KEY,
            type TEXT,
            latitude DOUBLE,
            longitude DOUBLE,
            area TEXT,
            population TEXT,
            police_station TEXT,
            town TEXT,
            district TEXT,
            state TEXT,
            pin_code TEXT,
            instance_time TIME DEFAULT CURRENT_TIME
          )
        ''');
    print('created Zone Table');

    await db.execute('''
          CREATE TABLE Subject (
            subject_id TEXT PRIMARY KEY,
            SubjectName TEXT, 
            SpouseName TEXT,
            ChildName TEXT,
            MaritalStatus TEXT,
            Village TEXT,
            IDType TEXT,
            IDNumber TEXT,
            Mobile TEXT,
            Address TEXT,
            Age INTEGER,
            Sex TEXT,
            Caste TEXT,
            Image TEXT,
            Voice TEXT,
            Religion Text,
            Occupation TEXT,
            Zone_ID TEXT,
            Email TEXT,
            Relatives TEXT,
            Instance_time TIME DEFAULT CURRENT_TIME,
            upload_time TEXT
          )
        ''');

    await db.execute('''
          CREATE TABLE survey_project (
            name TEXT,
            sid TEXT PRIMARY KEY,
            creation_date DATE  DEFAULT CURRENT_DATE,
            description TEXT,
            template_source TEXT,
            details_source TEXT,
            instance_time TIME DEFAULT CURRENT_TIME,
            upload_time TEXT
          )
        ''');

    await db.execute('''
          CREATE TABLE field_project (
            name TEXT,
            fid TEXT PRIMARY KEY,
            sid TEXT,
            source_type INTEGER,
            attribute_name TEXT,
            attribute_datatype TEXT,
            attribute_unit TEXT,
            attribute_values TEXT,
            required_value INTEGER,
            InstanceTime TIME DEFAULT CURRENT_TIME,
            upload_time TEXT,
            FOREIGN KEY (sid) REFERENCES survey_project(sid)
          )
        ''');

    await db.execute('''
          CREATE TABLE record_log (
            rid TEXT PRIMARY KEY,
            subject_id TEXT,
            survey_datetime DATETIME,
            sid INTEGER,
            image TEXT,
            voice TEXT,
            record_type INTEGER,
            survey_data TEXT,
            userid TEXT,
            username TEXT,
            InstanceTime TIME DEFAULT CURRENT_TIME,
            upload_time TEXT,
            FOREIGN KEY (sid) REFERENCES survey_project(sid),
            FOREIGN KEY (subject_id) REFERENCES Subject(subject_id),
            FOREIGN KEY (userid) REFERENCES users(Userid)
          )
        ''');

    await db.execute('''
          CREATE TABLE field_entry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rid TEXT,
            fid TEXT,
            value TEXT,
            InstanceTime TIME DEFAULT CURRENT_TIME,
            upload_time TEXT,
            FOREIGN KEY (rid) REFERENCES record_log(rid),
            FOREIGN KEY (fid) REFERENCES field_project(fid)
          )
        ''');

    await db.execute('''
      CREATE TABLE service (
            service_id TEXT PRIMARY KEY,
            sname TEXT,
            description TEXT,
            sid TEXT, 
            upload_time TEXT,
            FOREIGN KEY (sid) REFERENCES survey_project(sid)
          )
      ''');

    await db.execute('''
          CREATE TABLE service_enrollment (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_id TEXT,
            subject_id TEXT,
            sid TEXT,
            start_date TEXT,
            end_date TEXT,
            upload_time TEXT,
            FOREIGN KEY (subject_id) REFERENCES Subject(subject_id),
            FOREIGN KEY (sid) REFERENCES survey_project(sid),
            FOREIGN KEY (service_id) REFERENCES service(service_id)
          )
        ''');
    print('created service_enrollment');

    // await db.execute('''
    //       CREATE TABLE allocateZone (
    //         id INTEGER PRIMARY KEY AUTOINCREMENT,
    //         zone_id TEXT,
    //         userid TEXT,
    //         FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
    //         FOREIGN KEY (userid) REFERENCES users(Userid)
    //       )
    //     ''');
    // print('created allocateZone');

    await db.execute('''
          CREATE TABLE lastest_download_upload_time (
            operation_type TEXT PRIMARY KEY,
            date_time TEXT
          )
        ''');
        print('!!!!!!!!!!!!!!!!!!!!!!!!!!!lastest_download_upload_time');

    await db.execute('''
        INSERT INTO lastest_download_upload_time(operation_type,date_time) VALUES("upload","")
      ''');

    await db.execute('''
        INSERT INTO lastest_download_upload_time(operation_type,date_time) VALUES("download","")
      ''');



    


   

  

    // await db.execute('''
    //       CREATE TABLE survey_project_upload (
    //         sid TEXT PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (sid) REFERENCES survey_project(sid),
    //       )
    //     ''');
    // await db.execute('''
    //       CREATE TABLE field_project_upload (
    //         fid TEXT PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (fid) REFERENCES field_project(fid),
    //       )
    //     ''');

    // await db.execute('''
    //       CREATE TABLE services_enrollment_upload (
    //         id INTEGER PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (id) REFERENCES service_enrollment(id),
    //       )
    //     ''');
    // await db.execute('''
    //       CREATE TABLE subject_upload (
    //         subject_id TEXT PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (subject_id) REFERENCES Subject(subject_id),
    //       )
    //     ''');

    // await db.execute('''
    //       CREATE TABLE responses_upload (
    //         rid TEXT PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (rid) REFERENCES record_log(rid),
    //       )
    //     ''');

    // await db.execute('''
    //       CREATE TABLE field_entry_upload (
    //         id INTEGER PRIMARY KEY,
    //         upload_time TEXT,
    //         FOREIGN KEY (id) REFERENCES field_entry(id),
    //       )
    //     ''');
  }

  // Insert a new question
  Future<int> insertQuestion(Map<String, dynamic> question) async {
    final db = await database;
    return await db.insert('questions', question);
  }

  // Update an existing question
  Future<int> updateQuestion(
      int id, Map<String, dynamic> updatedQuestion) async {
    final db = await database;
    return await db
        .update('questions', updatedQuestion, where: 'id = ?', whereArgs: [id]);
  }

  // Delete a question
  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // Retrieve all questions
  Future<List<Map<String, dynamic>>> getQuestions() async {
    final db = await database;
    return await db.query('questions');
  }

  void renameFile(String oldPath, String newPath) {
    File oldFile = File(oldPath);
    if (oldFile.existsSync()) {
      oldFile.renameSync(newPath);
      print('File renamed successfully.');
    } else {
      print('File does not exist at the old path.');
    }
  }

   Future<int> insertAllocatedZone(Map<String, dynamic> value) async {
    final db = await database;
    print('Allocated Zones');
    return await db.insert('allocateZone', value);
  }




  Future<int> updateUserProfile(String userId, String username, String email) async {
  final db = await database;
  
  try {
    return await db.transaction((txn) async {
      // Update login table
      await txn.update(
        'login',
        {
          'name': username,
        },
        where: 'userid = ?',
        whereArgs: [userId],
      );

      // Update users table
      await txn.rawUpdate('''
        UPDATE users 
        SET Name = ?, Email = ?, Instance_time = ? 
        WHERE Userid = ?
      ''', [username, email, DateTime.now().toIso8601String(), userId]);

      return 1;
    });
  } catch (e) {
    print('Database error: $e');
    return 0;
  }
}

Future<bool> updateUserPassword(String userId, String newPassword) async {
  final db = await database;
  try {
    await db.transaction((txn) async {
      // Update login table
      await txn.update(
        'login',
        {'password': newPassword},
        where: 'userid = ?',
        whereArgs: [userId],
      );

      // Update users table
      await txn.update(
        'users',
        {'Password': newPassword},
        where: 'Userid = ?',
        whereArgs: [userId],
      );
    });
    return true;
  } catch (e) {
    print('Database error updating password: $e');
    return false;
  }
}







  Future<void> updateSubjectId(String oldSubjectId, String newSubjectId) async {
    final db = await database;
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String oldpathutil = join(documentDirectory.path, "$oldSubjectId.jpg");
    String newpathutil = join(documentDirectory.path, "$newSubjectId.jpg");
    await db.transaction((txn) async {
      await txn.execute('''
        UPDATE Subject
        SET subject_id = ?,Image = ?
        WHERE subject_id = ?
      ''', [newSubjectId, newpathutil, oldSubjectId]);

      renameFile(oldpathutil, newpathutil);

      await txn.execute('''
        UPDATE record_log
        SET subject_id = ?
        WHERE subject_id = ?
      ''', [newSubjectId, oldSubjectId]);

      await txn.execute('''
        UPDATE service_enrollment
        SET subject_id = ?
        WHERE subject_id = ?
      ''', [newSubjectId, oldSubjectId]);
    });
  }

  Future<void> updateRecordLogID(String oldrid, String newrid) async {
    final db = await database;
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String oldpathutil = join(documentDirectory.path, "$oldrid.jpg");
    String newpathutil = join(documentDirectory.path, "$newrid.jpg");

    await db.transaction((txn) async {
      await txn.execute('''
        UPDATE record_log
        SET rid = ?,image = ?
        WHERE rid = ?
      ''', [newrid, "rid_$newrid.jpg", oldrid]);

      renameFile(oldpathutil, newpathutil);

      await txn.execute('''
        UPDATE field_entry
        SET rid = ?
        WHERE rid = ?
      ''', [newrid, oldrid]);
    });
  }

  Future<List<Map<String, Object?>>> getSubjectsValidForService(
      String serviceName) async {
    // Get current date
    final currentDate = DateTime.now().toIso8601String();
    // Open the database
    final db = await database;
    // Execute the query
    final List<Map<String, Object?>> result = await db.rawQuery('''
    SELECT Subject.*
    FROM Subject
    INNER JOIN service_enrollment ON Subject.subject_id = service_enrollment.subject_id
    INNER JOIN survey_project ON service_enrollment.sid = survey_project.sid
    WHERE survey_project.name = ?
    AND service_enrollment.end_date > ?
  ''', [serviceName, currentDate]);

    return result;
  }

  Future<void> ba() async {
    final db = await database;
    final res = await db.rawQuery('select * from service_enrollment');
    print(res);
  }

  Future<List<Map<String, Object?>>> getFamilyDetailsByFormAndVillage(
      String formName, String village) async {
    final db = await database;
    final currentDate =
        DateTime.now().toIso8601String(); // Get current date in ISO 8601 format
    print(currentDate);
    final result = await db.rawQuery('''
    SELECT DISTINCT 
      Subject.subject_id, 
      Subject.SubjectName, 
      Subject.ChildName, 
      Subject.SpouseName, 
      Subject.Mobile, 
      service_enrollment.start_date, 
      service_enrollment.end_date
    FROM Subject
    INNER JOIN service_enrollment ON Subject.subject_id = service_enrollment.subject_id
    INNER JOIN survey_project ON service_enrollment.sid = survey_project.sid 
    INNER JOIN Zone ON Zone.zone_id = Subject.zone_id
    WHERE 
      survey_project.name = ? 
      AND Zone.name = ? 
      AND service_enrollment.end_date > ?
  ''', [formName, village, currentDate]);
    return result;
  }

  Future<List<Map<String, Object?>>> getFamilyDetailsByServiceName(
      String formName) async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT Subject.subject_id, Subject.SubjectName, Subject.ChildName, Subject.SpouseName
    FROM Subject
    INNER JOIN service_enrollment ON Subject.subject_id = service_enrollment.subject_id
    INNER JOIN survey_project ON service_enrollment.sid = survey_project.sid
    WHERE survey_project.name = ?
  ''', [formName]);

    return result;
  }

  Future<List<String>> getValidServicesForSubject(String subjectId) async {
    // Get current date
    final currentDate = DateTime.now().toIso8601String();
    print('current Date : $currentDate');
    // Open the database
    final db = await database;
    // Execute the query
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT service_enrollment.*, survey_project.name
    FROM service_enrollment
    INNER JOIN survey_project ON service_enrollment.sid = survey_project.sid
    WHERE service_enrollment.subject_id = ?
    AND service_enrollment.end_date > ?
  ''', [subjectId, currentDate]);
    print('maps : $maps');
    Set<String> uniqueProjectNames = {};
    for (Map<String, dynamic> map in maps) {
      uniqueProjectNames.add(map['name'] as String);
    }
    List<String> names = [];
    for (String s in uniqueProjectNames) {
      names.add(s);
    }
    return names;
  }

  Future<List<String>> getAllServices_serivce_id() async {
    final db = await database;
    final services = await db.rawQuery('Select service_id from service');
    List<String> allServices = [];
    for (Map<String, dynamic> service in services) {
      allServices.add(service['service_id']);
    }
    return allServices;
  }

  Future<List<Map<String, dynamic>?>> getServiceForms() async {
    final db = await database;
    final data = await db.rawQuery('Select * from survey_project');
    for (var row in data) {
      print(row);
    }
    return data;
  }

  Future<List<Map<String, dynamic>?>> getServices() async {
    final db = await database;
    print('came here');
    final services = await db.rawQuery('Select * from service');
    for (var row in services) {
      print(row);
    }
    print(services);
    return services;
  }

  Future<List<Map<String, dynamic>?>> getServiceEnrollment() async {
    final db = await database;
    final services = await db.rawQuery('Select * from service_enrollment');
    for (var row in services) {
      print(row);
    }
    return services;
  }

  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    final db = await database;

    // Replace 'users' with the actual name of your users table
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'Userid = ? AND Password = ?',
      whereArgs: [username, password],
    );

    if (users.isNotEmpty) {
      // Return the first user (assuming usernames are unique)
      return users.first;
    } else {
      return null; // User not found
    }
  }

  Future<bool> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      await db.insert('users', user);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<int> insertSubject(Map<String, dynamic> subject) async {
    final db = await database;
    return await db.insert('Subject', subject);
  }

  Future<int> insertForm(Map<String, dynamic> form_) async {
    final db = await database;
    print('inserted');
    return await db.insert('survey_project', form_);
  }

  Future<int> insertFieldEntry(Map<String, dynamic> fieldEntry) async {
    final db = await database;
    print('inserted entry');
    return await db.insert('field_entry', fieldEntry);
  }

  Future<int> insertField(Map<String, dynamic> value) async {
    final db = await database;
    print('field inserted');
    print(value);
    return await db.insert('field_project', value);
  }

  Future<int> getCountForResponses() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM record_log',
    );
    return result[0]['count'];
  }

  Future<String> getServiceID(String sid) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT service_id FROM service where sid = "$sid"',
    );
    return result[0]['service_id'];
  }

//  Future<int> insertResponse(Map<String, dynamic> response) async {
//    final db = await database;
//    print('response inserted');
//    print(response);
//    return await db.insert('record_log', response);
//  }

Future<int> insertResponse(Map<String, dynamic> response) async {
  final db = await database;
  
  try {
    // Use the response data directly since we're now passing a properly formatted record
    // from take_test_page.dart
    return await db.insert('record_log', {
      'rid': response['rid'],                     // From server response
      'subject_id': response['subject_id'],       // Patient ID
      'survey_datetime': response['survey_datetime'],
      'sid': response['sid'],
      'record_type': response['record_type'],
      'survey_data': response['survey_data'],
      'image': response['image'] ?? '',           // Use empty string if null
      'voice': response['voice'] ?? '',           // Use empty string if null
      'userid': response['userid'],
      'username': response['username'],
      'upload_time': response['upload_time']      // 1 for synced, 0 for not synced
    });
  } catch (e) {
    print('Error inserting response: $e');
    rethrow;
  }
}

  Future<int> insertServiceEnrollment(Map<String, dynamic> response) async {
    final db = await database;
    print('service enrolled');
    print(response);
    return await db.insert('service_enrollment', response);
  }

  Future<List<Map<String, dynamic>>> getFields() async {
    final db = await database;
    return await db.query('field_project');
  }

  Future<List<Map<String, dynamic>>> getFieldEntriestoUpload() async {
    final db = await database;
    var result =
        await db.rawQuery('Select * from field_entry where upload_time = 0');
    return result;
  }

  Future<List<Map<String, dynamic>>> getUpdatedFieldEntriestoUpload() async {
    final db = await database;
    var result =
        await db.rawQuery('Select * from field_entry where upload_time = 2');
    return result;
  }

  

  Future<List<Map<String, dynamic>>> getServiceEnrollmentstoUpload() async {
    final db = await database;
    var result = await db
        .rawQuery('Select * from service_enrollment where upload_time = 0');
    // await db.rawQuery('Select * from service_enrollment ');
    return result;
  }

  Future<List<Map<String, dynamic>>> getSubjectDetailstoUpload() async {
    final db = await database;
    var result =
        await db.rawQuery('Select * from Subject where upload_time = 0');
    return result;
  }

  Future<List<Map<String, dynamic>>> getRecordLogstoUpload() async {
    final db = await database;
    var result =
        await db.rawQuery('Select * from record_log where upload_time = 0');
    return result;
  }

  Future<List<Map<String, dynamic>>> getUpdatedRecordLogstoUpload() async {
    final db = await database;
    var result =
        await db.rawQuery('Select * from record_log where upload_time = 2');
    return result;
  }

  Future<List<Map<String, dynamic>>> updateSubjectDetailsAfterUpload(
      String subjectID) async {
    final db = await database;
    var result = await db.rawQuery(
        'UPDATE Subject SET upload_time = 1 WHERE subject_id = "$subjectID"');
    return result;
  }

  Future<List<Map<String, dynamic>>> updateServiceEnrollmentAfterUpload(
      int id) async {
    final db = await database;
    var result = await db.rawQuery(
        'UPDATE service_enrollment SET upload_time = 1 WHERE id = $id');
    return result;
  }

  Future<List<Map<String, dynamic>>> updateImage(String subjectID) async {
    final db = await database;
    final pathName = "$subjectID.jpg";
    var result = await db.rawQuery(
        "UPDATE Subject SET Image = '$pathName' WHERE subject_id = '$subjectID'");
    return result;
  }

  Future<List<Map<String, dynamic>>> updateRecordLogAfterUpload(
      String rid) async {
    final db = await database;
    var result = await db
        .rawQuery("UPDATE record_log SET upload_time = 1 WHERE rid = '$rid'");
    return result;
  }

  Future<List<Map<String, dynamic>>> updateFieldEntryAfterUpload(int id) async {
    final db = await database;
    var result = await db
        .rawQuery('UPDATE field_entry SET upload_time = 1 WHERE id = $id');
    return result;
  }

  Future<int> getCountForZone(String zoneId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM Subject WHERE Zone_ID like \'$zoneId%\'',
      //[zoneId],
    );

    return result[0]['count'];
    // int count =  int.parse(result);
    // return count + 1;
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await database;
    return await db.query('Subject');
  }

  Future<List<Map<String, dynamic>>> getSubjectsSids() async {
    final db = await database;
    return await db.rawQuery('Select subject_id from Subject');
  }

  // Future<List<Map<String, dynamic>>> getResponses() async {
  //   final db = await database;
  //   return await db
  //       .query('record_log', where: 'record_type = ?', whereArgs: [0]);
  // }

  Future<List<Map<String, dynamic>>> getResponses() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT s.SubjectName, s.SpouseName,s.ChildName, s.Mobile, s.Village,s.Age, sp.name AS FormName, rl.*
    FROM record_log rl
    INNER JOIN survey_project sp ON rl.sid = sp.sid
    INNER JOIN Subject s ON rl.subject_id = s.subject_id
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllResponses() async {
    final db = await database;
    final data = await db.rawQuery('''
    select * from record_log
  ''');
    for (var row in data) {
      print(row);
    }
    // print(data);
    return data;
  }

  Future<String> getSidByName(String name) async {
    final db = await database;
    final result = await db.query(
      'survey_project',
      columns: ['sid'],
      where: 'name = ?',
      whereArgs: [name],
    );
    // Return the sid as a String
    return result.first['sid'].toString();
  }

  Future<Map<String, String>> getSidServiceIdByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT service.service_id, service.sid
    FROM service
    INNER JOIN survey_project ON service.sid = survey_project.sid
    WHERE survey_project.name = ?
  ''', [name]);

    return {
      'service_id': result.first['service_id'].toString(),
      'sid': result.first['sid'].toString(),
    };
  }

  Future<String> getridBysubjectIDandDatetime(
      String subjectID, DateTime currTime) async {
    final db = await database;
    final formattedDatetime = currTime.toUtc().toIso8601String();
    print("${currTime.runtimeType}");
    print(currTime);
    final result = await db.query(
      'record_log',
      columns: ['rid'],
      where: 'subject_id = ? AND survey_datetime = ?',
      whereArgs: [subjectID, formattedDatetime],
    );
    // Return the sid as a String
    return result.first['rid'].toString();
  }

  Future<String> getfidBysidandAttributeName(
      String sid, String attributeName) async {
    final db = await database;
    final result = await db.query(
      'field_project',
      columns: ['fid'],
      where: 'sid = ? AND attribute_name = ?',
      whereArgs: [sid, attributeName],
    );
    // Return the sid as a String
    return result.first['fid'].toString();
  }

  Future<String> getsubjectIDByName(FamilyDetails? familyDetails) async {
    final db = await database;

    final result = await db.query(
      'Subject',
      columns: ['subject_id'],
      where: 'SubjectName = ? AND ChildName =? AND SpouseName = ?',
      whereArgs: [
        familyDetails?.subjectName,
        familyDetails?.spouseName,
        familyDetails?.childName
      ],
    );
    // Return the sid as a String
    return result.first['subject_id'].toString();
  }
  // Future<String> getsubjectIDByName(String? name) async {
  //   final db = await database;
  //   final result = await db.query(
  //     'Subject',
  //     columns: ['subject_id'],
  //     where: 'Name = ?',
  //     whereArgs: [name],
  //   );
  //   // Return the sid as a String
  //   return result.first['subject_id'].toString();
  // }

  Future<List<String>> getSubjectNames() async {
    final db = await database;
    final result = await db.query(
      'Subject',
      columns: ['SubjectName'],
    );
    print(result);
    // Extract the 'Name' values from the result and store them in a list
    final names = result.map((row) => row['name'].toString()).toList();
    print(names);
    return names;
  }

  // Future<List<Map<String, String>>> getSubjectNames() async {
  //   // Replace this with the actual implementation to fetch data from the database
  //   final db = await database;
  //   final result = await db.query('Subject', columns: [
  //     'MotherNameBeneficiary',
  //     'ChildNameBeneficiary',
  //     'HusbandName'
  //   ]);
  //   print(result);
  //   final names = result.map((e) => null)
  //   return List.generate(
  //     100,
  //     (index) => {
  //       'motherName': 'Mother Name $index',
  //       'childName': 'Child Name $index',
  //       'husbandName': 'Husband Name $index',
  //     },
  //   );
  // }
  Future<List<Map<String, Object?>>> getFamilyDetails() async {
    final db = await database;
    final result = await db.query('Subject',
        columns: ['subject_id', 'SubjectName', 'ChildName', 'SpouseName']);
    return result;
  }

  Future<List<Map<String, Object?>>> getFamilyDetailsbyVillage(
      String village) async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT s.subject_id, s.SubjectName, s.ChildName, s.SpouseName, s.Mobile FROM Subject s JOIN Zone z ON s.Zone_ID = z.zone_id WHERE z.name = '$village'");
    print('village members : $result');
    return result;
  }
  // Future<List<Map<String, Object?>>> getFamilyDetailsbyVillage(
  //     String village) async {
  //   final db = await database;
  //   final result = await db.query(
  //     'Subject',
  //     columns: [
  //       'subject_id',
  //       'SubjectName',
  //       'ChildName',
  //       'SpouseName',
  //       'Mobile'
  //     ],
  //     where: 'Village = ?',
  //     whereArgs: [village],
  //   );
  //   print('village memebers : $result');
  //   return result;
  // }

  Future<List<Map<String, Object?>>> getFamilyDetailsbyVillageAndNotRegistered(
      String formName, String village) async {
    final db = await database;
    final currentDate =
        DateTime.now().toIso8601String(); // Get current date in ISO 8601 format
    print(currentDate);

    final result = await db.rawQuery(
        '''SELECT s.subject_id, s.SubjectName, s.ChildName, s.SpouseName, s.Mobile 
       FROM Subject s 
       JOIN Zone z ON s.Zone_ID = z.zone_id 
       WHERE z.name = ? 
       AND s.subject_id NOT IN (
         SELECT DISTINCT Subject.subject_id 
         FROM Subject 
         INNER JOIN service_enrollment ON Subject.subject_id = service_enrollment.subject_id 
         INNER JOIN survey_project ON service_enrollment.sid = survey_project.sid 
         INNER JOIN Zone ON Zone.zone_id = Subject.zone_id 
         WHERE 
           survey_project.name = ? 
           AND Zone.name = ? 
           AND service_enrollment.end_date > ?
       )''', [village, formName, village, currentDate]);

    // print('village members : $result');
    return result;
  }

  Future<List<Map<String, Object?>>> getVillageNames() async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.rawQuery('''
    SELECT DISTINCT name as Village FROM Zone
  ''');
    print('villages : $result');
    return result;
  }
  // Future<List<Map<String, Object?>>> getVillageNames() async {
  //   final db = await database;
  //   final List<Map<String, Object?>> result = await db.rawQuery('''
  //   SELECT DISTINCT Village FROM Subject
  // ''');
  //   print('villages : $result');
  //   return result;
  // }

  Future<List<Map<String, Object?>>> getVillagefromZoneID(String zoneID) async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.rawQuery('''
    SELECT name FROM Zone Where zone_id = ?
  ''', [zoneID]);
    print('villages : $result');
    return result;
  }

  Future<List<String>> getFormsNames() async {
    final db = await database;
    final result = await db.query(
      'survey_project',
      columns: ['name'],
    );
    print(result);
    // Extract the 'Name' values from the result and store them in a list
    final names = result.map((row) => row['name'].toString()).toList();
    print(names);
    return names;
  }

  Future<List<Map<String, dynamic>>> getFormWithName(String? name) async {
    final db = await database;
    final result = await db.query(
      'survey_project',
      where: 'name = ?',
      whereArgs: [name],
    );
    print('The result is ');
    print(result);
    return result;
  }

  Future<List<Map<String, dynamic>>> getPreviousResponses(
      String subjectId, String sid) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT * FROM record_log where record_type=0 AND subject_id="$subjectId" AND sid="$sid" ORDER BY survey_datetime DESC;');
    print('previous Responses : ');
    print(result);
    return result;
  }

  // Future<List<String>> getServicesEnrolledByID(
  //     String? subjectID) async {
  //   final db = await database;
  //   final result = await db.query(
  //     'service_enrollment',
  //     where: 'subject_id=?',
  //     whereArgs: [subjectID],
  //   );
  //   final names = result.map((row) => row['Name'].toString()).toList();
  //   print(names);
  //   return names;
  // }
  Future<List<String>> getServicesEnrolledByID(String subjectId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT survey_project.name
    FROM survey_project
    INNER JOIN service_enrollment ON survey_project.sid = service_enrollment.sid
    WHERE service_enrollment.subject_id = ?
  ''', [subjectId]);

    List<String> projectNames = [];
    for (Map<String, dynamic> map in maps) {
      projectNames.add(map['name'] as String);
    }

    return projectNames;
  }

  Future<List<String>> getUniqueServicesEnrolledByID(String subjectId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT DISTINCT survey_project.name
    FROM survey_project
    INNER JOIN service_enrollment ON survey_project.sid = service_enrollment.sid
    WHERE service_enrollment.subject_id = ?
  ''', [subjectId]);

    Set<String> uniqueProjectNames = {};
    for (Map<String, dynamic> map in maps) {
      uniqueProjectNames.add(map['name'] as String);
    }
    List<String> names = [];
    for (String s in uniqueProjectNames) {
      names.add(s);
    }
    return names;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

//  Future<List<Map<String, dynamic>>> getForms() async {
//    final db = await database;
//    final f = await db.query('survey_project');
//    for (var e in f) {
//      print(e);
//    }
    // print('$f');
//    return f;
//  }

// Add/modify this method to get all forms
Future<List<Map<String, dynamic>>> getForms() async {
  try {
    final db = await database;
    print('Executing getForms query');
    // Query specific columns from survey_project table
    final result = await db.rawQuery('''
      SELECT name, sid, description, creation_date 
      FROM survey_project 
      ORDER BY creation_date DESC
    ''');
    print('Query result: $result');
    return result;
  } catch (e) {
    print('Database error in getForms: $e');
    return [];
  }
}

// Add this method to check if any forms exist
Future<bool> hasAnyForms() async {
  final db = await database;
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM survey_project');
  print('Form count: ${result.first['count']}'); // Debug print
  return (result.first['count'] as int) > 0;
}

// Add this method to insert a test form if needed
Future<void> addTestForm() async {
  final db = await database;
  await db.insert('survey_project', {
    'name': 'Test Form',
    'description': 'Test Description',
    'sid': 'test_sid',
    'creation_date': DateTime.now().toIso8601String(),
    'template_source': '{}',
    'details_source': '{}'
  });
  print('Test form added to database');
}

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'Userid = ?',
      whereArgs: [userId],
    );
    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  Future<int> updateUser(
      String userId, Map<String, dynamic> updatedUser) async {
    final db = await database;
    return await db.update(
      'users',
      updatedUser,
      where: 'Userid = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'Userid = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteDatabaseUtil() async {
    String path = join(await getDatabasesPath(), 'svyVARN0000.db');

    // Delete the database file
    //await deleteDatabase(path);
    // path = join(await getDatabasesPath(), 'svyVARN0000.db');
     await deleteDatabase(path);
    print('deleted database successfully');
  }

  Future<bool> zoneExists(String zone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT zone_id from Zone where zone_id = ?
  ''', [zone]);
    return maps.isNotEmpty;
  }

  Future<int> storeTheZones(Map<String, dynamic> zoneInfo) async {
    final db = await database;
    bool flag = await zoneExists(zoneInfo['zone_id']);
    if (flag) {
      // print('already there');
      log.info('$zoneInfo already exists');
      return 1;
    } else {
      log.info('Inserting $zoneInfo ');
      // print('');
      return await db.insert('Zone', zoneInfo);
    }
  }

  void checkZones() async {
    final db = await database;
    final res = await db.rawQuery('''select * from Zone''');
    print(res);
  }

  Future<bool> surveyFormExists(String sid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT sid from survey_project where sid = ?
  ''', [sid]);
    return maps.isNotEmpty;
  }

  Future<int> storeTheSurveyForms(Map<String, dynamic> surveyForm) async {
    final db = await database;
    bool flag = await surveyFormExists(surveyForm['sid']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the form');
      return await db.insert('survey_project', surveyForm);
    }
  }

  void checkSurveyForms() async {
    final db = await database;
    final res = await db.rawQuery('''select * from survey_project''');
    print(res);
  }

  Future<bool> fieldExists(String fid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT sid from field_project where fid = ?
  ''', [fid]);
    return maps.isNotEmpty;
  }

  Future<int> insertFieldUtil(Map<String, dynamic> value) async {
    final db = await database;
    bool flag = await fieldExists(value['fid']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the field');
      return await db.insert('field_project', value);
    }
  }

  void checkFields() async {
    final db = await database;
    final res = await db.rawQuery('''select * from field_project''');
    print(res);
  }

  Future<bool> subjectExists(String subjectid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT subject_id from Subject where subject_id = ?
  ''', [subjectid]);
    return maps.isNotEmpty;
  }

  Future<int> insertSubjectUtil(Map<String, dynamic> subject) async {
    final db = await database;
    bool flag = await subjectExists(subject['subject_id']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the subject');
      return await db.insert('Subject', subject);
    }
  }

  void checkSubjects() async {
    final db = await database;
    final res = await db.rawQuery('''select * from Subject''');
    print(res);
  }

  Future<bool> serviceExists(String serviceid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT service_id from service where service_id = ?
  ''', [serviceid]);
    return maps.isNotEmpty;
  }

  Future<int> insertServiceUtil(Map<String, dynamic> service) async {
    final db = await database;
    bool flag = await serviceExists(service['service_id']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the service');
      return await db.insert('service', service);
    }
  }

  void checkServices() async {
    final db = await database;
    final res = await db.rawQuery('''select * from service''');
    print(res);
  }

  // void checkUploadTime() async {
  //   final db = await database;
  //   final res = await db.rawQuery('''select subject_id,upload_time from Subject where upload_time=1''');
  //   print(res);
  // }

  Future<List<Map<String, Object?>>> uploadFormsData() async {
    final db = await database;
    final res = await db.rawQuery('''
      select * from survey_project where upload_time=0
    ''');
    return res;
  }

  Future<List<Map<String, Object?>>> uploadFieldsData() async {
    final db = await database;
    final res = await db.rawQuery('''
      select * from field_project where upload_time=0
    ''');
    return res;
  }

  Future<void> check_service_enrollment() async {
    final db = await database;
    final res = await db.rawQuery('''
      select * from service_enrollment
    ''');
    print(res);
  }

  Future<void> check_responses() async {
    final db = await database;
    final res = await db.rawQuery('''
      select * from record_log
    ''');
    print(res);
  }

  Future<void> check_responses_to_upload() async {
    final db = await database;
    final res = await db.rawQuery('''
      select * from record_log where upload_time is null or upload_time = 0
    ''');
    print(res);
  }

  // Future<int> insertResponseUtil(Map<String, dynamic> response) async {
  //   final db = await database;
  //   print('response inserted');
  //   print(response);
  //   return await db.insert('record_log', response);
  // }

  Future<bool> responseExists(String rid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT rid from record_log where rid = ?
  ''', [rid]);
    return maps.isNotEmpty;
  }

  Future<int> insertResponseUtil(Map<String, dynamic> response) async {
    final db = await database;
    bool flag = await responseExists(response['rid']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the response');
      return await db.insert('record_log', response);
    }
  }

  Future<bool> fieldEntryExists(String rid, String fid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT rid from field_entry where rid = ? AND fid = ?
  ''', [rid, fid]);
    return maps.isNotEmpty;
  }

  Future<int> insertFiedEntryUtil(Map<String, dynamic> response) async {
    final db = await database;
    bool flag = await fieldEntryExists(response['rid'], response['fid']);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the field_entry');
      return await db.insert('field_entry', response);
    }
  }

  Future<bool> serviceEnrollmentofSubjectExists(
      Map<String, dynamic> row) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT id from service_enrollment where service_id = ? AND subject_id = ? AND sid = ? AND start_date = ? AND end_date = ?
  ''', [
      row['service_id'],
      row['subject_id'],
      row['sid'],
      row['start_date'],
      row['end_date']
    ]);
    return maps.isNotEmpty;
  }

  Future<int> serviceEnrollementofSubject(Map<String, dynamic> row) async {
    final db = await database;
    bool flag = await serviceEnrollmentofSubjectExists(row);
    if (flag) {
      print('already there');
      return 1;
    } else {
      print('inserting the service enrollment of subject');
      return await db.insert('service_enrollment', row);
    }
  }


  Future<void> clearAllTablesData() async {
    final db = await database;

    // //Below commented code gives the list of all the tables of the database
    // List<Map<String, dynamic>> result = await db.rawQuery(
    //     "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    // List<String> tableNames =
    //     result.map((row) => row['name'] as String).toList();
    // print(tableNames);
    // final res = await db.rawQuery('''SELECT * from users;''');
    // print(res);

    await db.rawQuery('''DELETE FROM users;''');
    await db.rawQuery('''DELETE FROM Zone;''');
    await db.rawQuery('''DELETE FROM Subject;''');
    await db.rawQuery('''DELETE FROM survey_project;''');
    await db.rawQuery('''DELETE FROM field_project;''');
    await db.rawQuery('''DELETE FROM record_log;''');
    await db.rawQuery('''DELETE FROM field_entry;''');
    await db.rawQuery('''DELETE FROM service;''');
    await db.rawQuery('''DELETE FROM service_enrollment;''');
    await db.rawQuery('''DELETE FROM allocateZone;''');
  }

  //Initialize "lastest_download_upload_time"
  Future<void> initializeLastestDownloadUploadTime(
      String operationType, String dateTime) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawInsert('''
        INSERT INTO lastest_download_upload_time(operation_type,date_time)
        VALUES (?, ?)
      ''', [operationType, dateTime]);
    });
  }
  //Update "lastest_download_upload_time"
  Future<void> updateLastestDownloadUploadTime(
      String operationType, String dateTime) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('''
        UPDATE lastest_download_upload_time SET date_time=?  WHERE 
        operation_type= ?
      ''', [dateTime, operationType]);
    });
  }

  Future<String> getUpdateLastestDownloadUploadTime(
      String operationType) async {
    final db = await database;
    List<Map<String, dynamic>> tempVar = await db.rawQuery('''
    SELECT date_time FROM lastest_download_upload_time WHERE 
        operation_type= ?
  ''', [operationType]);
    return tempVar[0]['date_time'];
  }

  Future<bool> updateResponses(String responses, String rid) async {
    final db = await database;
    try {
      // Assuming there's an ID field in the responses map
      await db.transaction((txn) async {
        await txn.execute('''
        UPDATE record_log SET survey_data=?  WHERE 
        rid= ?
      ''', [responses, rid]);
        await txn.execute('''UPDATE record_log SET upload_time = 2 WHERE rid = ?''',[rid]);
        
      });
      // print(responses);
      return true;
    } catch (e) {
      print('Error updating responses: $e');
      return false;
    }
  }
  Future<bool> updateResponsesByField(String response, String rid,String fid) async {
    final db = await database;
    try {
      // Assuming there's an ID field in the responses map
      await db.transaction((txn) async {
        
        await txn.execute('''UPDATE field_entry SET value = ? WHERE rid = ? and fid = ?''', [response,rid, fid]);
      await txn.execute('''UPDATE field_entry SET upload_time = 2 WHERE rid = ? and fid = ?''',[rid,fid]);
    });
      
      // print(responses);
      return true;
    } catch (e) {
      print('Error updating response by field: $e');
      return false;
    }
  }



  Future<List<Map<String, dynamic>>> getFormWithSid(String? sid) async {
    final db = await database;
    final result = await db.query(
      'survey_project',
      where: 'sid = ?',
      whereArgs: [sid],
    );
    print('The result is ');
    print(result);
    print('Query result for sid $sid: $result'); // Debug print
    print('DB Query Result: $result');  // Add this line
    print('DB Result template_source: ${result.first['template_source']}');  // Add this line
    print('DB Result template_source type: ${result.first['template_source'].runtimeType}');  // Add this line
    return result;
  }

//  CREATE TABLE login (
//         loginid TEXT PRIMARY KEY,
//         password TEXT,
//         name TEXT,
//         user_type TEXT,
//         userid TEXT
//       )
  Future<bool> saveLoginDetails(String loginid, String password, String name, String userType, String userid) async { // Save a new login credentials
    final db = await database;
    try {    
      await db.transaction((txn) async {        
      await txn.rawInsert('''
        INSERT INTO login(loginid,password,name,user_type,userid) VALUES (?, ?, ?, ?, ?)''', [loginid, password,name,userType,userid]);
        
      });
      print("Saved login credentials in localdb !!!!!!!!!!!");
      return true;
    } catch (e) {
      print('Error logging: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLoginDetails(String uid, String pwd) async { // Get login credentials
    final db = await database;

    // List<Map<String, dynamic>> result = await db.rawQuery('''
    //     SELECT COUNT(*) AS count FROM login WHERE userid=? and password=?''', [uid, pwd]);

    final res = await db.rawQuery('''SELECT * FROM login WHERE loginid=? and password=?''', [uid, pwd]);
        
    //return result[0]['count'];      
    return res;
  }

  Future<int> checkLoginDetails(String uid, String pwd) async { // Verify login credentials
    final db = await database;

     List<Map<String, dynamic>> result = await db.rawQuery('''
         SELECT COUNT(*) AS count FROM login WHERE loginid=? and password=?''', [uid, pwd]);
      print("Counttttttt");
      print(result[0]['count']);
    
        
    return result[0]['count'];      
    
  }


  Future<int> checkLoginUser(String uid) async {  // To check if the user credential is already saved
    final db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT COUNT(*) AS count FROM login WHERE loginid=?''', [uid]);
    
      print("User present -");
      print(result[0]['count']);

    return result[0]['count'];      
  }

}
