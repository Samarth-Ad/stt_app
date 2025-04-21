import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For frontend-only functionality, use mock data
      // Comment this out when integrating with backend
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate network delay
      setState(() {
        _orderDetails = _getMockOrderDetails(widget.orderId);
        _isLoading = false;
      });
      return;

      // Backend integration code - uncomment when integrating with backend
      // final orderDetails = await _orderService.getOrderDetails(widget.orderId);
      // setState(() {
      //   _orderDetails = orderDetails;
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate mock order details based on order ID
  Map<String, dynamic> _getMockOrderDetails(String orderId) {
    // Mock orders data
    final mockOrders = {
      'STT123456': {
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
      'STT789012': {
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
    };

    // Check if we have details for this order ID
    if (mockOrders.containsKey(orderId)) {
      return mockOrders[orderId]!;
    }

    // If not found, create a default order with the given ID
    return {
      'orderId': orderId,
      'createdAt': {
        '_seconds':
            DateTime.now()
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000,
      },
      'status': 'pending',
      'totalAmount': 365.0,
      'items': [
        {
          'name': 'T-Shirt Style 1',
          'price': 15.0,
          'quantity': 1,
          'imageUrl': 'assets/Tshirt_1.jpg',
          'totalPrice': 15.0,
        },
        {
          'name': 'Ganpati Murti Classic',
          'price': 350.0,
          'quantity': 1,
          'imageUrl': 'assets/ganpatiMurti_1.jpg',
          'totalPrice': 350.0,
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
    };
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

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'online':
        return 'Online Payment';
      default:
        return method;
    }
  }

  String _formatStatus(String status) {
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final shortOrderId =
        orderId.length > 8
            ? orderId.substring(0, 8).toUpperCase()
            : orderId.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #$shortOrderId',
          style: const TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : _orderDetails == null
              ? const Center(child: Text('Order not found'))
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    final order = _orderDetails!;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = (order['status'] as String?) ?? 'pending';
    final paymentMethod = (order['paymentMethod'] as String?) ?? 'n/a';
    final createdAt = order['createdAt'] ?? order['orderDate'];
    final address = (order['shippingAddress'] as Map<String, dynamic>?) ?? {};

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order status card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: const TextStyle(
                            color: Colors.white,
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
                      const SizedBox(width: 8),
                      Text(
                        'Placed on ${_formatDate(createdAt)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.payment_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment: ${_formatPaymentMethod(paymentMethod)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Shipping address
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    address['name'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(address['phone'] ?? 'N/A'),
                  const SizedBox(height: 4),
                  Text(address['line1'] ?? 'N/A'),
                  if ((address['line2'] ?? '').isNotEmpty)
                    Text(address['line2']),
                  Text(
                    '${address['city'] ?? 'N/A'}, ${address['state'] ?? 'N/A'} - ${address['pincode'] ?? 'N/A'}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Order items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      Text(
                        '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ...items.map<Widget>((item) {
                    final itemName = item['name'] ?? 'Unknown Item';
                    final itemPrice =
                        (item['price'] as num?)?.toDouble() ?? 0.0;
                    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Item image (placeholder)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              image:
                                  item['imageUrl'] != null
                                      ? DecorationImage(
                                        image: AssetImage(item['imageUrl']),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                item['imageUrl'] == null
                                    ? const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),

                          // Item details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (item['size'] != null)
                                  Text(
                                    'Size: ${item['size']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (item['variant'] != null)
                                  Text(
                                    'Color: ${item['variant']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Price and quantity
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${quantity}x ${currencyFormat.format(itemPrice)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(itemPrice * quantity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Order total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Help and support
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you have any issues with your order, please contact our customer support.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Contact support logic
                        },
                        icon: const Icon(
                          Icons.support_agent,
                          color: Color(0xFF8B4513),
                        ),
                        label: const Text(
                          'Contact Support',
                          style: TextStyle(
                            color: Color(0xFF8B4513),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA000); // Amber
      case 'processing':
        return const Color(0xFF1976D2); // Blue
      case 'shipped':
        return const Color(0xFF7B1FA2); // Purple
      case 'delivered':
        return const Color(0xFF388E3C); // Green
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}
