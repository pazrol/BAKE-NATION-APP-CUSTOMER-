import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:bakenation_customer/order/payment.dart';
import 'package:bakenation_customer/addresses/address_detail.dart';
import 'package:bakenation_customer/addresses/edit_address.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShippingScreen extends StatefulWidget {
  const ShippingScreen({required this.shippingTypes, super.key});

  final String shippingTypes;

  @override
  _ShippingScreenState createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  String? selectedAddressId;
  late String name;
  late String phoneNumber;
  late String address;
  Map<String, dynamic>? selectedAddressDetails;
  List<Map<String, dynamic>> addresses = [];
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _setupAddressListener();
  }

  void _setupAddressListener() {
    if (userId != null) {
      DatabaseReference addressRef = FirebaseDatabase.instance
          .ref()
          .child('user_database')
          .child(userId!)
          .child('address_detail');

      addressRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> addressesMap =
              event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            addresses = addressesMap.entries.map((entry) {
              return {
                'addressId': entry.key,
                'full_name': entry.value['full_name'],
                'phone_number': entry.value['phone_number'],
                'unit': entry.value['unit'],
                'address': entry.value['address'],
                'postcode': entry.value['postcode'],
                'city': entry.value['city'],
                'state': entry.value['state'],
              };
            }).toList();
          });
        }
      });
    }
  }

  Future<void> _fetchAddresses() async {
    if (userId != null) {
      DatabaseReference addressRef = FirebaseDatabase.instance
          .ref()
          .child('user_database')
          .child(userId!)
          .child('address_detail');

      addressRef.once().then((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> addressesMap =
              event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            addresses = addressesMap.entries.map((entry) {
              return {
                'addressId': entry.key,
                'full_name': entry.value['full_name'],
                'phone_number': entry.value['phone_number'],
                'unit': entry.value['unit'],
                'address': entry.value['address'],
                'postcode': entry.value['postcode'],
                'city': entry.value['city'],
                'state': entry.value['state'],
              };
            }).toList();
            name = addresses[0]['full_name'];
            phoneNumber = addresses[0]['phone_number'];
            address =
                'No ${addresses[0]['unit'] ?? ''} ${addresses[0]['address'] ?? ''}, ${addresses[0]['postcode'] ?? ''}, ${addresses[0]['city'] ?? ''}, ${addresses[0]['state'] ?? ''}.';
            print('address');
            print(addresses[0]['full_name']);
            print(
                'No ${addresses[0]['unit'] ?? ''} ${addresses[0]['address'] ?? ''}, ${addresses[0]['postcode'] ?? ''}, ${addresses[0]['city'] ?? ''}, ${addresses[0]['state'] ?? ''}.');
          });
        }
      });
    }
  }

  void _navigateToNewAddressScreen() async {
    final selectedAddressResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressDetailPage(),
      ),
    );

    if (selectedAddressResult != null && selectedAddressResult is String) {
      _fetchAddresses();
    }
  }

  void _navigateToEditAddressScreen(String addressId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddress(addressId: addressId),
      ),
    );
    _fetchAddresses();
  }

  void _selectAddress(Map<String, dynamic> address) {
    setState(() {
      selectedAddressId = address['addressId'];
      selectedAddressDetails =
          address; // Save the full details of the selected address
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping'),
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
              'Shipping Details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _navigateToNewAddressScreen,
                child: const Text(
                  'Add Address',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Address List Section
            Expanded(
              child: ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return Card(
                    color: selectedAddressId == address['addressId']
                        ? const Color.fromRGBO(163, 25, 25, 0.2)
                        : Colors.grey[200],
                    child: ListTile(
                      title: Text(
                        address['full_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${address['unit']}, ${address['address']}, ${address['city']}, ${address['state']}'),
                          Text('${address['phone_number']}'),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          // Edit Address Functionality
                          _navigateToEditAddressScreen(address['addressId']);
                        },
                        child: const Text(
                          'Edit',
                          style:
                              TextStyle(color: Color.fromRGBO(163, 25, 25, 1)),
                        ),
                      ),
                      onTap: () => _selectAddress(
                          address), // Update the selected address
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

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
                onPressed: selectedAddressId == null
                    ? null
                    : () {
                        // Proceed with payment, pass the selected address to the PaymentScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                    shippingTypes: widget.shippingTypes,
                                    selectedAddress:
                                        selectedAddressDetails.toString(),
                                    name: name,
                                    phoneNumber: phoneNumber,
                                    address:
                                        address, // Pass the selected address details
                                  )),
                        );
                      },
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
