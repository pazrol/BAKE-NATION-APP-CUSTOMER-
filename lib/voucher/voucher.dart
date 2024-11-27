import 'package:bakenation_customer/voucher/voucher_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VoucherPage(),
    );
  }
}

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  _VoucherPageState createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseReference _userRef;
  String points = '';
  List<Map<String, dynamic>> vouchers = [];
  List<Map<String, dynamic>> activeVouchers = [];
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print("User is not signed in");
      return;
    }

    _userRef = FirebaseDatabase.instance
        .ref()
        .child('user_database')
        .child(userId)
        .child('rewards')
        .child('points');

    _userRef.onValue.listen((DatabaseEvent event) {
      setState(() {
        points = event.snapshot.value != null
            ? event.snapshot.value.toString()
            : '0';
      });
    });

    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    final vouchersRef = FirebaseDatabase.instance.ref().child('vouchers');
    final snapshot = await vouchersRef.get();
    final customerVouchersRef = FirebaseDatabase.instance
        .ref()
        .child('user_database')
        .child(user!.uid)
        .child('rewards')
        .child('vouchers');
    final customerVouchersRefsnapshot = await customerVouchersRef.get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedVouchers = [];
      for (var voucher in snapshot.children) {
        String status = voucher.child('status').value.toString();

        if (status == 'active') {
          fetchedVouchers.add({
            'voucherId': voucher.key,
            'imageUrl': voucher.child('image_url').value.toString(),
          });
        }
      }
      setState(() {
        vouchers = fetchedVouchers;
      });
    } else {
      print("No vouchers found");
    }

    if (customerVouchersRefsnapshot.exists) {
      List<Map<String, dynamic>> fetchedCustomerVouchers = [];
      for (var voucher in customerVouchersRefsnapshot.children) {
        fetchedCustomerVouchers.add({
          'voucherId': voucher.key,
          'imageUrl': voucher.child('image_url').value.toString(),
        });
      }
      setState(() {
        activeVouchers = fetchedCustomerVouchers;
      });
    } else {
      print("No vouchers found");
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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: const Color.fromRGBO(163, 25, 25, 1),
            tabs: const [
              Tab(text: 'Rewards'),
              Tab(text: 'Active Rewards'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(163, 25, 25, 1),
                        borderRadius: BorderRadius.circular(37),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'My Points : $points',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vouchers.isEmpty)
                      const Center(
                        child: Text(
                          'No vouchers',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ...vouchers.map((voucher) => buildVoucherCard(
                            voucher['voucherId'] ?? '',
                            voucher['imageUrl'] ?? '',
                          )),
                  ],
                ),
                ListView(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(163, 25, 25, 1),
                        borderRadius: BorderRadius.circular(37),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'My Points : $points',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeVouchers.isEmpty)
                      const Center(
                        child: Text(
                          'No vouchers',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ...activeVouchers.map((voucher) => buildVoucherCard(
                            voucher['voucherId'] ?? '',
                            voucher['imageUrl'] ?? '',
                          )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
