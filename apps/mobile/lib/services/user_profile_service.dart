import 'dart:convert';
import 'package:app_001/backend/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:app_001/login_page.dart';

class UserProfileService {
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      // Use loginid instead of userid for the request
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-user-details";

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}'
      };

      final body = jsonEncode({
        "identifier":
            LoginPage.username, // Use username/loginid instead of userid
      });

      print("Making request to: $url");
      print("Request body: $body");
      print("Headers: $headers");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['user-info'] ?? {};
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to get user info');
        }
      } else {
        throw Exception(
            'Failed to get user info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in getUserInfo: $e");

      // Fallback to local database with better error handling
      try {
        final dbHelper = DatabaseHelper.instance;
        final List<Map<String, dynamic>> results = await dbHelper
            .getLoginDetails(LoginPage.username, LoginPage.password);

        if (results.isNotEmpty) {
          // Transform login table data to match the expected user info format
          return {
            'name': results[0]['name'],
            'loginid': results[0]['loginid'],
            'userid': results[0]['userid'],
            'user_type': results[0]['user_type'],
            // Add other fields with default values
            'age': results[0]['age'],
            'password': '',
            'sex': results[0]['sex'],
            'ccode': '',
            'address': results[0]['address'],
            'mobile': results[0]['mobile'],
            'email': results[0]['email'],
            'qualification': results[0]['qualification'],
            'designation': results[0]['designation'],
            'verifemail': '',
            'verifphone': '',
            'active': ''
          };
        }
      } catch (dbError) {
        print("Database error: $dbError");
      }

      throw Exception('Failed to get user info: $e');
    }
  }

  static Future<bool> updateUserInfo(Map<String, dynamic> userDetails) async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/update-user-details";

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}'
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(userDetails),
      );

      print("Update response status: ${response.statusCode}");
      print("Update response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Update local database
          await _updateLocalUserInfo(userDetails);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error updating user info: $e");
      return false;
    }
  }

  static Future<void> _updateLocalUserInfo(
      Map<String, dynamic> userDetails) async {
    try {
      final db = DatabaseHelper.instance;
      await db.updateUserProfile(userDetails['userid'],
          userDetails['name'] ?? '', userDetails['email'] ?? '');
    } catch (e) {
      print("Error updating local database: $e");
    }
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/change-password";

      // Use loginid instead of userid
      final body = jsonEncode({
        'loginid': LoginPage.username, // Use username/loginid
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LoginPage.jwtToken}'
      };

      print('Making password change request to: $url');
      print('Request body: $body');
      print('Using headers: $headers');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Update local password
          final db = DatabaseHelper.instance;
          await db.updateUserPassword(LoginPage.username, newPassword);
          return true;
        } else {
          print('Password change failed: ${jsonResponse['message']}');
        }
      }
      return false;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // ignore: unused_element
  static Future<void> _updateLocalPassword(
      String userId, String newPassword) async {
    try {
      final db = DatabaseHelper.instance;
      await db.updateUserPassword(userId, newPassword);
    } catch (e) {
      print("Error updating local password: $e");
      throw Exception('Failed to update local password');
    }
  }
}
