import 'package:bakenation_customer/customer/customer_frame.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen(
      {required this.shippingTypes,
      required this.selectedAddress,
      required this.name,
      required this.phoneNumber,
      required this.address,
      super.key});

  final String shippingTypes;
  final String selectedAddress;
  final String name;
  final String phoneNumber;
  final String address;

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _userVouchers = [];
  double _subtotal = 0.0;
  double _sst = 0.0;
  double discount = 0.0;
  final double _processingFee = 5.0;
  double _totalPayment = 0.0;
  String _paymentOption = ''; // Store selected payment option
  String _setVoucherID = ''; // Store selected voucher ID
  String _setVoucherPoint = ''; // Store selected voucher point
  String _setVoucherName = ''; // Store selected voucher name
  bool _setisHaveVoucher = false;
  Timer? _timer;
  int _remainingTime = 120; // 2 minutes timer
  String _orderId = '';
  String _successMessage = ''; // Message to show after order completion

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchUserVouchers();
  }

  // Fetch user voucher
  Future<void> _fetchUserVouchers() async {
    if (user == null) return;

    final voucherRef =
        _database.child('user_database/${user!.uid}/rewards/vouchers');
    final snapshot = await voucherRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final vouchers = data.entries.map((entry) {
        final itemData = entry.value as Map<dynamic, dynamic>;
        return {
          'voucherID': entry.key,
          'voucherName': itemData['title'],
          'voucherPoint': itemData['pointsRequired'],
        };
      }).toList();

      setState(() {
        _userVouchers = vouchers;
        _calculateSubtotal();
      });
    }
  }

  // Fetch cart items
  Future<void> _fetchCartItems() async {
    if (user == null) return;

    final cartRef = _database.child('user_database/${user!.uid}/cart');
    final snapshot = await cartRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final cartItems = data.entries.map((entry) {
        final itemData = entry.value as Map<dynamic, dynamic>;
        return {
          'productId': entry.key,
          'productName': itemData['productName'],
          'productPrice': itemData['productPrice'],
          'imageUrl': itemData['imageUrl'],
          'quantity': itemData['quantity'],
        };
      }).toList();

      setState(() {
        _cartItems = cartItems;
        _calculateSubtotal();
      });
    }
  }

  void _calculateSubtotal() {
    if (_setisHaveVoucher) {
      discount = int.parse(_setVoucherPoint) / 100;
      _subtotal = _cartItems.fold(
        0.0,
        (total, item) => total + (item['productPrice'] * item['quantity']),
      );
      _sst = _subtotal * 0.06; // 6% SST
      _totalPayment = (_subtotal + _sst + _processingFee) - discount;
    } else {
      _subtotal = _cartItems.fold(
        0.0,
        (total, item) => total + (item['productPrice'] * item['quantity']),
      );
      _sst = _subtotal * 0.06; // 6% SST
      _totalPayment = _subtotal + _sst + _processingFee;
    }
  }

  // Function to generate custom Order ID
  String generateOrderId() {
    final randomNumber =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 10000))
            .toString()
            .substring(1); // Generates a random 4-digit number
    return 'BN3921$randomNumber';
  }

  // Process payment
  Future<void> _processPayment() async {
    if (user == null) return;

    // Fetch user details, including address
    final userRef = _database.child('user_database/${user!.uid}');
    final userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details not found')),
      );
      return;
    }

    final userData = userSnapshot.value as Map<dynamic, dynamic>;
    final userName = userData['name'] ?? 'Unknown';
    final userAddress = userData['address'] ?? 'No address provided';

    // Calculate points based on total payment
    int pointsEarned = ((_totalPayment / 100) * 99).floor(); // RM3 = 2 point

    // Generate unique order ID using the custom function
    _orderId = generateOrderId(); // Generate custom order ID

    // Show the payment dialog
    _showPaymentDialog(pointsEarned);
  }

  // Update item quantity
  void _updateItemQuantity(int index, int newQuantity) async {
    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
      _calculateSubtotal();
    });

    if (user == null) return;

    final productId = _cartItems[index]['productId'];
    final cartRef =
        _database.child('user_database/${user!.uid}/cart/$productId');

    await cartRef.update({
      'quantity': newQuantity,
    });
  }

  // Remove item
  void _removeItem(int index) async {
    if (user == null) return;

    final productId = _cartItems[index]['productId'];
    final cartRef =
        _database.child('user_database/${user!.uid}/cart/$productId');

    // Remove the item from Firebase
    await cartRef.remove();

    // Remove the item from the local list
    setState(() {
      _cartItems.removeAt(index);
      _calculateSubtotal();
    });
  }

  void _startTimer(int pointsEarned) {
    // Create a SnackBar to show remaining time
    final snackBar = SnackBar(
      content: Text('Time Remaining: $_remainingTime seconds'),
      duration: const Duration(seconds: 1),
      backgroundColor: const Color.fromRGBO(
          163, 25, 25, 1), // You can change the color to any of your choice
    );

    // Show the initial SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Initialize the timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        _timer?.cancel();
        _completeOrder(pointsEarned);
        Navigator.pop(context); // Close the dialog when time finishes
      } else {
        setState(() {
          _remainingTime--; // Decrease the remaining time
        });

        // Show updated SnackBar with new remaining time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time Remaining: $_remainingTime seconds'),
            duration:
                const Duration(seconds: 1), // Show the Snackbar for 1 second
            backgroundColor: const Color.fromRGBO(
                163, 25, 25, 1), // Same background color for consistency
          ),
        );
      }
    });
  }

  void _showPaymentDialog(int pointsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment in Progress',
                style: TextStyle(fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _timer?.cancel(); // Stop the timer when closing the dialog
                  Navigator.pop(context); // Close the dialog
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/qr_payment.jpg', height: 200),
              const SizedBox(height: 20),
              // Bank account and name info
              const Text(
                'ACCOUNT NUMBER: BAKE NATION',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'BANK: MAYBANK',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'NAME: BAKE NATION',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              onPressed: () async {
                setState(() {
                  _timer?.cancel(); // Stop the timer when the button is pressed
                });
                await _completeOrder(pointsEarned); // Complete the order
                Navigator.pop(context); // Close the dialog

                // Navigate to CustomerFramePage after successful payment
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CustomerFramePage(), // Navigate to CustomerFramePage
                  ),
                );
              },
              child: const Text(
                'DONE',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        );
      },
    );

    _startTimer(pointsEarned);
  }

  Future<void> _completeOrder(int pointsEarned) async {
    // Store the order data under the custom order ID
    final orderRef =
        _database.child('orders/${user!.uid}/order_details').child(_orderId);

    final orderData = {
      'userId': user!.uid,
      'statusPayment': 'completed',
      'orderStatus': 'placed',
      'totalPayment': _totalPayment,
      'subtotal': _subtotal,
      'sst': _sst,
      'processingFee': _processingFee,
      'cartItems': _cartItems,
      'timestamp': ServerValue.timestamp,
      'shippingTypes': widget.shippingTypes,
      'addressDetail': {
        'address': widget.address,
        'name': widget.name,
        'phoneNumber': widget.phoneNumber
      },
    };

    // Store the order data in the database
    await orderRef.set(orderData);

    // Update user's points in the user database under rewards > points
    final userPointsRef =
        _database.child('user_database/${user!.uid}/rewards/points');
    final userVouchersRef = _database
        .child('user_database/${user!.uid}/rewards/vouchers/$_setVoucherID');
    final snapshot = await userPointsRef.get();
    final snapshotVoucher = await userVouchersRef.get();
    int currentPoints = 0;

    if (snapshot.exists) {
      currentPoints = snapshot.value as int;
    }

    // Update points
    await userPointsRef.set(currentPoints + pointsEarned);

    // update customer voucher
    if (snapshotVoucher.exists) {
      await userVouchersRef.remove();
    }

    // Clear cart after placing order
    await _database.child('user_database/${user!.uid}/cart').remove();

    // Update success message to display at the bottom
    setState(() {
      _successMessage =
          'Your Order Successfully Placed. You earned $pointsEarned points.';
    });

    // Show success message using a SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_successMessage)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
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
              'Item(s) Added,',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Item List Section
            Expanded(
              child: ListView.builder(
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Image.network(
                            item['imageUrl'] ??
                                'https://via.placeholder.com/50',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RM${item['productPrice'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeItem(index),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (item['quantity'] > 1) {
                                        _updateItemQuantity(
                                            index, item['quantity'] - 1);
                                      }
                                    },
                                  ),
                                  Text('${item['quantity']}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _updateItemQuantity(
                                          index, item['quantity'] + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Payment Option Section
            Container(
              height: 50.0,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(27),
              ),
              child: InkWell(
                onTap: () {
                  // Show a dialog to select payment option
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Payment Option'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Pay with QR Code'),
                            onTap: () {
                              setState(() {
                                _paymentOption = 'QR Code';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _paymentOption.isEmpty
                            ? 'Select Payment Option'
                            : _paymentOption, // Display QR option or prompt if empty
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 50.0,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(27),
              ),
              child: InkWell(
                onTap: () {
                  // Show a dialog to select payment option
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Your Voucher'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text("Continue without voucher"),
                            onTap: () {
                              setState(() {
                                _setisHaveVoucher = false;
                                _setVoucherID = '';
                                _setVoucherPoint = '';
                                _setVoucherName = '';
                                _calculateSubtotal();
                              });
                              Navigator.pop(context);
                            },
                          ),
                          for (final voucher in _userVouchers)
                            ListTile(
                              title: Text(voucher['voucherName']),
                              onTap: () {
                                setState(() {
                                  _setisHaveVoucher = true;
                                  _setVoucherID = voucher['voucherID'];
                                  _setVoucherPoint =
                                      voucher['voucherPoint'].toString();
                                  _setVoucherName = voucher['voucherName'];
                                  _calculateSubtotal();
                                });
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _setVoucherName.isEmpty
                            ? 'Select Your Voucher'
                            : _setVoucherName, // Display QR option or prompt if empty
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummaryRow(
                      title: 'Subtotal',
                      amount: 'RM${_subtotal.toStringAsFixed(2)}'),
                  SummaryRow(
                      title: 'SST 6%', amount: 'RM${_sst.toStringAsFixed(2)}'),
                  SummaryRow(
                      title: 'Processing Fee',
                      amount: 'RM${_processingFee.toStringAsFixed(2)}'),
                  if (_setisHaveVoucher)
                    SummaryRow(
                        title: 'Discount',
                        amount: '-RM${discount.toStringAsFixed(2)}'),
                  const Divider(),
                  SummaryRow(
                    title: 'Total Payment',
                    amount: 'RM${_totalPayment.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _paymentOption.isEmpty ? null : _processPayment,
                child: const Text(
                  'Pay',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add your helper methods for updating quantity or removing items if needed.
}

class SummaryRow extends StatelessWidget {
  final String title;
  final String amount;
  final bool isBold;

  const SummaryRow({
    super.key,
    required this.title,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
