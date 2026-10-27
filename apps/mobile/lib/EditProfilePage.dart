import 'package:app_001/change_password_page.dart';
import 'package:app_001/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:app_001/login_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'loginid': TextEditingController(),
    'userid': TextEditingController(),
    'age': TextEditingController(),
    'sex': TextEditingController(),
    'address': TextEditingController(),
    'mobile': TextEditingController(),
    'email': TextEditingController(),
    'qualification': TextEditingController(),
    'designation': TextEditingController(),
  };

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userInfo = await UserProfileService.getUserInfo();

      setState(() {
        _controllers.forEach((key, controller) {
          controller.text = userInfo[key]?.toString() ?? '';
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Collect updated user info
      final updatedInfo = {
        'userid': LoginPage.userId, // Required for identification
        'name': _controllers['name']?.text,
        'age': _controllers['age']?.text,
        'sex': _controllers['sex']?.text,
        'address': _controllers['address']?.text,
        'mobile': _controllers['mobile']?.text,
        'email': _controllers['email']?.text,
        'qualification': _controllers['qualification']?.text,
        'designation': _controllers['designation']?.text,
      };

      final success = await UserProfileService.updateUserInfo(updatedInfo);

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Profile updated successfully'
                : 'Failed to update profile'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, String controllerKey,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers[controllerKey],
            enabled: _isEditing && enabled,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Enter $label',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateUserInfo,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _fetchUserInfo(); // Reset to original values
                    });
                  },
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField('Name', 'name'),
                          _buildTextField('Login ID', 'loginid',
                              enabled: false),
                          _buildTextField('User ID', 'userid', enabled: false),
                          _buildTextField('Age', 'age'),
                          _buildTextField('Sex', 'sex'),
                          _buildTextField('Address', 'address'),
                          _buildTextField('Mobile', 'mobile'),
                          _buildTextField('Email', 'email'),
                          _buildTextField('Qualification', 'qualification'),
                          _buildTextField('Designation', 'designation'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
