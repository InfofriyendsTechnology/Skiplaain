import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import 'booking_ticket_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> salon;
  final List<Map<String, dynamic>> selectedServices;
  final double totalAmount;
  final int totalDurationMinutes;
  final String bookingDate;
  final String displayDate;
  final String timeSlot;
  final String? barberId;
  final String? barberName;

  const BookingConfirmationScreen({
    super.key,
    required this.salon,
    required this.selectedServices,
    required this.totalAmount,
    required this.totalDurationMinutes,
    required this.bookingDate,
    required this.displayDate,
    required this.timeSlot,
    this.barberId,
    this.barberName,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final CustomerAuthService _authService = CustomerAuthService();
  final BookingService _bookingService = BookingService();
  final TextEditingController _notesController = TextEditingController();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isBooking = false;

  String get _salonId => (widget.salon['id'] ?? 'salon_id').toString();
  bool get _isVipMember => _authService.isVipMemberForSalon(_salonId);
  String get _barberDisplayName => widget.barberName ?? 'Any Available Barber';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authService.customerName.isEmpty ? '' : _authService.customerName);
    _phoneController = TextEditingController(text: _authService.customerPhone.isEmpty ? '' : _authService.customerPhone);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onConfirmBooking() async {
    if (_isBooking) return;

    final customerName = _nameController.text.trim().isEmpty ? 'Customer' : _nameController.text.trim();
    final customerPhone = _phoneController.text.trim().isEmpty ? '+919876543210' : _phoneController.text.trim();

    setState(() => _isBooking = true);

    try {
      final salonName = (widget.salon['salonName'] ?? widget.salon['businessName'] ?? 'Salon').toString();
      final salonPhone = (widget.salon['phone'] ?? '').toString();
      final salonAddress = (widget.salon['address'] ?? widget.salon['location'] ?? '').toString();

      final bookingId = await _bookingService.createBooking(
        salonId: _salonId,
        salonName: salonName,
        salonPhone: salonPhone,
        salonAddress: salonAddress,
        customerName: customerName,
        customerPhone: customerPhone,
        selectedServices: widget.selectedServices,
        totalAmount: widget.totalAmount,
        bookingDate: widget.bookingDate,
        timeSlot: widget.timeSlot,
        barberId: widget.barberId ?? 'any',
        barberName: _barberDisplayName,
        specialInstructions: _notesController.text.trim(),
      );

      _authService.setCustomerProfile(customerName, customerPhone);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingTicketScreen(
            bookingId: bookingId,
            salonName: salonName,
            salonAddress: salonAddress,
            salonPhone: salonPhone,
            customerName: customerName,
            customerPhone: customerPhone,
            selectedServices: widget.selectedServices,
            totalAmount: widget.totalAmount,
            displayDate: widget.displayDate,
            timeSlot: widget.timeSlot,
            barberName: _barberDisplayName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonName = (widget.salon['salonName'] ?? widget.salon['businessName'] ?? 'Salon').toString();
    final salonAddress = (widget.salon['address'] ?? widget.salon['location'] ?? 'Surat, Gujarat').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirm Appointment',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connected Shop Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FF00).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF00FF00), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salonName,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        salonAddress,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF262626), height: 1),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailColumn('DATE', widget.displayDate),
                                _buildDetailColumn('TIME SLOT', widget.timeSlot),
                                _buildDetailColumn('BARBER', _barberDisplayName),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // VIP Priority Line Skip Badge if Member
                      if (_isVipMember) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF162B16), Color(0xFF0F1A0F)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Active VIP Member of $salonName • Priority Line Skip applied!',
                                  style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Customer Details Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Information',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Your Name',
                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white54, size: 18),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF262626)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF262626)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF00FF00)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Mobile Phone Number',
                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white54, size: 18),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF262626)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF262626)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF00FF00)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Services & Bill
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Services & Bill',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 14),
                            ...widget.selectedServices.map((s) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s['name'] ?? 'Service',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    Text(
                                      '₹${s['price']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            const Divider(color: Color(0xFF262626), height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable at Salon', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                Text(
                                  '₹${widget.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFF00FF00), fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFF141414),
                  border: Border(top: BorderSide(color: Color(0xFF262626))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _onConfirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    child: _isBooking
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : const Text('Confirm Appointment'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
