import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EditAddress(
          addressId: 'example_address_id'), // Provide addressId here
    );
  }
}

class EditAddress extends StatefulWidget {
  final String addressId;

  const EditAddress({super.key, required this.addressId});

  @override
  _EditAddressPageState createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddress> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _fetchAddressDetails();
  }

  void _fetchAddressDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final snapshot = await _database
            .child(
                "user_database/${user.uid}/address_detail/${widget.addressId}")
            .get();

        if (snapshot.exists) {
          final addressDetails = snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            _fullNameController.text = addressDetails["full_name"] ?? '';
            // Prepend '+6' when fetching the phone number
            _phoneNumberController.text = addressDetails["phone_number"] ?? '';
            _addressController.text = addressDetails["address"] ?? '';
            _unitController.text = addressDetails["unit"] ?? '';
            _postcodeController.text = addressDetails["postcode"] ?? '';
            _cityController.text = addressDetails["city"] ?? '';
            _stateController.text = addressDetails["state"] ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No address found')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching address: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Prepend '+6' to the phone number before saving
        String formattedPhoneNumber = '+6${_phoneNumberController.text.trim()}';

        final addressDetails = {
          "full_name": _fullNameController.text,
          "phone_number": formattedPhoneNumber, // Save the phone number with +6
          "address": _addressController.text,
          "unit": _unitController.text,
          "postcode": _postcodeController.text,
          "city": _cityController.text,
          "state": _stateController.text,
        };

        try {
          // Update the existing address details
          await _database
              .child(
                  "user_database/${user.uid}/address_detail/${widget.addressId}")
              .set(addressDetails);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );

          // Navigate back to the address page
          Navigator.pop(context);
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
        title: const Text('Shipping',
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
                    'Shipping Details:',
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
                    'Save Changes',
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
