import 'package:bakenation_customer/customer/profile.dart';
import 'package:bakenation_customer/voucher/voucher.dart';
import 'package:flutter/material.dart';
import 'package:bakenation_customer/customer/homepage.dart';
import 'package:bakenation_customer/product/product.dart';
import 'package:bakenation_customer/order/cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CustomerFramePage extends StatefulWidget {
  const CustomerFramePage({super.key});

  @override
  _CustomerFramePageState createState() => _CustomerFramePageState();
}

class _CustomerFramePageState extends State<CustomerFramePage> {
  int _selectedIndex = 0;
  String selectedDetaildPage = 'janganTukar';
  late Widget page;
  int _cartItemCount = 0;

  final User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _fetchCartItemCount();
  }

  // Fetch cart item count from Firebase
  void _fetchCartItemCount() {
    if (user != null) {
      final cartRef = _database.child('user_database/${user!.uid}/cart');

      // Listen for changes in the cart data
      cartRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          final cartData = event.snapshot.value as Map<dynamic, dynamic>;
          int itemCount = cartData.values
              .fold(0, (sum, item) => sum + (item['quantity'] as num).toInt());

          setState(() {
            _cartItemCount = itemCount;
          });
        } else {
          setState(() {
            _cartItemCount = 0;
          });
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      selectedDetaildPage = 'janganTukar';
    });
  }

  void callbackPage(String selectedPage, Widget pageWidget) {
    setState(() {
      selectedDetaildPage = selectedPage;
      page = pageWidget;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          title: Center(
            child: Image.asset(
              'assets/bn_logo.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            IconButton(
              icon: Badge(
                label: Text('$_cartItemCount'),
                child: const Icon(Icons.shopping_cart),
              ), // Cart icon with dynamic badge count
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ],
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      body: selectedDetaildPage == 'janganTukar'
          ? <Widget>[
              // Home page
              HomePage(
                callbackPage: (selectedDetaildPage, page) {
                  callbackPage(selectedDetaildPage, page);
                },
              ),
              // Product page
              ProductPage(
                callbackPage: (selectedDetaildPage, page) {
                  callbackPage(selectedDetaildPage, page);
                },
              ),
              // QR code page

              // Voucher page
              const VoucherPage(),
              // Profile page
              ProfilePage(
                callbackPage: (selectedDetaildPage, page) {
                  callbackPage(selectedDetaildPage, page);
                },
              ),
            ][_selectedIndex]
          : selectedDetaildPage == 'tukarPage'
              ? page
              : const Text('No page to show'), // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            const Color.fromRGBO(163, 25, 25, 1), // Selected icon color
        unselectedItemColor: Colors.grey, // Unselected icon color
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
