import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:bakenation_customer/order/payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({required this.shippingTypes, super.key});

  final String shippingTypes;

  @override
  _PickupScreenState createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  bool _isStoreSelected = false;
  String locationPickup = '34 & 36, Jalan SP 5/3, Bandar Saujana Putra,\n'
      '42610 Jenjarom, Selangor';
  late String name;
  late String phoneNumber;
  late Map<String, dynamic> customerDetails;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // TODO: implement initState
    _loadUserData();
    super.initState();
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
          name = data['First Name'] + data['Last Name'];
          phoneNumber = data['Phone No'];
          customerDetails = {
            'name': name,
            'phone': phoneNumber,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerFramePage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup Details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Pickup Store Selection Section
            GestureDetector(
              onTap: () {
                setState(() {
                  _isStoreSelected = !_isStoreSelected;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _isStoreSelected
                      ? const Color.fromRGBO(163, 25, 25, 0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a Pickup Store:',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The Bake Nation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '34 & 36, Jalan SP 5/3, Bandar Saujana Putra,\n'
                            '42610 Jenjarom, Selangor',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Next Button
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isStoreSelected
                    ? () {
                        // Add navigation or other actions here
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                    shippingTypes: widget.shippingTypes,
                                    selectedAddress: customerDetails.toString(),
                                    name: name,
                                    phoneNumber: phoneNumber,
                                    address: locationPickup,
                                  )),
                        );
                      }
                    : null,
                child: const Text(
                  'Next',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
