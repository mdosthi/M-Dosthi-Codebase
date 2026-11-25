import 'package:mdosthi_app/login_page.dart';
import 'package:mdosthi_app/utils/NetworkSpeedChecker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mdosthi_app/main.dart';
import 'dart:io';

import '../EditProfilePage.dart';

class HamburgerMenu extends StatefulWidget {
  final String userName;
  final String email;
  final List<Widget> pages;
  final List<IconData> icons;
  final List<String>
      pageTitles; // These will be translated but we'll use index instead for identification
  final VoidCallback? reloadCallback;

  const HamburgerMenu({
    super.key,
    required this.userName,
    required this.email,
    required this.pages,
    required this.icons,
    required this.pageTitles,
    this.reloadCallback,
  });

  @override
  _HamburgerMenuState createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  // Menu item identifiers - not dependent on translated strings
  // ignore: constant_identifier_names
  static const int MENU_HOME = 0;
  // ignore: constant_identifier_names
  static const int MENU_EDIT_PROFILE = 1;
  // ignore: constant_identifier_names
  static const int MENU_LOGOUT = 2;
  // ignore: constant_identifier_names
  static const int MENU_BANDWIDTH = 3;
  // ignore: constant_identifier_names
  static const int MENU_CHANGE_USERNAME = 4;

  Future<void> changeUsername(BuildContext context) async {
    TextEditingController usernameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(hintText: 'Enter new username'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newUsername = usernameController.text;
                // Validate new username if needed
                setState(() {
                  LoginPage.username = newUsername; // Modify the username
                });
                if (widget.reloadCallback != null) {
                  widget.reloadCallback!(); // Callback to reload the menu
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkNetworkSpeed(BuildContext context) async {
    const url =
        "https://images.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png";
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final elapsed = stopwatch.elapsedMilliseconds;
        final speedInKbps =
            ((response.bodyBytes.length / 1024) / (elapsed / 1000)) *
                8; // Calculate download speed in Kbps

        // Show download speed in an AlertDialog
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Network Speed'),
              content: Text(
                  'Download speed: ${speedInKbps.toStringAsFixed(2)} Kbps'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Show an error dialog if the download failed
        int networkError = 1;

        try {
          final result = await InternetAddress.lookup('example.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('connected');
          }
        } on SocketException catch (_) {
          print('not connected');
          networkError = 0;
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Network Error!'),
                content: const Text('Check your internet connection.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }

        if (networkError == 0) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(
                    'Failed to download the file. Status code: ${response.statusCode}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      // Show an error dialog in case of an exception
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> showProgressDialog(BuildContext context, String message,
      ValueNotifier<double> progressNotifier) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 20),
                  Text('${(progress * 100).toStringAsFixed(2)}%'),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Helper method that determines menu item action based on index position
  void _handleMenuItemTap(BuildContext context, int index) {
    // Get the corresponding page widget type
    final Widget pageWidget = widget.pages[index];

    // Check the page type or index position instead of comparing strings
    if (pageWidget is NetworkSpeedChecker) {
      checkNetworkSpeed(context);
    } else if (index == MENU_CHANGE_USERNAME) {
      changeUsername(context);
    } else if (index == MENU_EDIT_PROFILE) {
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EditProfilePage()),
      );
    } else if (index == MENU_HOME) {
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => pageWidget),
      );
    } else if (index == MENU_LOGOUT) {
      // Clear the saved session from SharedPreferences so the user is not
      // auto-logged-in the next time they open the app.
      LoginPage.clearSession().then((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      });
    } else {
      // Default case - just navigate to the page
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => pageWidget),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(loginAccount),
            accountEmail: Text("Username - ${widget.email}"),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          Expanded(
            child: ListView.builder(
              // Only include the regular menu items
              itemCount: widget.pages.length, // Regular pages only
              itemBuilder: (BuildContext context, int index) {
                // Regular menu items
                return ListTile(
                  leading: Icon(widget.icons[index]),
                  title: Text(widget.pageTitles[index]),
                  onTap: () => _handleMenuItemTap(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
