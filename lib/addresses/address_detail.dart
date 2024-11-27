import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AddressDetailPage(),
    );
  }
}

class AddressDetailPage extends StatefulWidget {
  const AddressDetailPage({super.key});

  @override
  _AddressDetailPageState createState() => _AddressDetailPageState();
}

class _AddressDetailPageState extends State<AddressDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Get the phone number and format it with '+6'
        String formattedPhoneNumber = '+6${_phoneNumberController.text.trim()}';

        final addressDetails = {
          "full_name": _fullNameController.text,
          "phone_number": formattedPhoneNumber,
          "address": _addressController.text,
          "unit": _unitController.text,
          "postcode": _postcodeController.text,
          "city": _cityController.text,
          "state": _stateController.text,
        };

        try {
          // Generate a unique key for each address
          await _database
              .child("user_database/${user.uid}/address_detail")
              .push() // Using push() to create a unique key
              .set(addressDetails);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );

          // Clear the form
          _formKey.currentState!.reset();
          _fullNameController.clear();
          _phoneNumberController.clear();
          _addressController.clear();
          _unitController.clear();
          _postcodeController.clear();
          _cityController.clear();
          _stateController.clear();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving address: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Address Details:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(_fullNameController, 'Full Name'),
                _buildTextField(_phoneNumberController, 'Phone Number'),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_unitController, 'Unit/House Number'),
                _buildTextField(_postcodeController, 'Postcode'),
                _buildTextField(_cityController, 'City'),
                _buildTextField(_stateController, 'State'),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                const Divider(),
                ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(27),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
