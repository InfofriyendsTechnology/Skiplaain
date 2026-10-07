import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_booking_service.dart';
import '../../utils/popup_utils.dart';
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
  final ApiService _apiService = ApiService();
  final ApiBookingService _bookingService = ApiBookingService();
  final TextEditingController _notesController = TextEditingController();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isBooking = false;

  String get _salonId => (widget.salon['id'] ?? 'salon_id').toString();
  String get _barberDisplayName => widget.barberName ?? 'Any Available Barber';

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    final token = await _apiService.getToken();
    if (token != null) {
      // TODO: Fetch customer profile from API
      _nameController = TextEditingController(text: '');
      _phoneController = TextEditingController(text: '');
    } else {
      _nameController = TextEditingController(text: '');
      _phoneController = TextEditingController(text: '');
    }
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
      
      final result = await _bookingService.createBooking(
        salonId: _salonId,
        salonName: salonName,
        salonPhone: (widget.salon['phone'] ?? '').toString(),
        salonAddress: (widget.salon['address'] ?? '').toString(),
        customerName: customerName,
        customerPhone: customerPhone,
        selectedServices: widget.selectedServices,
        totalAmount: widget.totalAmount,
        bookingDate: widget.bookingDate,
        timeSlot: widget.timeSlot,
        barberId: widget.barberId,
        barberName: _barberDisplayName,
        specialInstructions: _notesController.text.trim(),
      );

      final bookingId = (result['bookingId'] ?? result['id']).toString();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingTicketScreen(
            bookingId: bookingId,
            salonName: salonName,
            salonAddress: (widget.salon['address'] ?? '').toString(),
            salonPhone: (widget.salon['phone'] ?? '').toString(),
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
        PopupUtils.showErrorNotification(context, 'Failed to create booking: $e');
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
                      // Salon info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salonName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              salonAddress,
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFF262626)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF00FF00), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.displayDate} at ${widget.timeSlot}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Services
                      const Text(
                        'Selected Services',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...widget.selectedServices.map((service) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              service['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              '₹${service['price']}',
                              style: const TextStyle(color: Color(0xFF00FF00), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                      
                      const SizedBox(height: 16),

                      // Customer details
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF262626)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF262626)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Special Instructions (Optional)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF262626)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF141414),
                  border: Border(top: BorderSide(color: Color(0xFF262626))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          Text(
                            '₹${widget.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _onConfirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
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
