import 'package:flutter/material.dart';
import '../../utils/transitions.dart';
import 'manage_services_screen.dart';

class WelcomePartnerScreen extends StatefulWidget {
  final String? phoneNumber;

  const WelcomePartnerScreen({super.key, this.phoneNumber});

  @override
  State<WelcomePartnerScreen> createState() => _WelcomePartnerScreenState();
}

class _WelcomePartnerScreenState extends State<WelcomePartnerScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedCategory = 'Gents Salon';

  final List<String> _categories = [
    'Gents Salon',
    'Ladies Salon',
    'Unisex Salon',
    'Spa & Massage'
  ];

  void _onGetStarted() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter business name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navigate to next screen (Manage Services)
    Navigator.push(
      context,
      PremiumTransition(
        page: ManageServicesScreen(
          salonName: _nameController.text.trim(),
          address: 'Address not set', // Will be added from profile later
          category: _selectedCategory,
          phoneNumber: widget.phoneNumber ?? '+91 85535 35342',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildTextFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel(label),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: items.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Headers
              const Center(
                child: Text(
                  'Welcome Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              const Center(
                child: Text(
                  'Register your business to start accepting systematic\nbookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        label: 'BUSINESS NAME',
                        controller: _nameController,
                        hint: 'e.g. Yash Styles',
                      ),
                      
                      _buildDropdownField(
                        label: 'SALON CATEGORY',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF00FF00).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF00FF00), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can add your address later from Profile Settings',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
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
}
