import 'package:flutter/material.dart';

class SlotPickerScreen extends StatefulWidget {
  final Map<String, dynamic> salon;
  final List<Map<String, dynamic>> selectedServices;
  final double totalAmount;
  final int totalDurationMinutes;
  final String? customerPhone;

  const SlotPickerScreen({
    super.key,
    required this.salon,
    required this.selectedServices,
    required this.totalAmount,
    required this.totalDurationMinutes,
    this.customerPhone,
  });

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Select Slot', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Slot booking feature coming soon',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
