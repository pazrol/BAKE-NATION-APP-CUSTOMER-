import 'package:bakenation_customer/voucher/voucher_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VoucherList extends StatefulWidget {
  const VoucherList({super.key});

  @override
  _VoucherListState createState() => _VoucherListState();
}

class _VoucherListState extends State<VoucherList> {
  late DatabaseReference _userVouchersRef;
  List<Map<String, dynamic>> redeemedVouchers = [];

  @override
  void initState() {
    super.initState();
    _fetchRedeemedVouchers();
  }

  Future<void> _fetchRedeemedVouchers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print("User is not signed in");
      return;
    }

    _userVouchersRef = FirebaseDatabase.instance
        .ref()
        .child('user_database')
        .child(userId)
        .child('redeemed_vouchers');

    final snapshot = await _userVouchersRef.get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedVouchers = [];
      for (var voucher in snapshot.children) {
        fetchedVouchers.add({
          'voucherId': voucher.key,
          'imageUrl': voucher.child('image_url').value.toString(),
        });
      }
      setState(() {
        redeemedVouchers = fetchedVouchers;
      });
    } else {
      print("No redeemed vouchers found");
    }
  }

  Widget buildVoucherCard(String voucherId, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoucherDetailPage(voucherId: voucherId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeemed Vouchers'),
        backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
      ),
      body: redeemedVouchers.isEmpty
          ? const Center(
              child: Text(
                'No redeemed vouchers found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView(
              children: redeemedVouchers
                  .map((voucher) => buildVoucherCard(
                        voucher['voucherId'] ?? '',
                        voucher['imageUrl'] ?? '',
                      ))
                  .toList(),
            ),
    );
  }
}
