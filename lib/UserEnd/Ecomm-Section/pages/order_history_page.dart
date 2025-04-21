import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import 'order_details_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For frontend-only functionality, we'll use mock data
      // Comment this out when integrating with backend
      final mockOrders = _createMockOrders();
      setState(() {
        _orders = mockOrders;
        _isLoading = false;
      });
      return;

      // Backend integration code - uncomment when integrating with backend
      // final orders = await _orderService.getUserOrders();
      // setState(() {
      //   _orders = orders;
      // });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading orders: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate mock orders for frontend testing
  List<Map<String, dynamic>> _createMockOrders() {
    return [
      {
        'orderId': 'STT123456',
        'createdAt': {
          '_seconds':
              DateTime.now()
                  .subtract(const Duration(days: 2))
                  .millisecondsSinceEpoch ~/
              1000,
        },
        'status': 'processing',
        'totalAmount': 368.0,
        'items': [
          {
            'name': 'T-Shirt Style 1',
            'price': 15.0,
            'quantity': 2,
            'imageUrl': 'assets/Tshirt_1.jpg',
            'totalPrice': 30.0,
          },
          {
            'name': 'Ganpati Murti Classic',
            'price': 338.0,
            'quantity': 1,
            'imageUrl': 'assets/ganpatiMurti_1.jpg',
            'totalPrice': 338.0,
          },
        ],
        'paymentMethod': 'cod',
        'shippingAddress': {
          'name': 'John Doe',
          'phone': '9876543210',
          'line1': '123 Main Street',
          'line2': 'Apartment 4B',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'pincode': '400001',
        },
      },
      {
        'orderId': 'STT789012',
        'createdAt': {
          '_seconds':
              DateTime.now()
                  .subtract(const Duration(days: 15))
                  .millisecondsSinceEpoch ~/
              1000,
        },
        'status': 'delivered',
        'totalAmount': 518.0,
        'items': [
          {
            'name': 'T-Shirt Style 2',
            'price': 18.0,
            'quantity': 1,
            'imageUrl': 'assets/TShirt_2.jpg',
            'totalPrice': 18.0,
          },
          {
            'name': 'Ganpati Murti Premium',
            'price': 500.0,
            'quantity': 1,
            'imageUrl': 'assets/ganpatiMurti_2.jpg',
            'totalPrice': 500.0,
          },
        ],
        'paymentMethod': 'online',
        'shippingAddress': {
          'name': 'John Doe',
          'phone': '9876543210',
          'line1': '123 Main Street',
          'line2': 'Apartment 4B',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'pincode': '400001',
        },
      },
    ];
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is Map && date['_seconds'] != null) {
      // Firestore timestamp format
      dateTime = DateTime.fromMillisecondsSinceEpoch(
        (date['_seconds'] * 1000).round(),
      );
    } else {
      return 'Invalid date';
    }

    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return '#FFA000'; // Amber
      case 'processing':
        return '#1976D2'; // Blue
      case 'shipped':
        return '#7B1FA2'; // Purple
      case 'delivered':
        return '#388E3C'; // Green
      case 'cancelled':
        return '#D32F2F'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: const Color(0xFF8B4513),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B4513)),
                )
                : _orders.isEmpty
                ? _buildEmptyOrdersView()
                : _buildOrdersList(),
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
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

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderId = order['orderId'] ?? '';
        final shortOrderId =
            orderId.length > 8
                ? orderId.substring(0, 8).toUpperCase()
                : orderId.toUpperCase();
        final createdAt = order['createdAt'] ?? order['orderDate'];
        final status = (order['status'] as String?) ?? 'pending';
        final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final items = (order['items'] as List<dynamic>?) ?? [];
        final itemCount = items.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(orderId: orderId),
                ),
              ).then((_) => _loadOrders());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #$shortOrderId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                                  _getStatusColor(status).substring(1),
                                  radix: 16,
                                ) |
                                0xFF000000,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: Color(
                              int.parse(
                                    _getStatusColor(status).substring(1),
                                    radix: 16,
                                  ) |
                                  0xFF000000,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Placed on ${_formatDate(createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Text('Total: ', style: TextStyle(fontSize: 14)),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      OrderDetailsPage(orderId: orderId),
                            ),
                          ).then((_) => _loadOrders());
                        },
                        child: const Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF8B4513),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF8B4513),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
