import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:bakenation_customer/order/cart.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double productPrice;
  final String imageUrl;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.imageUrl,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  User? user = FirebaseAuth.instance.currentUser;
  int _quantity = 1;
  String? imageUrl;
  String? size;
  int? stock;

  final DatabaseReference _productRef =
      FirebaseDatabase.instance.ref('products');

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  // Fetch the image URL, size, and stock from Firebase for the product
  Future<void> _fetchProductDetails() async {
    final productSnapshot = await _productRef.child(widget.productId).get();
    if (productSnapshot.exists) {
      final productData = productSnapshot.value as Map<dynamic, dynamic>;
      setState(() {
        imageUrl = productData['image_url'] ??
            'https://via.placeholder.com/150'; // Default image if not found
        size = productData['size'] ?? 'N/A'; // Default size if not found
        stock = productData['stock'] ?? 0; // Default stock if not found
      });
    } else {
      setState(() {
        imageUrl =
            'https://via.placeholder.com/150'; // Default image if not found
        size = 'N/A'; // Default size
        stock = 0; // Default stock
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      if (stock != null && _quantity < stock!) {
        _quantity++;
      }
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please log in to add items to the cart.')));
      return;
    }

    final cartItem = CartItem(
      userId: user!.uid,
      productName: widget.productName,
      productPrice: widget.productPrice,
      imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
      quantity: _quantity,
      productID: widget.productId,
    );

    // Ensure CartProvider uses the singleton instance and persists
    await CartProvider().addToCart(cartItem);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.productName} added to cart!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image (300x300 px box)
                Center(
                  child: imageUrl == null
                      ? const CircularProgressIndicator()
                      : Container(
                          width: 300, // Fixed width of 300px
                          height: 300, // Fixed height of 300px
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Product Name and Price
                Text(
                  widget.productName,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM${widget.productPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Product Size (fetched from Firebase)
                if (size != null)
                  Text(
                    'Size: $size',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 8),

                // Product Stock Availability (fetched from Firebase)
                if (stock != null)
                  Text(
                    'Stock Available: $stock',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 16),

                // Quantity Selector
                Row(
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _decrementQuantity,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _incrementQuantity,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Add to Cart Button at the bottom
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ADD TO CART',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
