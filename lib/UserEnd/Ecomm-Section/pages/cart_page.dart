import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'checkout_page.dart';

class CartItem {
  final Product product;
  int quantity;
  String? size;
  String? variant;

  CartItem({required this.product, this.quantity = 1, this.size, this.variant});

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'name': product.name,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'quantity': quantity,
      'size': size,
      'variant': variant,
      'totalPrice': totalPrice,
    };
  }
}

class CartProvider {
  static List<CartItem> _cartItems = [];

  static List<CartItem> get items => _cartItems;

  static double get totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  static void addItem(Product product, {String? size, String? variant}) {
    // Check if the product is already in the cart with the same size/variant
    final existingIndex = _cartItems.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.variant == variant,
    );

    if (existingIndex >= 0) {
      // If it exists, increment the quantity
      _cartItems[existingIndex].quantity += 1;
    } else {
      // Otherwise add a new item
      _cartItems.add(
        CartItem(product: product, quantity: 1, size: size, variant: variant),
      );
    }
  }

  static void removeItem(int index) {
    _cartItems.removeAt(index);
  }

  static void updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      _cartItems[index].quantity = quantity;
    } else {
      removeItem(index);
    }
  }

  static void clear() {
    _cartItems.clear();
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartItems = CartProvider.items;
    final totalAmount = CartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearCartDialog,
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartList(cartItems),
      bottomNavigationBar:
          cartItems.isEmpty ? null : _buildCheckoutBar(totalAmount),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Return to catalog
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCartItemCard(item, index);
      },
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    return Dismissible(
      key: Key('cart_item_${item.product.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          CartProvider.removeItem(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} removed from cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item.product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (item.size != null)
                      Text(
                        'Size: ${item.size}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    if (item.variant != null)
                      Text(
                        'Color: ${item.variant}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Price and quantity controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () {
                                setState(() {
                                  CartProvider.updateQuantity(
                                    index,
                                    item.quantity - 1,
                                  );
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () {
                                setState(() {
                                  CartProvider.updateQuantity(
                                    index,
                                    item.quantity + 1,
                                  );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCheckoutBar(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total amount
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),

          // Checkout button
          ElevatedButton(
            onPressed: _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    // Convert cart items to the format expected by CheckoutPage
    final List<Map<String, dynamic>> cartItemsForCheckout =
        CartProvider.items.map((item) => item.toMap()).toList();

    // Get the total amount
    final double totalAmount = CartProvider.totalAmount;

    // Show a checkout confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Items: ${cartItemsForCheckout.length}'),
                const SizedBox(height: 8),
                Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text('Would you like to place this order?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.pop(context);

                  // Show loading indicator
                  setState(() {
                    _isLoading = true;
                  });

                  // Simulate order placement with a delay
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });

                      // Show order success dialog
                      _showOrderSuccessDialog();

                      // Clear cart
                      CartProvider.clear();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Place Order'),
              ),
            ],
          ),
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Order Placed!'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order has been placed successfully.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Order ID: #STT-123456',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Thank you for shopping with us!',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Refresh cart page state
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue Shopping'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/orders');
                },
                child: const Text('View Orders'),
              ),
            ],
          ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to remove all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    CartProvider.clear();
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
