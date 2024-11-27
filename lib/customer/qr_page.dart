import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  User? user;
  String? qrData;

  @override
  void initState() {
    super.initState();
    _generateQRCodeForUser();
  }

  Future<void> _generateQRCodeForUser() async {
    // Get the current user
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not logged in
      return;
    }

    final userId = user!.uid; // Unique user ID
    final DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('user_database')
        .child(userId)
        .child('user_detail');

    // Check if the user's QR code data already exists in Realtime Database
    final DataSnapshot snapshot = await userRef.child('qrCodeData').get();

    if (!snapshot.exists) {
      // Generate QR code data using the user's unique ID
      final qrCodeData =
          'https://membership.com/user/$userId'; // Custom URL or data

      await userRef.update({
        'qrCodeData': qrCodeData,
      });

      setState(() {
        qrData = qrCodeData;
      });
    } else {
      setState(() {
        qrData = snapshot.value as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: qrData == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Scan Me',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: qrData!, // Display the QR code data
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Action for "My Points" button
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                              163, 25, 25, 1), // Background color
                        ),
                        child: const Text(
                          'My Points : 00',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Action for "Redeem My Points" button
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                        ),
                        child: const Text(
                          'Redeem My Points',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
