import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:flutter/material.dart';
import 'package:bakenation_customer/order/cod.dart';
import 'package:bakenation_customer/order/pickup.dart';
import 'package:bakenation_customer/order/postage.dart';

class DeliveryOptions extends StatefulWidget {
  const DeliveryOptions({super.key});

  @override
  _DeliveryOptionsState createState() => _DeliveryOptionsState();
}

class _DeliveryOptionsState extends State<DeliveryOptions> {
  String selectedOption = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
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
            const SizedBox(height: 16),
            const Text(
              "Select Your Delivery Options :",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Delivery options
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  deliveryOption('COD', Icons.directions_bike, 'COD'),
                  const SizedBox(height: 16),
                  deliveryOption('Pickup', Icons.shopping_bag, 'PICKUP'),
                  const SizedBox(height: 16),
                  deliveryOption('Postage', Icons.local_shipping, 'POSTAGE'),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            // Next button at the bottom
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: selectedOption.isEmpty
                    ? null // Disable button if no option is selected
                    : () {
                        if (selectedOption == 'COD') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DeliveryScreen(
                                      shippingTypes: 'COD',
                                    )),
                          );
                        } else if (selectedOption == 'PICKUP') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PickupScreen(
                                      shippingTypes: 'PICKUP',
                                    )),
                          );
                        } else if (selectedOption == 'POSTAGE') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ShippingScreen(
                                      shippingTypes: 'POSTAGE',
                                    )),
                          );
                        }
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

  Widget deliveryOption(String title, IconData icon, String option) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = option;
        });
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedOption == option ? Colors.grey[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: selectedOption == option
              ? Border.all(
                  color: const Color.fromRGBO(163, 25, 25, 1), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.black,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
