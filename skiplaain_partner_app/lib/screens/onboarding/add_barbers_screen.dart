import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import '../dashboard/main_dashboard_screen.dart';

class AddBarbersScreen extends StatefulWidget {
  final String phoneNumber;
  final String salonName;
  final String address;
  final String category;
  final String openingTime;
  final String closingTime;
  final String weeklyOff;
  final List<Map<String, dynamic>> services;

  const AddBarbersScreen({
    super.key,
    required this.phoneNumber,
    required this.salonName,
    required this.address,
    required this.category,
    required this.openingTime,
    required this.closingTime,
    required this.weeklyOff,
    required this.services,
  });

  @override
  State<AddBarbersScreen> createState() => _AddBarbersScreenState();
}

class _AddBarbersScreenState extends State<AddBarbersScreen> {
  final PartnerService _partnerService = PartnerService();
  bool _isLoading = false;

  static const List<String> _allWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Empty list by default - Partner adds their own real barbers manually
  final List<Map<String, dynamic>> _barbers = [];

  void _showAddBarberDialog() {
    final nameController = TextEditingController();
    List<String> selectedDays = List<String>.from(_allWeekdays);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF262626)),
          ),
          title: const Text('Add Staff & Schedule', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Barber Name', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul, Suresh, Vikram...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF00))),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Working Days', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      '${selectedDays.length}/7 Days',
                      style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap days this staff member takes appointments:',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 10),

                // 7 Day Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allWeekdays.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          if (isSelected) {
                            if (selectedDays.length > 1) {
                              selectedDays.remove(day);
                            }
                          } else {
                            selectedDays.add(day);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF333333),
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final offDays = _allWeekdays.where((d) => !selectedDays.contains(d)).toList();

                setState(() {
                  _barbers.add({
                    'id': 'barber_${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'isAvailable': true,
                    'workingDays': selectedDays,
                    'offDays': offDays,
                    'rating': 5.0,
                  });
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _onFinishOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await _partnerService.savePartnerProfile(
        phoneNumber: widget.phoneNumber,
        salonName: widget.salonName,
        address: widget.address,
        category: widget.category,
        openingTime: widget.openingTime,
        closingTime: widget.closingTime,
        weeklyOff: widget.weeklyOff,
        services: widget.services,
        barbers: _barbers,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        title: const Text('Add Salon Barbers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Your Salon Barbers',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add your barbers and customize their weekly working days so customers can book them on available dates.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STAFF (${_barbers.length})', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
                  TextButton.icon(
                    onPressed: _showAddBarberDialog,
                    icon: const Icon(Icons.add, color: Color(0xFF00FF00), size: 16),
                    label: const Text('Add Staff', style: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _barbers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00FF00), size: 28),
                            ),
                            const SizedBox(height: 14),
                            const Text('No Barbers Added Yet', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Click below to add your first staff member', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddBarberDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add First Staff Member'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _barbers.length,
                        itemBuilder: (context, idx) {
                          final b = _barbers[idx];
                          final name = (b['name'] ?? 'Barber').toString();
                          final rawWorkingDays = b['workingDays'] as List<dynamic>?;
                          final workingDays = rawWorkingDays != null
                              ? rawWorkingDays.map((e) => e.toString()).toList()
                              : _allWeekdays;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF262626)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00FF00).withOpacity(0.15),
                                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                    style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w900, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 2),
                                      Text(
                                        workingDays.length == 7 ? 'Works All 7 Days' : 'Works: ${workingDays.join(", ")}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                  onPressed: () => setState(() => _barbers.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onFinishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                      : const Text('Complete & Launch Salon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
