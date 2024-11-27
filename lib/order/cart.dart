import 'package:bakenation_customer/order/delivery_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CartItem {
  final String productName;
  final double productPrice;
  final String imageUrl;
  int quantity;
  final String? userId;
  final String productID;

  CartItem({
    required this.productName,
    required this.productPrice,
    required this.imageUrl,
    required this.userId,
    required this.productID,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'productPrice': productPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'productID': productID,
    };
  }

  static CartItem fromMap(
      Map<String, dynamic> map, String userId, String productID) {
    return CartItem(
      productName: map['productName'],
      productPrice: map['productPrice'].toDouble(),
      imageUrl: map['imageUrl'],
      quantity: map['quantity'],
      userId: userId,
      productID: productID.toString(),
    );
  }
}

class CartProvider {
  final List<CartItem> _cartItems = [];
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  CartProvider();

  List<CartItem> get cartItems => _cartItems;

  Future<void> addToCart(CartItem item) async {
    if (userId == null) return;

    for (var cartItem in _cartItems) {
      if (cartItem.productID == item.productID &&
          cartItem.userId == item.userId) {
        cartItem.quantity += item.quantity;
        await updateItemInDatabase(cartItem);
        return;
      }
    }
    _cartItems.add(item);
    await saveItemToDatabase(item);
  }

  Future<void> saveItemToDatabase(CartItem item) async {
    if (userId == null) return;

    final itemRef =
        _database.child('user_database/$userId/cart/${item.productID}');
    await itemRef.set(item.toMap());
  }

  Future<void> updateItemInDatabase(CartItem item) async {
    if (userId == null) return;

    final itemRef =
        _database.child('user_database/$userId/cart/${item.productID}');
    await itemRef.update({'quantity': item.quantity});
  }

  Future<void> removeItemFromDatabase(CartItem item) async {
    if (userId == null) return;

    final itemRef =
        _database.child('user_database/$userId/cart/${item.productID}');
    await itemRef.remove();
  }

  void removeFromCart(CartItem item) async {
    _cartItems.remove(item);
    await removeItemFromDatabase(item); // Remove item from database
  }

  Future<void> _loadCartItems() async {
    if (userId == null) return;

    final cartRef = _database.child('user_database/$userId/cart');
    final snapshot = await cartRef.get();
    if (snapshot.exists) {
      // Ensure the data is a Map
      final dynamic data = snapshot.value;

      if (data is Map) {
        // Safely convert to Map<String, dynamic>
        Map<String, dynamic> cartData = {};

        // Iterate over the map and convert each entry
        data.forEach((key, value) {
          if (key is String && value is Map) {
            // Manually convert the value if it's a Map
            cartData[key] = Map<String, dynamic>.from(value);
          }
        });

        // Clear the current cart items and reload with the new data
        _cartItems.clear();
        cartData.forEach((key, value) {
          final item = CartItem.fromMap(value, userId!, key);
          _cartItems.add(item); // Add item to cart
        });

        print('Items in cart: $_cartItems');
      } else {
        print('Data is not a valid Map: $data');
      }
    }
  }

  int get itemCount => _cartItems.length;

  double get subtotal {
    return _cartItems.fold(
        0, (total, item) => total + item.productPrice * item.quantity);
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartProvider _cartProvider;

  @override
  void initState() {
    super.initState();
    _cartProvider = CartProvider();
    _loadCartItems();
  }

  // Trigger loading of cart items when the screen is initialized
  Future<void> _loadCartItems() async {
    await _cartProvider._loadCartItems(); // Load cart items from Firebase

    setState(() {}); // Rebuild the UI after loading cart items
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartProvider.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You've added ${cartItems.length} item${cartItems.length == 1 ? '' : 's'}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: cartItems.map((item) {
                    return Card(
                      elevation: 4.0, // Add shadow for the card effect
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Image.network(
                              item.imageUrl,
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
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'RM${item.productPrice.toStringAsFixed(2)}',
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
                                  onPressed: () {
                                    setState(() {
                                      _cartProvider.removeFromCart(item);
                                    });
                                  },
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          if (item.quantity > 1) {
                                            item.quantity--;
                                            _cartProvider
                                                .updateItemInDatabase(item);
                                          }
                                        });
                                      },
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          item.quantity++;
                                          _cartProvider
                                              .updateItemInDatabase(item);
                                        });
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
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RM${_cartProvider.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cartItems.isEmpty
                      ? Colors.grey // Disabled color if the cart is empty
                      : const Color.fromRGBO(163, 25, 25, 1), // Normal color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: cartItems.isEmpty
                    ? null // Disable the button if the cart is empty
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeliveryOptions(),
                          ),
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
