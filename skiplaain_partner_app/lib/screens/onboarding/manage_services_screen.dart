import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/transitions.dart';
import 'add_custom_service_screen.dart';
import 'business_hours_screen.dart'; // Next screen in flow

class ManageServicesScreen extends StatefulWidget {
  final String salonName;
  final String address;
  final String category;
  final String phoneNumber;

  const ManageServicesScreen({
    super.key,
    this.salonName = 'Test Salon',
    this.address = 'Default Location',
    this.category = 'Gents Salon',
    this.phoneNumber = '+91 85535 35342',
  });

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  // Mock data for standard services with controllers for price and duration
  final List<Map<String, dynamic>> _standardServices = [
    {
      'name': 'Haircut',
      'isSelected': true,
      'priceController': TextEditingController(text: '200'),
      'durationController': TextEditingController(text: '30'),
      'durationUnit': 'Mins',
    },
    {
      'name': 'Beard Trim',
      'isSelected': true,
      'priceController': TextEditingController(text: '100'),
      'durationController': TextEditingController(text: '15'),
      'durationUnit': 'Mins',
    },
    {
      'name': 'Hair Color',
      'isSelected': false,
      'priceController': TextEditingController(),
      'durationController': TextEditingController(),
      'durationUnit': 'Mins',
    },
    {
      'name': 'Facial',
      'isSelected': false,
      'priceController': TextEditingController(),
      'durationController': TextEditingController(),
      'durationUnit': 'Mins',
    },
    {
      'name': 'Head Massage',
      'isSelected': false,
      'priceController': TextEditingController(),
      'durationController': TextEditingController(),
      'durationUnit': 'Mins',
    },
    {
      'name': 'Shaving',
      'isSelected': false,
      'priceController': TextEditingController(),
      'durationController': TextEditingController(),
      'durationUnit': 'Mins',
    },
  ];

  final List<Map<String, dynamic>> _customServices = [];

  @override
  void dispose() {
    for (var service in _standardServices) {
      (service['priceController'] as TextEditingController).dispose();
      (service['durationController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _toggleService(int index) {
    setState(() {
      _standardServices[index]['isSelected'] = !_standardServices[index]['isSelected'];
    });
  }

  void _onSaveAndContinue() {
    // Validate that all selected services have price and duration
    bool isValid = true;
    List<Map<String, dynamic>> selectedServices = [];

    for (var service in _standardServices) {
      if (service['isSelected']) {
        final price = (service['priceController'] as TextEditingController).text.trim();
        final duration = (service['durationController'] as TextEditingController).text.trim();
        if (price.isEmpty || duration.isEmpty) {
          isValid = false;
          break;
        }
        selectedServices.add({
          'name': service['name'],
          'price': int.tryParse(price) ?? 0,
          'duration': int.tryParse(duration) ?? 30,
          'durationUnit': service['durationUnit'] ?? 'Mins',
        });
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Price and Duration for all selected services.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var service in _customServices) {
      selectedServices.add({
        'name': service['name'] ?? 'Custom Service',
        'price': int.tryParse(service['price']?.toString() ?? '0') ?? 0,
        'duration': int.tryParse(service['duration']?.toString() ?? '30') ?? 30,
        'durationUnit': service['durationUnit'] ?? 'Mins',
      });
    }

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add at least one service.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PremiumTransition(
        page: BusinessHoursScreen(
          salonName: widget.salonName,
          address: widget.address,
          category: widget.category,
          phoneNumber: widget.phoneNumber,
          services: selectedServices,
        ),
      ),
    );
  }

  Future<void> _onAddCustomService() async {
    final result = await Navigator.push(
      context, 
      PremiumTransition(page: const AddCustomServiceScreen())
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _customServices.add(result);
      });
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: inputFormatters,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(int index) {
    final service = _standardServices[index];
    final bool isSelected = service['isSelected'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleService(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service['name'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00FF00) : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.transparent : const Color(0xFF2A2A2A),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Color(0xFF00FF00))
                        : null,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded inputs for Price and Duration if selected
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'PRICE (₹)',
                      controller: service['priceController'],
                      hint: 'e.g. 200',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            'TIME',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: service['durationController'],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '30',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: service['durationUnit'],
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF2A2A2A),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    items: ['Mins', 'Hours'].map((String unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(unit, style: const TextStyle(fontSize: 12)),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          service['durationUnit'] = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Manage Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select standard services and set your price & time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              // Services List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _standardServices.length,
                        itemBuilder: (context, index) {
                          return _buildServiceItem(index);
                        },
                      ),
                      
                      if (_customServices.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
                          child: Text(
                            'Custom Services',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._customServices.map((service) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00FF00), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['name'],
                                      style: const TextStyle(
                                        color: Color(0xFF00FF00),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service['duration'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${service['price']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ]
                    ],
                  ),
                ),
              ),
              
              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    // Add Custom Service Button (Dark)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onAddCustomService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '+ ADD CUSTOM SERVICE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Save & Continue Button (Neon Green)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onSaveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SAVE & CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
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
}
