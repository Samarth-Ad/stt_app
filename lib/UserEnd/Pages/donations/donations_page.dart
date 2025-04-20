import 'package:flutter/material.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({super.key});

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isAnonymous = false;
  String _selectedCause = 'Education';
  final List<String> _causes = [
    'Education',
    'Health',
    'Food',
    'Clothing',
    'Shelter',
    'Animal Welfare',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donations',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Impact Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Impact',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/donation-form');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Donate Now'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildImpactCard(
                          icon: Icons.food_bank,
                          count: '150+',
                          label: 'Meals',
                        ),
                        _buildImpactCard(
                          icon: Icons.school,
                          count: '45',
                          label: 'Students',
                        ),
                        _buildImpactCard(
                          icon: Icons.local_hospital,
                          count: '78',
                          label: 'Medical Aids',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Donation Form
              const Text(
                'Make a Donation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // Donation amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Donation for (Cause)
              DropdownButtonFormField<String>(
                value: _selectedCause,
                decoration: InputDecoration(
                  labelText: 'Donation For',
                  prefixIcon: const Icon(Icons.volunteer_activism),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items:
                    _causes.map((String cause) {
                      return DropdownMenuItem<String>(
                        value: cause,
                        child: Text(cause),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCause = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Anonymous donation checkbox
              CheckboxListTile(
                title: const Text('Make an anonymous donation'),
                value: _isAnonymous,
                activeColor: const Color(0xFF8B4513),
                onChanged: (bool? value) {
                  if (value != null) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Payment methods
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // UPI option
              _buildPaymentOption(
                icon: Icons.account_balance,
                title: 'UPI Payment',
                subtitle: 'Pay using any UPI app',
                onTap: () {
                  Navigator.pushNamed(context, '/donation-form');
                },
              ),

              // Card option
              _buildPaymentOption(
                icon: Icons.credit_card,
                title: 'Credit/Debit Card',
                subtitle: 'Pay using credit or debit card',
                onTap: () {
                  Navigator.pushNamed(context, '/donation-form');
                },
              ),

              // Net Banking option
              _buildPaymentOption(
                icon: Icons.laptop,
                title: 'Net Banking',
                subtitle: 'Pay using net banking',
                onTap: () {
                  Navigator.pushNamed(context, '/donation-form');
                },
              ),

              const SizedBox(height: 24),

              // Recent Donations
              const Text(
                'Recent Donations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // List of recent donations
              _buildRecentDonation(
                name: 'Raj Patel',
                amount: '₹5,000',
                cause: 'Education',
                date: 'March 15, 2025',
                isAnonymous: false,
              ),
              _buildRecentDonation(
                name: 'Anonymous',
                amount: '₹2,500',
                cause: 'Health',
                date: 'March 10, 2025',
                isAnonymous: true,
              ),
              _buildRecentDonation(
                name: 'Meera Shah',
                amount: '₹1,000',
                cause: 'Food',
                date: 'March 5, 2025',
                isAnonymous: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF8B4513), size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B4513)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentDonation({
    required String name,
    required String amount,
    required String cause,
    required String date,
    required bool isAnonymous,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                isAnonymous
                    ? Colors.grey.shade200
                    : const Color(0xFF8B4513).withOpacity(0.2),
            child: Icon(
              isAnonymous ? Icons.person_off : Icons.person,
              color: isAnonymous ? Colors.grey : const Color(0xFF8B4513),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'For $cause • $date',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }
}
