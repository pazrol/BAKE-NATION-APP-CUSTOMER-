import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bakenation_customer/addresses/address_detail.dart';
import 'package:bakenation_customer/addresses/edit_address.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AddressScreen(),
    );
  }
}

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;
      final addressRef =
          _database.child("user_database/$userId/address_detail");

      addressRef.onValue.listen((event) {
        final addresses = <Map<String, dynamic>>[];
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          data.forEach((key, value) {
            final address = {
              "id": key,
              "full_name": value["full_name"],
              "phone_number": value["phone_number"],
              "unit": value["unit"],
              "address": value["address"],
              "postcode": value["postcode"],
              "city": value["city"],
              "state": value["state"],
            };
            addresses.add(address);
          });
        }

        setState(() {
          _addresses = addresses;
        });
      });
    }
  }

  void _selectAddress(Map<String, dynamic> address) {
    final selectedAddress =
        'No ${address['unit'] ?? ''} ${address['address'] ?? ''}, ${address['postcode'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}.';
    Navigator.pop(context, selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddressDetailPage()),
                  );
                },
                child: const Text(
                  'Add Address',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _addresses.isEmpty
                  ? const Center(
                      child: Text(
                      "No Addresses Available",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                  : ListView.builder(
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return GestureDetector(
                          onTap: () => _selectAddress(address),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          address['full_name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          '|',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          address['phone_number'] ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditAddress(
                                              addressId: address['id'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Edit",
                                        style: TextStyle(
                                          color: Color.fromRGBO(163, 25, 25, 1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No ${address['unit'] ?? ''} ${address['address'] ?? ''},\n ${address['postcode'] ?? ''},${address['city'] ?? ''}, ${address['state'] ?? ''}.',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
