import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationsFormPage extends StatefulWidget {
  const DonationsFormPage({super.key});

  @override
  State<DonationsFormPage> createState() => _DonationsFormPageState();
}

class _DonationsFormPageState extends State<DonationsFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Membership status
  String _membershipStatus = 'Member';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // We need to delay this to allow navigation arguments to be available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processRouteArguments();
    });
  }

  void _processRouteArguments() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        if (args.containsKey('transactionId')) {
          _transactionIdController.text = args['transactionId'] as String;
        }
        if (args.containsKey('donorName')) {
          _nameController.text = args['donorName'] as String;
        }
        if (args.containsKey('amount')) {
          _amountController.text = args['amount'] as String;
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userData.exists && mounted) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _membershipStatus = data['membership'] ?? 'Non Member';
            _isLoading = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDonationToDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // First, ensure the user document exists in Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      // If user document doesn't exist in Firestore, create it first
      if (!userDoc.exists) {
        print("User document doesn't exist in Firestore, creating it now");
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'gender': 'Select Gender', // Default value
          'membership': _membershipStatus,
          'registrationDate': FieldValue.serverTimestamp(),
        });
        print("Created user document in Firestore");
      }

      // Parse amount from text field
      double amount = 0;
      try {
        amount = double.parse(_amountController.text);
      } catch (e) {
        print('Error parsing amount: $e');
        amount = 0; // Default to 0 if parsing fails
      }

      // Now save the donation with transaction ID
      await FirebaseFirestore.instance.collection('donations').add({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'membership': _membershipStatus,
        'userId': user.uid,
        'amount': amount,
        'transactionId': _transactionIdController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message using SnackBar instead of fluttertoast
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation request submitted successfully!'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving donation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToDonation() {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Donation'),
            content: Text(
              'Do you want to proceed with your donation of ₹${_amountController.text}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _saveDonationToDatabase();
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _transactionIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : SafeArea(
                child: Column(
                  children: [
                    // Logo and title
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/stt_logo.png',
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Donations',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Transaction ID field
                              TextFormField(
                                controller: _transactionIdController,
                                decoration: InputDecoration(
                                  labelText: 'Transaction ID',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the transaction ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  // Basic email validation
                                  if (!value.contains('@') ||
                                      !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone field
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Amount field
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the donation amount';
                                  }
                                  try {
                                    double.parse(value);
                                  } catch (e) {
                                    return 'Please enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Membership status
                              TextFormField(
                                initialValue: _membershipStatus,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'STT MEMBER / NON MEMBER',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 36),

                              // Proceed for donation button
                              ElevatedButton(
                                onPressed: _proceedToDonation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B4513),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'SUBMIT DONATION',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
