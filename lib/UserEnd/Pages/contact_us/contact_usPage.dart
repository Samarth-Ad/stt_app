import 'package:flutter/material.dart';
import '../../models/member_model.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  // Create a list of team members
  final List<Member> _members = [
    Member(
      name: 'Shravani Bhole',
      role: 'CEO',
      quote:
          '"Contemporary design and well-made products are things that we think everybody should be able to have. It\'s the reason we do what we do"',
      email: 'anonymous1708@gmail.com',
      phone: '9169203847',
    ),
    Member(
      name: 'Udayan Kundu',
      role: 'CMO',
      quote: '"Innovation distinguishes between a leader and a follower"',
      email: 'udayan.k@example.com',
      phone: '9876543210',
    ),
    Member(
      name: 'Samarth Adsare',
      role: 'Founder',
      quote:
          '"Design is not just what it looks like and feels like. Design is how it works"',
      email: 'samarth.a@example.com',
      phone: '8765432109',
    ),
    Member(
      name: 'Khushi Warang',
      role: 'Treasurer',
      quote:
          '"A budget is telling your money where to go instead of wondering where it went"',
      email: 'khushi.w@example.com',
      phone: '7654321098',
    ),
  ];

  Member? _selectedMember;

  @override
  void initState() {
    super.initState();
    // Set the first member as selected by default
    if (_members.isNotEmpty) {
      _selectedMember = _members.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: SafeArea(
        child: isMobile ? _buildMobileLayout() : _buildTabletLayout(),
      ),
    );
  }

  // Mobile layout with just the list and modal for details
  Widget _buildMobileLayout() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header with back button and logo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const SizedBox(height: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Members title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Members',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          // Members list
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getAvatarColor(index),
                    child: Text(
                      member.name[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(member.name),
                  subtitle: Text(member.role),
                  onTap: () {
                    _showMemberDetails(member);
                  },
                );
              },
            ),
          ),

          // Send Message button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Handle send message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA9703D),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Message',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // Tablet/Desktop layout with side-by-side panels
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Members list - left panel
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Header with back button and logo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 40,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const SizedBox(height: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Members title
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Members',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                // Members list
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(index),
                          child: Text(
                            member.name[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.role),
                        onTap: () {
                          setState(() {
                            _selectedMember = member;
                          });
                        },
                      );
                    },
                  ),
                ),

                // Send Message button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle send message
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA9703D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Send Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Bottom navigation
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),

        // Individual details - right panel
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                _selectedMember != null
                    ? Column(
                      children: [
                        // Header with back button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                onPressed: () {
                                  // Could implement mobile view navigation here
                                },
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Individual Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Name and role
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA9703D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _selectedMember!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedMember!.role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quote if available
                        if (_selectedMember!.quote != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA9703D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedMember!.quote!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Contact details section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'CONTACT DETAILS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        // Email if available
                        if (_selectedMember!.email != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA9703D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _selectedMember!.email!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        // Phone if available
                        if (_selectedMember!.phone != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA9703D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _selectedMember!.phone!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Bottom navigation
                        _buildBottomNavigation(),
                      ],
                    )
                    : const Center(
                      child: Text('Select a member to view details'),
                    ),
          ),
        ),
      ],
    );
  }

  // Show member details in a modal bottom sheet (for mobile view)
  void _showMemberDetails(Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Individual Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Name and role
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFA9703D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.role,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Quote if available
              if (member.quote != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9703D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.quote!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

              const SizedBox(height: 24),

              // Contact details section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'CONTACT DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),

              // Email if available
              if (member.email != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9703D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      member.email!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              // Phone if available
              if (member.phone != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9703D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      member.phone!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              const Spacer(),

              // Bottom navigation
              _buildBottomNavigation(),
            ],
          ),
        );
      },
    );
  }

  // Helper method to create the bottom navigation
  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.calendar_today, 'Calendar'),
          _buildNavItem(Icons.people, 'Events'),
          _buildNavItem(Icons.card_travel, 'Product', isSelected: true),
          _buildNavItem(Icons.volunteer_activism, 'Donations'),
          _buildNavItem(Icons.person, 'Profile'),
        ],
      ),
    );
  }

  // Helper method to create navigation items
  Widget _buildNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color.fromARGB(255, 166, 208, 244)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }

  // Helper method to generate different colors for avatars
  Color _getAvatarColor(int index) {
    List<Color> colors = [
      Colors.grey, // Shravani
      Colors.lightGreen, // Udayan
      Colors.lime, // Samarth
      Colors.white, // Khushi
    ];

    return index < colors.length ? colors[index] : Colors.blueGrey;
  }
}
