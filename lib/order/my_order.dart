import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyOrderPage(),
    );
  }
}

class MyOrderPage extends StatefulWidget {
  const MyOrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<MyOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // order completed
  void orderCompleted(
    String orderId,
    String userId,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'completed'});
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    String statusLabel =
        order['orderStatus'] ?? 'Unknown Status'; // Default to "Unknown Status"

    // Depending on the status, display the appropriate label
    switch (statusLabel) {
      case 'placed':
        statusLabel = 'Your order is placed';
        break;
      case 'Processing':
        statusLabel = 'Preparing your order';
        break;
      case 'out_for_delivery':
        statusLabel = 'Out for delivery';
        break;
      case 'ready_to_pickup':
        statusLabel = 'Ready to pickup';
        break;
      case 'shipped_out':
        statusLabel = 'Order has been shipped out';
        break;
      case 'completed':
        statusLabel = 'Order Completed';
        break;
      case 'cancelled':
        statusLabel = 'Order Cancelled';
        break;
      // You can add more cases as needed
      default:
        statusLabel = 'Unknown Status';
    }

    List<dynamic> cartItems = order['cartItems'] ?? [];
    print("gijdjddf");
    print(order['trackingNumber']);
    int itemCount = cartItems.length;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(163, 25, 25, 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel, // Display the status from the database
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (statusLabel == 'Order has been shipped out' &&
                order['trackingNumber'] != 'N/A')
              Text("Tracking Number : ${order['trackingNumber']}"),
            ...cartItems.asMap().entries.map<Widget>((entry) {
              int index = entry.key;
              var item = entry.value;

              if (!_showMore && index >= 3) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['productName'] ?? 'Unknown Item'} x${item['quantity'] ?? 1}',
                      style: const TextStyle(),
                    ),
                    Text(
                      'RM${item['productPrice'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8.0),

            // Divider above SST row
            Divider(color: Colors.grey[300]),

            // Always show SST and Processing Fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SST (6%)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('RM${order['sst'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Processing Fee',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('RM${order['processingFee'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL AMOUNT',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'RM${order['totalPayment'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (statusLabel == 'Order has been shipped out')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add your ready to ship logic here

                      final orderID = order['orderID'];
                      final userID = _currentUser?.uid;

                      orderCompleted(orderID, userID.toString());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Order Received',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            if (statusLabel == 'Out for delivery')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add your ready to ship logic here

                      final orderID = order['orderID'];
                      final userID = _currentUser?.uid;

                      orderCompleted(orderID, userID.toString());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Order Received',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

            // Show More/Show Less Button
            if (itemCount > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showMore = !_showMore;
                    });
                  },
                  child: Text(
                    _showMore ? 'Show Less ' : 'Show More ',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrders(
      String userId, bool isCompletedOrCancelled) async {
    final DatabaseReference ordersRef = _database
        .child('orders')
        .child(userId)
        .child('order_details'); // Adjusted path

    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    List<Map<String, dynamic>> orders = [];

    if (data != null) {
      data.forEach((orderId, orderData) {
        // Filter orders based on completed or cancelled status
        if ((isCompletedOrCancelled &&
                (orderData['orderStatus'] == 'completed' ||
                    orderData['orderStatus'] == 'cancelled')) ||
            (!isCompletedOrCancelled &&
                orderData['orderStatus'] != 'completed' &&
                orderData['orderStatus'] != 'cancelled')) {
          List<dynamic> cartItems = orderData['cartItems'] ?? [];
          orders.add({
            'orderID': orderId,
            'orderStatus': orderData['orderStatus'] ?? 'unknown',
            'cartItems': cartItems,
            'totalPayment': orderData['totalPayment'] ?? 'N/A',
            'sst': orderData['sst'] ?? 'N/A',
            'processingFee': orderData['processingFee'] ?? 'N/A',
            'trackingNumber': orderData['tracking_number'] ?? 'N/A',
          });
        }
      });
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: const Color.fromRGBO(163, 25, 25, 1),
            tabs: const [
              Tab(text: 'Active Orders'),
              Tab(text: 'Order History'),
            ],
          ),

          // TabBarView for tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Orders Tab
                RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      // Trigger a refresh by reloading the data
                    });
                  },
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchOrders(userId, false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'No Active Orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return buildOrderCard(snapshot.data![index]);
                        },
                      );
                    },
                  ),
                ),

                // Order History Tab (Completed or Cancelled orders)
                RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      // Trigger a refresh by reloading the data
                    });
                  },
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchOrders(
                        userId, true), // Show completed or cancelled orders
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'No Orders History',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return buildOrderCard(snapshot.data![index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
