import 'package:flutter/material.dart';
import 'package:bakenation_customer/product/product_detail.dart';
import 'package:firebase_database/firebase_database.dart';

class Product {
  final String id; // Add productId field
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id, // productId is required
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  // Factory method to create a Product from a Firebase snapshot map
  factory Product.fromMap(Map<dynamic, dynamic> map, String productId) {
    return Product(
      id: productId, // Pass the productId
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['image_url'] ?? 'No Image Found',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({required this.callbackPage, super.key});

  final Function(String selectedDetaildPage, Widget page) callbackPage;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref('products');
  final DatabaseReference adsRef =
      FirebaseDatabase.instance.ref('advertisements');
  List<Product> products = [];
  List<String> adImages = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchAds();
  }

  // Fetch products from Firebase and limit to top 10
  Future<void> fetchProducts() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          products = data.entries.map((entry) {
            // Pass both product data and product ID
            return Product.fromMap(
                entry.value as Map<dynamic, dynamic>, entry.key as String);
          }).toList();
        });
      } else {
        setState(() {
          products = []; // No products found
        });
      }
    });
  }

  // Fetch advertisements from Firebase
  Future<void> fetchAds() async {
    adsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          adImages = data.values
              .map((value) =>
                  value['image_url'] as String? ??
                  'https://via.placeholder.com/300x150')
              .toList();
        });
      } else {
        setState(() {
          adImages = []; // No ads found
        });
      }
    });
  }

  // Refresh function to call fetchProducts and fetchAds to update the UI
  Future<void> _refreshProducts() async {
    await fetchProducts();
    await fetchAds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProducts, // Trigger the refresh
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Slide Ads Section
              AspectRatio(
                aspectRatio: 16 / 9, // Set the aspect ratio to 16:9
                child: adImages.isEmpty
                    ? const Center(
                        child: Text(
                          'No advertisements available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : PageView.builder(
                        itemCount: adImages.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            adImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 30),

              // Product Catalog
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Our Premium Products',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    products.isEmpty
                        ? const Center(
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.70,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];

                              return GestureDetector(
                                onTap: () {
                                  widget.callbackPage(
                                    'tukarPage',
                                    ProductDetailPage(
                                      productId:
                                          product.id, // Pass the productId
                                      productName: product.name,
                                      productPrice: product.price,
                                      imageUrl: product.imageUrl,
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          height: 150,
                                          width: double.infinity,
                                          child: Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(7.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'RM${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
