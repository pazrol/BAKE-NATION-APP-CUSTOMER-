import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  String? _currentPassword;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (_user != null) {
      final snapshot = await _dbRef
          .child('user_database')
          .child(_user.uid)
          .child('user_detail')
          .once();
      final data = snapshot.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _firstNameController.text = data['First Name'] ?? '';
          _lastNameController.text = data['Last Name'] ?? '';
          _emailController.text = data['Email'] ?? '';
          _phoneController.text = data['Phone No'] ?? '';
          _currentPassword = data['Password'] ?? '';
        });
      }
    }
  }

  void _saveUserData() async {
    if (_user != null) {
      Map<String, dynamic> updates = {};

      // First Name update
      if (_firstNameController.text.isNotEmpty) {
        updates['First Name'] = _firstNameController.text;
      }

      // Last Name update
      if (_lastNameController.text.isNotEmpty) {
        updates['Last Name'] = _lastNameController.text;
      }

      // Email update
      if (_emailController.text.isNotEmpty) {
        updates['Email'] = _emailController.text;
      }

      // Phone Number update with +60 prefix if necessary
      if (_phoneController.text.isNotEmpty) {
        String phone = _phoneController.text;
        if (!phone.startsWith('+60')) {
          phone = '+6$phone'; // Add country code +60
        }
        updates['Phone No'] = phone;
      }

      // Handle password change if old and new password are provided
      if (_oldPasswordController.text.isNotEmpty) {
        if (_oldPasswordController.text == _currentPassword) {
          if (_newPasswordController.text.isNotEmpty) {
            // Update password in Firebase Authentication
            try {
              await _user.updatePassword(_newPasswordController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating password: $e')),
              );
              return;
            }
            updates['Password'] = _newPasswordController.text;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Old password is incorrect.')),
          );
          return;
        }
      }

      if (updates.isNotEmpty) {
        await _dbRef
            .child('user_database')
            .child(_user.uid)
            .child('user_detail')
            .update(updates);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        _loadUserData(); // Reload user data after saving
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child:
                        const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hello,',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _firstNameController.text,
                      style: const TextStyle(
                          color: Color.fromRGBO(163, 25, 25, 1),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Input fields
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            // Save button
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  _saveUserData();
                  setState(() {}); // Refresh the page to display updated info
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Text('Save',
                      style: TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(255, 255, 255, 1))),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
