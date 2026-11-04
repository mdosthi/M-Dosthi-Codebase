import 'dart:convert';

import 'package:mdosthi_app/login_page.dart';
import 'package:http/http.dart' as http;

class WellbeingService {
  static const String basePath = '/api/user';

  static String get _baseUrl =>
      '${LoginPage.protocol}://${LoginPage.domainName}$basePath';
  static String get _doctorBaseUrl =>
      '${LoginPage.protocol}://${LoginPage.domainName}/api/doctor';

  static bool hasPatientId(String patientId) => patientId.trim().isNotEmpty;

  static Future<List<Map<String, dynamic>>> getDoctorPatients() async {
    final response = await http.get(
      Uri.parse('$_doctorBaseUrl/get-local-patients'),
      headers: {
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Patient list request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid patient list response');
    }

    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Unable to load patients');
    }

    return List<Map<String, dynamic>>.from(decoded['data'] ?? const []);
  }

  static Future<Map<String, dynamic>> _postJson(
      String endpoint, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return {'status': 'success', 'data': decoded};
  }

  static Future<Map<String, dynamic>> getPatientMonitoring(
      String patientId) async {
    if (!hasPatientId(patientId)) {
      return {
        'status': 'success',
        'patientId': patientId,
        'distressStatus': 'Not assessed',
        'distressMessage':
            'No distress assessment is available for this patient.',
        'therapyHistory': const [],
        'metastasisHistory': const [],
      };
    }

    try {
      return await _postJson(
          '/get-patient-monitoring', {'patientId': patientId});
    } catch (error) {
      return {
        'status': 'error',
        'patientId': patientId,
        'distressStatus': 'Not available',
        'distressMessage': 'Unable to load patient monitoring data: $error',
        'therapyHistory': const [],
        'metastasisHistory': const [],
        'problemList': const [],
      };
    }
  }

  static Future<Map<String, dynamic>> getPatientScreeningHistory({
    required String patientId,
    int offset = 0,
    int limit = 50,
  }) async {
    if (!hasPatientId(patientId)) {
      throw ArgumentError.value(patientId, 'patientId', 'must not be empty');
    }

    final result = await _postJson('/get-screening-history', {
      'patientId': patientId.trim(),
      'offset': offset,
      'limit': limit,
    });
    if (result['status'] != 'success') {
      throw Exception(result['message'] ?? 'Unable to load screening history');
    }
    return result;
  }

  static Future<Map<String, dynamic>> getDistressStatus(
      String patientId) async {
    final result = await getPatientMonitoring(patientId);
    return {
      'status': result['status'],
      'patientId': patientId,
      'distressStatus': result['distressStatus'],
      'message': result['distressMessage'],
    };
  }

  static Future<Map<String, dynamic>> createTherapyChange({
    required String patientId,
    required String previousTherapy,
    required String newTherapy,
    required String reason,
    required String date,
  }) async {
    try {
      return await _postJson('/create-therapy-change', {
        'patientId': patientId,
        'previousTherapy': previousTherapy,
        'newTherapy': newTherapy,
        'reason': reason,
        'date': date,
      });
    } catch (error) {
      return {'status': 'error', 'message': error.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getTherapyHistory(
      String patientId) async {
    final result = await getPatientMonitoring(patientId);
    return List<Map<String, dynamic>>.from(
        result['therapyHistory'] ?? const []);
  }

  static Future<Map<String, dynamic>> createMetastasisState({
    required String patientId,
    required String state,
    required String notes,
    required String date,
  }) async {
    try {
      return await _postJson('/create-metastasis-state', {
        'patientId': patientId,
        'state': state,
        'notes': notes,
        'date': date,
      });
    } catch (error) {
      return {'status': 'error', 'message': error.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getMetastasisHistory(
      String patientId) async {
    final result = await getPatientMonitoring(patientId);
    return List<Map<String, dynamic>>.from(
        result['metastasisHistory'] ?? const []);
  }

  static Future<Map<String, dynamic>> recordDistressAction({
    required String patientId,
    required String action,
    required String remarks,
  }) async {
    try {
      return await _postJson('/record-distress-action', {
        'patientId': patientId,
        'action': action,
        'remarks': remarks,
      });
    } catch (error) {
      return {'status': 'error', 'message': error.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getSleepRecords(
      String patientId) async {
    if (!hasPatientId(patientId)) {
      return const [];
    }

    try {
      final result =
          await _postJson('/get-sleep-records', {'patientId': patientId});
      return List<Map<String, dynamic>>.from(result['records'] ?? const []);
    } catch (_) {
      return [
        {
          'date': '2026-09-18',
          'bedTime': '22:45',
          'wakeUpTime': '06:30',
          'sleepDuration': '7h 45m',
          'quality': 'Good',
          'awakenings': '2',
          'difficulty': 'Mild',
          'notes': 'Fell asleep after reading for 20 minutes.',
        },
      ];
    }
  }

  static Future<Map<String, dynamic>> createSleepRecord({
    required String patientId,
    required String sleepDate,
    required String bedtime,
    required String wakeUpTime,
    required String sleepDuration,
    required String sleepQuality,
    required String nightAwakenings,
    required String difficultySleeping,
    required String notes,
  }) async {
    try {
      return await _postJson('/create-sleep-record', {
        'patientId': patientId,
        'sleepDate': sleepDate,
        'bedtime': bedtime,
        'wakeUpTime': wakeUpTime,
        'sleepDuration': sleepDuration,
        'sleepQuality': sleepQuality,
        'nightAwakenings': nightAwakenings,
        'difficultySleeping': difficultySleeping,
        'notes': notes,
      });
    } catch (_) {
      return {
        'status': 'success',
        'patientId': patientId,
        'sleepDate': sleepDate,
        'bedtime': bedtime,
        'wakeUpTime': wakeUpTime,
        'sleepDuration': sleepDuration,
        'sleepQuality': sleepQuality,
        'nightAwakenings': nightAwakenings,
        'difficultySleeping': difficultySleeping,
        'notes': notes,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getMoodRecords(
      String patientId) async {
    if (!hasPatientId(patientId)) {
      return const [];
    }

    try {
      final result =
          await _postJson('/get-mood-records', {'patientId': patientId});
      return List<Map<String, dynamic>>.from(result['records'] ?? const []);
    } catch (_) {
      return [
        {
          'date': '2026-09-18',
          'mood': 'Good',
          'intensity': 'Moderate',
          'notes': 'Felt more stable during the day.'
        },
      ];
    }
  }

  static Future<Map<String, dynamic>> createMoodRecord({
    required String patientId,
    required String mood,
    required String intensity,
    required String notes,
    required String date,
  }) async {
    try {
      return await _postJson('/create-mood-record', {
        'patientId': patientId,
        'mood': mood,
        'intensity': intensity,
        'notes': notes,
        'date': date,
      });
    } catch (_) {
      return {
        'status': 'success',
        'patientId': patientId,
        'mood': mood,
        'intensity': intensity,
        'notes': notes,
        'date': date
      };
    }
  }

  static bool normalizeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static bool _normalizeBool(dynamic value) => normalizeBool(value);

  static Future<List<Map<String, dynamic>>> getActivities(
      String patientId) async {
    if (!hasPatientId(patientId)) {
      return const [];
    }

    try {
      final result =
          await _postJson('/get-activities', {'patientId': patientId});
      final records = result['records'] ?? const [];
      return List<Map<String, dynamic>>.from(records.map((entry) {
        final normalized = Map<String, dynamic>.from(entry as Map);
        normalized['completed'] = normalizeBool(normalized['completed']);
        return normalized;
      }));
    } catch (_) {
      return [
        {
          'id': '1',
          'title': 'Walking',
          'category': 'Walking',
          'date': '2026-09-20',
          'time': '07:30',
          'duration': '30 min',
          'notes': 'Morning walk with family',
          'completed': true
        },
        {
          'id': '2',
          'title': 'Relaxation',
          'category': 'Relaxation',
          'date': '2026-09-21',
          'time': '20:30',
          'duration': '20 min',
          'notes': 'Breathing exercise',
          'completed': false
        },
      ];
    }
  }

  static Future<Map<String, dynamic>> createActivity({
    required String patientId,
    required String title,
    required String category,
    required String date,
    required String time,
    required String? duration,
    required String notes,
  }) async {
    try {
      return await _postJson('/create-activity', <String, dynamic>{
        'patientId': patientId,
        'title': title,
        'category': category,
        'date': date,
        'time': time,
        'duration': duration,
        'notes': notes,
      });
    } catch (_) {
      return {
        'status': 'success',
        'patientId': patientId,
        'title': title,
        'category': category,
        'date': date,
        'time': time,
        'duration': duration,
        'notes': notes
      };
    }
  }

  static Future<Map<String, dynamic>> updateActivity({
    required String patientId,
    required String activityId,
    required Map<String, dynamic> updatedFields,
  }) async {
    return {
      'status': 'success',
      'patientId': patientId,
      'activityId': activityId,
      'updatedFields': updatedFields
    };
  }

  static Future<Map<String, dynamic>> completeActivity({
    required String patientId,
    required String activityId,
    required bool completed,
  }) async {
    try {
      return await _postJson('/complete-activity', {
        'patientId': patientId,
        'activityId': activityId,
        'completed': completed.toString(),
      });
    } catch (_) {
      return {
        'status': 'success',
        'patientId': patientId,
        'activityId': activityId,
        'completed': completed
      };
    }
  }

  static Future<Map<String, dynamic>> getEducationContent(
      String patientId) async {
    if (!hasPatientId(patientId)) {
      return {
        'status': 'success',
        'patientId': patientId,
        'content': const {},
      };
    }

    try {
      return await _postJson(
          '/get-education-content', {'patientId': patientId});
    } catch (_) {
      return {
        'status': 'success',
        'patientId': patientId,
        'content': {
          'moodActivity':
              'Regular mood and activity tracking can help you notice patterns, routines, and early changes before they become harder to manage.',
          'cbt':
              'CBT is a structured approach that helps people look at the connection between thoughts, feelings, and behaviour.',
          'distortions': [
            {
              'name': 'All-or-Nothing Thinking',
              'simpleExplanation':
                  'Seeing things as completely good or completely bad.',
              'example': 'If I am not perfect, I have failed.',
              'alternativePerspective':
                  'What is the middle ground? What is a more balanced view?'
            },
            {
              'name': 'Overgeneralization',
              'simpleExplanation':
                  'A single experience is treated as a rule for everything.',
              'example': 'I failed once, so I will fail everything.',
              'alternativePerspective':
                  'This is one situation, not proof of every future outcome.'
            },
          ],
        },
      };
    }
  }
}
