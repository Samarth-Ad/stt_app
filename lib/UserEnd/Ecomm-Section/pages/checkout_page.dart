import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_appbar.dart';
import 'order_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _paymentMethod = 'cod';
  bool _isLoading = false;
  bool _loadingAddress = true;
  bool _hasExistingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    setState(() {
      _loadingAddress = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists && userDoc.data()!.containsKey('address')) {
          final address = userDoc.data()!['address'] as Map<String, dynamic>;
          _nameController.text = address['name'] ?? '';
          _phoneController.text = address['phone'] ?? '';
          _line1Controller.text = address['line1'] ?? '';
          _line2Controller.text = address['line2'] ?? '';
          _cityController.text = address['city'] ?? '';
          _stateController.text = address['state'] ?? '';
          _pincodeController.text = address['pincode'] ?? '';

          setState(() {
            _hasExistingAddress = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading address: $e')));
    } finally {
      setState(() {
        _loadingAddress = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'address': {
                'name': _nameController.text,
                'phone': _phoneController.text,
                'line1': _line1Controller.text,
                'line2': _line2Controller.text,
                'city': _cityController.text,
                'state': _stateController.text,
                'pincode': _pincodeController.text,
              },
            });
      } catch (e) {
        // If document doesn't exist, create it
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'address': {
            'name': _nameController.text,
            'phone': _phoneController.text,
            'line1': _line1Controller.text,
            'line2': _line2Controller.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'pincode': _pincodeController.text,
          },
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save address to user profile
      await _saveAddress();

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create order in Firestore
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      await orderRef.set({
        'userId': user.uid,
        'orderDate': Timestamp.now(),
        'items': widget.cartItems,
        'totalAmount': widget.totalAmount,
        'status': 'pending',
        'paymentMethod': _paymentMethod,
        'paymentStatus': _paymentMethod == 'cod' ? 'pending' : 'paid',
        'shippingAddress': {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'line1': _line1Controller.text,
          'line2': _line2Controller.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
        },
      });

      // Clear cart for user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'cart': []},
      );

      // Navigate to confirmation page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: CustomAppBar(title: 'Checkout', showBackButton: true),
      body:
          _loadingAddress
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping Address',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAddressForm(),
                      const SizedBox(height: 24),
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentMethodSelection(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(currencyFormat),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Place Order',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length != 10) {
              return 'Phone number should be 10 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _line1Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 1',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _line2Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 2 (Optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeController,
          decoration: const InputDecoration(
            labelText: 'PIN Code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your PIN code';
            }
            if (value.length != 6) {
              return 'PIN code should be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Row(
                children: [
                  const Icon(Icons.payments, color: Color(0xFF8B4513)),
                  const SizedBox(width: 12),
                  const Text('Cash on Delivery'),
                  const Spacer(),
                  Text(
                    'Pay Later',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              value: 'cod',
              groupValue: _paymentMethod,
              activeColor: const Color(0xFF8B4513),
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            const Divider(),
            RadioListTile<String>(
              title: Row(
                children: [
                  const Icon(Icons.credit_card, color: Color(0xFF8B4513)),
                  const SizedBox(width: 12),
                  const Text('Online Payment'),
                  const Spacer(),
                  Text(
                    'Pay Now',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              value: 'online',
              groupValue: _paymentMethod,
              activeColor: const Color(0xFF8B4513),
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${item['quantity']} × ${currencyFormat.format(item['price'])}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(widget.totalAmount),
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
    );
  }
}
