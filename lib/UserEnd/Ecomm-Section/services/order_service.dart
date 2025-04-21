import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Place a new order
  Future<String> placeOrder({
    required List<Map<String, dynamic>> cartItems,
    required Map<String, dynamic> address,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate a unique order ID
      final String orderId = const Uuid().v4();

      // Create order document
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': user.uid,
        'items': cartItems,
        'shippingAddress': address,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart after successful order
      await _clearUserCart(user.uid);

      return orderId;
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  // Clear user's cart after order is placed
  Future<void> _clearUserCart(String userId) async {
    try {
      final cartRef = _firestore.collection('carts').doc(userId);
      await cartRef.update({'items': [], 'totalAmount': 0});
    } catch (e) {
      // Log error but don't throw exception to avoid breaking order flow
      print('Error clearing cart: $e');
    }
  }

  // Get user's order history
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot orderDocs =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return orderDocs.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get order details by ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final DocumentSnapshot orderDoc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      return orderDoc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
}
