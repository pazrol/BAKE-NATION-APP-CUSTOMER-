import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoucherDetailPage extends StatefulWidget {
  static const String routeName = '/voucherDetail';

  final String voucherId;

  const VoucherDetailPage({super.key, required this.voucherId});

  @override
  _VoucherDetailPageState createState() => _VoucherDetailPageState();
}

class _VoucherDetailPageState extends State<VoucherDetailPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("vouchers");
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref("user_database");

  String? title;
  String? description;
  String? imageUrl;
  String? startDate;
  String? endDate;
  int? pointsRequired;
  int? userPoints;
  bool isLoading = true;
  bool isRedeeming = false;
  bool isRedeemed = false;

  @override
  void initState() {
    super.initState();
    _fetchVoucherData();
  }

  Future<void> _fetchVoucherData() async {
    try {
      final snapshot = await _dbRef.child(widget.voucherId).get();
      if (snapshot.exists) {
        final voucherData = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          title = voucherData['title'] ?? 'No Title';
          description = voucherData['description'] ?? 'No Description';
          imageUrl = voucherData['image_url'];
          startDate = voucherData['startDate'] ?? 'No Start Date';
          endDate = voucherData['endDate'] ?? 'No End Date';
          pointsRequired = _convertToInt(voucherData['pointsRedemption']);
        });

        // Fetch user points after loading voucher data
        await _fetchUserPoints();

        // Check if voucher is already redeemed
        await _checkIfRedeemed();
      } else {
        setState(() {
          title = 'Voucher Not Found';
        });
      }
    } catch (error) {
      print("Error fetching voucher data: $error");
      setState(() {
        title = 'Error loading voucher data';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserPoints() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userSnapshot =
            await _userRef.child(userId).child('rewards').child('points').get();

        if (userSnapshot.exists) {
          setState(() {
            userPoints = userSnapshot.value as int?;
          });
        }
      }
    } catch (error) {
      print("Error fetching user points: $error");
    }
  }

  Future<void> _checkIfRedeemed() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final userVouchersRef =
            _userRef.child(userId).child('rewards').child('vouchers');
        final redeemedVoucherSnapshot =
            await userVouchersRef.child(widget.voucherId).get();

        if (redeemedVoucherSnapshot.exists) {
          setState(() {
            isRedeemed = true; // Mark the voucher as already redeemed
          });
        }
      } catch (error) {
        print("Error checking if voucher is redeemed: $error");
      }
    }
  }

  Future<void> _redeemVoucher(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (userPoints == null || pointsRequired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to fetch points or voucher data.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isRedeemed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already redeemed this voucher.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (userPoints! >= pointsRequired!) {
      setState(() {
        isRedeeming = true;
      });

      final userVouchersRef =
          _userRef.child(userId).child('rewards').child('vouchers');

      final limitVoucher = _dbRef.child(widget.voucherId);

      try {
        // Get the current value of 'redeemLimit'
        final snapshot = await limitVoucher.child('redeemLimit').get();
        if (snapshot.value != null) {
          int currentLimit = int.parse(snapshot.value
              .toString()); // Get the current value of redeemLimit
          int updatedLimit = currentLimit - 1; // Decrement the value by 1

          // Update the redeemLimit with the new value
          await limitVoucher.update({'redeemLimit': updatedLimit});
        } else {
          print('redeemLimit not found!');
        }
      } catch (e) {
        print(e.toString());
      }
      try {
        // Redeem the voucher by adding it to user's voucher list
        await userVouchersRef.child(widget.voucherId).set({
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'startDate': startDate,
          'endDate': endDate,
          'pointsRequired': pointsRequired,
        });

        final newPoints = userPoints! - pointsRequired!;
        await _userRef
            .child(userId)
            .child('rewards')
            .child('points')
            .set(newPoints);

        setState(() {
          isRedeemed = true;
          userPoints = newPoints; // Update user points locally
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher redeemed successfully!'),
            duration: Duration(seconds: 0),
          ),
        );
      } catch (error) {
        print("Error redeeming voucher: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error redeeming voucher.'),
            duration: Duration(seconds: 0),
          ),
        );
      } finally {
        setState(() {
          isRedeeming = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points to redeem this voucher.'),
          duration: Duration(seconds: 0),
        ),
      );
    }
  }

  int _convertToInt(dynamic value) {
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return value is int ? value : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voucher Details'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final canRedeem = userPoints != null &&
        pointsRequired != null &&
        userPoints! >= pointsRequired! &&
        !isRedeemed;
    final buttonLabel = isRedeemed ? 'Redeemed' : 'Redeem';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              title ?? 'No Title',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(description ?? 'No Description',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Divider(),
            Text(
              'Valid from: $startDate - $endDate',
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Points Required: $pointsRequired',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (userPoints != null)
              Text(
                'Your Points: $userPoints',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 5),

            // Button Section
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canRedeem && !isRedeemed
                    ? () =>
                        _redeemVoucher(context) // Allow redeem if not redeemed
                    : null, // Disable button if already redeemed
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem && !isRedeemed
                      ? const Color.fromRGBO(163, 25, 25, 1)
                      : Colors.grey, // Change color if disabled
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(29),
                  ),
                ),
                child: isRedeeming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(buttonLabel, // Show the "Redeemed" label if redeemed
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
