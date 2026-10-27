// lib/service/auth_service.dart
//
// AuthService handles JWT token expiry detection and silent re-login.
//
// USAGE in any page that makes API calls:
//
//   final result = await AuthService.makeAuthenticatedRequest(() async {
//     return await http.post(
//       Uri.parse(url),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer ${LoginPage.jwtToken}',
//       },
//       body: jsonEncode({...}),
//     );
//   });
//
//   if (result == null) {
//     // Re-login failed entirely — session is cleared, user will see login screen
//     return;
//   }
//   // use result normally

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart';

class AuthService {
  /// Checks whether a response indicates the JWT token has expired.
  /// Covers both HTTP 401 status and JSON bodies with token expiry messages.
  static bool isTokenExpired(http.Response response) {
    if (response.statusCode == 401) {
      return true;
    }
    // Some Spring Boot setups return 200 with an error body
    try {
      final body = jsonDecode(response.body);
      final message = (body['message'] ?? body['error'] ?? '').toString().toLowerCase();
      if (message.contains('token has expired') ||
          message.contains('expired') ||
          message.contains('jwt expired') ||
          message.contains('invalid token')) {
        return true;
      }
    } catch (_) {
      // Body was not JSON — not a token error
    }
    return false;
  }

  /// Silently re-logs in using saved credentials from SharedPreferences.
  /// Returns true if successful and updates LoginPage static fields + SharedPreferences.
  /// Returns false if re-login failed (wrong credentials or server unreachable).
  static Future<bool> silentReLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('session_username');
    final String? savedPassword = prefs.getString('session_password');

    if (savedUsername == null || savedUsername.isEmpty ||
        savedPassword == null || savedPassword.isEmpty) {
      print("AuthService.silentReLogin: No saved credentials found");
      return false;
    }

    print("AuthService.silentReLogin: Attempting silent re-login for $savedUsername");

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/login";

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': savedUsername,
              'password': savedPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          // Update in-memory static fields
          LoginPage.jwtToken = json['jwtToken'];
          LoginPage.userId = json['userid'];
          LoginPage.username = savedUsername;
          LoginPage.password = savedPassword;
          LoginPage.patid = json['userid'];

          // Persist the new token to SharedPreferences
          await LoginPage.saveSession(
            jwtToken: json['jwtToken'],
            userId: json['userid'],
            username: savedUsername,
            password: savedPassword,
            patid: json['userid'],
            name: json['name'] ?? '',
            type: json['type'] ?? '',
          );

          print("AuthService.silentReLogin: Success — new token obtained");
          return true;
        }
      }

      print("AuthService.silentReLogin: Failed — server returned ${response.statusCode}");
      return false;
    } catch (e) {
      print("AuthService.silentReLogin: Exception — $e");
      return false;
    }
  }

  /// Wraps any HTTP call with automatic token-expiry handling.
  ///
  /// - Runs [apiCall] once.
  /// - If the response indicates token expiry, silently re-logs in and retries once.
  /// - If re-login also fails, clears the session and returns null.
  ///   The SplashScreen will handle redirecting to LoginPage on next app open.
  ///
  /// Returns the http.Response on success, or null if re-login failed entirely.
  static Future<http.Response?> makeAuthenticatedRequest(
    Future<http.Response> Function() apiCall,
  ) async {
    // First attempt
    http.Response response;
    try {
      response = await apiCall();
    } catch (e) {
      print("AuthService.makeAuthenticatedRequest: Network error on first attempt — $e");
      rethrow;
    }

    // Check if token expired
    if (!isTokenExpired(response)) {
      return response; // All good — return normally
    }

    print("AuthService.makeAuthenticatedRequest: Token expired, attempting silent re-login");

    // Try silent re-login
    final reLoginSuccess = await silentReLogin();
    if (!reLoginSuccess) {
      print("AuthService.makeAuthenticatedRequest: Silent re-login failed — clearing session");
      await LoginPage.clearSession();
      return null; // Caller should handle null by showing an error or doing nothing
    }

    // Retry the original call with the new token
    print("AuthService.makeAuthenticatedRequest: Retrying API call with new token");
    try {
      response = await apiCall();
      return response;
    } catch (e) {
      print("AuthService.makeAuthenticatedRequest: Network error on retry — $e");
      rethrow;
    }
  }

  /// Call this from SplashScreen to validate the saved token before restoring session.
  /// Makes a lightweight API call to check if the token is still valid.
  /// If expired, silently re-logs in to get a fresh token before navigating to home.
  /// Returns true if session is valid (or was refreshed successfully), false otherwise.
  static Future<bool> validateAndRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('session_jwtToken');
    final String? savedUserId = prefs.getString('session_userId');

    if (savedToken == null || savedToken.isEmpty) {
      return false;
    }

    print("AuthService.validateAndRefreshToken: Checking token validity for $savedUserId");

    // Use the token expiry check by decoding the JWT payload locally
    // JWT format: header.payload.signature — all base64 encoded
    try {
      final parts = savedToken.split('.');
      if (parts.length == 3) {
        // Decode the payload (second part)
        // Base64 padding fix — JWT base64 is not padded
        String payload = parts[1];
        // Add padding if needed
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64Decode(payload));
        final payloadMap = jsonDecode(decoded);

        final int? exp = payloadMap['exp']; // expiry in seconds since epoch
        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();

          print("AuthService.validateAndRefreshToken: Token expires at $expiryTime, now is $now");

          if (expiryTime.isAfter(now)) {
            // Token is still valid — no need to re-login
            print("AuthService.validateAndRefreshToken: Token is valid");
            return true;
          } else {
            // Token has expired — try silent re-login
            print("AuthService.validateAndRefreshToken: Token expired, attempting silent re-login");
            return await silentReLogin();
          }
        }
      }
    } catch (e) {
      print("AuthService.validateAndRefreshToken: Could not decode token locally — $e");
    }

    // If local decode failed, try silent re-login as fallback
    return await silentReLogin();
  }
}