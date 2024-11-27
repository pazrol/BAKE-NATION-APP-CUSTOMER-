import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:bakenation_customer/order/payment.dart';
import 'package:bakenation_customer/addresses/address.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({required this.shippingTypes, super.key});

  final String shippingTypes;

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  String? selectedTimeSlot;
  String deliveryAddress = 'Fetching address...';
  late Map<dynamic, dynamic> codAddress;
  late String name;
  late String phoneNumber;
  late String address;
  bool isDeliverable = false;
  double? customerLatitude;
  double? customerLongitude;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Coordinates of the predefined address (34 & 36, Jalan SP 5/3, Bandar Saujana Putra)
  final double predefinedLatitude = 2.9444547685545244; // Bake Nation latitude
  final double predefinedLongitude =
      101.58585053862977; // Bake Nation longitude

  @override
  void initState() {
    super.initState();
    _fetchAddressDetails();
  }

  Future<void> _fetchAddressDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;
      final addressRef =
          _database.child("user_database/$userId/address_detail");

      final snapshot = await addressRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.isNotEmpty) {
          final firstAddress = data.values.first as Map<dynamic, dynamic>;
          setState(() {
            deliveryAddress =
                'No ${firstAddress['unit'] ?? ''} ${firstAddress['address'] ?? ''}, ${firstAddress['postcode'] ?? ''}, ${firstAddress['city'] ?? ''}, ${firstAddress['state'] ?? ''}.';

            codAddress = firstAddress;
            name = firstAddress['full_name'];
            phoneNumber = firstAddress['phone_number'];
            address = deliveryAddress;
          });
          // Convert address to latitude and longitude
          _getLatLongFromAddress(firstAddress);
        } else {
          setState(() {
            deliveryAddress = 'No address available.';
            isDeliverable = false;
          });
        }
      } else {
        setState(() {
          deliveryAddress = 'No address available.';
          isDeliverable = false;
        });
      }
    }
  }

  Future<void> _getLatLongFromAddress(Map<dynamic, dynamic> address) async {
    String fullAddress =
        "${address['address']}, ${address['city']}, ${address['state']}, ${address['postcode']}";

    try {
      // Geocoding to get latitude and longitude from the full address
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        setState(() {
          customerLatitude = locations.first.latitude;
          customerLongitude = locations.first.longitude;
        });

        // Check if the delivery address is within 7km
        _checkDeliveryRadius();
      } else {
        setState(() {
          isDeliverable = false;
        });
      }
    } catch (e) {
      setState(() {
        isDeliverable = false;
      });
    }
  }

  Future<void> _checkDeliveryRadius() async {
    if (customerLatitude != null && customerLongitude != null) {
      // Calculate distance between predefined location and customer address
      final double distanceInMeters = Geolocator.distanceBetween(
        predefinedLatitude,
        predefinedLongitude,
        customerLatitude!,
        customerLongitude!,
      );

      // Check if the distance is within 7km (7000 meters)
      setState(() {
        isDeliverable = distanceInMeters <= 7000;
      });
    } else {
      setState(() {
        isDeliverable = false;
      });
    }
  }

  // Update available time slots based on the current time

  void _navigateToAddressScreen() async {
    final selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressScreen(),
      ),
    );

    if (selectedAddress != null && selectedAddress is String) {
      setState(() {
        deliveryAddress = selectedAddress;
      });
      // Convert updated address to latitude and longitude
      _getLatLongFromAddress({
        'address': selectedAddress,
        'city': '',
        'state': '',
        'postcode': '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery',
        ),
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
            // Delivery Address Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Delivering to:\n$deliveryAddress',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _navigateToAddressScreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Status Message
            if (!isDeliverable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50], // Light red background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red), // Red border
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This location is outside from our delivery area.(7Km)',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Time Slot Selection Section

            const Spacer(),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isDeliverable
                    ? () {
                        // Proceed with payment if deliverable
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                    shippingTypes: widget.shippingTypes,
                                    selectedAddress: codAddress.toString(),
                                    name: name,
                                    phoneNumber: phoneNumber,
                                    address:
                                        address, // Pass the selected address
                                  )),
                        );
                      }
                    : null, // Disable button if not deliverable
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
