import 'package:flutter/material.dart';
import '../models/product.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'T-Shirt SPANISH',
      imageUrl: 'assets/products/tshirt_red.png',
      price: 15,
      rating: 4.5,
      reviews: 128,
      isOnSale: true,
      discountPercentage: 20,
    ),
    Product(
      id: '2',
      name: 'Blouse',
      imageUrl: 'assets/products/blouse_white.png',
      price: 25,
      rating: 5.0,
      reviews: 210,
    ),
    Product(
      id: '3',
      name: 'Shirt',
      imageUrl: 'assets/products/shirt_green.png',
      price: 17,
    ),
    Product(
      id: '4',
      name: 'Light blouse',
      imageUrl: 'assets/products/blouse_yellow.png',
      price: 14,
      rating: 4.8,
      reviews: 185,
      isOnSale: true,
      discountPercentage: 20,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B4513),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8B4513),
          tabs: const [Tab(text: 'Clothing Merch'), Tab(text: 'Ganpati Idols')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClothingGrid(),
          const Center(child: Text('Coming Soon')),
        ],
      ),
    );
  }

  Widget _buildClothingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  product.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    );
                  },
                ),
              ),
              if (product.isOnSale)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${product.discountPercentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: product.isOnSale ? 48 : 8,
                child: IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {
                    // Handle favorite
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.rating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        ' ${product.rating} (${product.reviews})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price}',
                  style: const TextStyle(
                    color: Color(0xFF8B4513),
                    fontWeight: FontWeight.bold,
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
