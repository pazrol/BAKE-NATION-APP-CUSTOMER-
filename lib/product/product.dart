import 'package:bakenation_customer/product/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<dynamic, dynamic> map, String productId) {
    return Product(
      id: productId,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      imageUrl:
          map['image_url'] as String? ?? 'https://via.placeholder.com/100x100',
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({required this.callbackPage, super.key});

  final Function(String selectedDetaildPage, Widget page) callbackPage;

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String selectedCategory = 'All Products';
  final List<String> categories = [
    'All Products',
    'Flavorings',
    'Tougheners',
    'Moisteners',
    'Driers'
  ];
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref('products');
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_applyCategoryAndSearchFilter);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          allProducts = data.entries.map((entry) {
            // Pass both product data (entry.value) and the product ID (entry.key)
            return Product.fromMap(
                entry.value as Map<dynamic, dynamic>, entry.key as String);
          }).toList();
          _applyCategoryAndSearchFilter(); // Apply initial filters
        });
      }
    });
  }

  void _applyCategoryAndSearchFilter() {
    final query = searchController.text.toLowerCase();

    setState(() {
      displayedProducts = allProducts.where((product) {
        final matchesCategory = selectedCategory == 'All Products' ||
            product.category == selectedCategory;
        final matchesSearch = product.name.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  // Refresh function to call fetchProducts and update the UI
  Future<void> _refreshProducts() async {
    await fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProducts, // Trigger the refresh
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search products',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show dropdown menu as a modal bottom sheet
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                color: Colors.white,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: categories.map((String category) {
                                    return ListTile(
                                      title: Center(
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: selectedCategory == category
                                                ? Colors.black
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      tileColor: selectedCategory == category
                                          ? Colors.red
                                          : Colors.white,
                                      onTap: () {
                                        setState(() {
                                          selectedCategory = category;
                                        });
                                        Navigator.pop(context);
                                        _applyCategoryAndSearchFilter(); // Apply filter based on selected category
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(163, 25, 25, 1),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 0, 0, 0)
                                    .withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedCategory == 'All Products'
                                    ? 'Category'
                                    : selectedCategory,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Space between dropdown and catalog

              // Product Catalog or No Products Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: displayedProducts.isEmpty
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
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];

                          return GestureDetector(
                            onTap: () {
                              widget.callbackPage(
                                'tukarPage',
                                ProductDetailPage(
                                  productId: product.id,
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
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
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
                                    padding: const EdgeInsets.all(8.0),
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
                                        const SizedBox(height: 10),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
