import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final CustomerAuthService _authService = CustomerAuthService();

  void _onCancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
        title: const Text('Cancel Appointment?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to cancel this booking slot?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Appointment', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _bookingService.cancelBooking(bookingId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'My Appointments',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _bookingService.streamCustomerBookings(_authService.customerPhone),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FF00)),
                );
              }

              final bookings = snapshot.data ?? [];

              if (bookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF00FF00), size: 26),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Appointments Yet',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your confirmed salon appointments will appear here.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final b = bookings[index];
                  final bookingId = (b['bookingId'] ?? b['id'] ?? '').toString();
                  final salonName = (b['salonName'] ?? 'Salon').toString();
                  final salonAddress = (b['salonAddress'] ?? '').toString();
                  final bookingDate = (b['bookingDate'] ?? '').toString();
                  final timeSlot = (b['timeSlot'] ?? b['time'] ?? '').toString();
                  final status = (b['status'] ?? 'confirmed').toString().toLowerCase();
                  final price = (b['price'] ?? '₹${b['totalAmount'] ?? 0}').toString();
                  final services = (b['services'] as List<dynamic>?) ?? [];
                  final serviceSummary = (b['service'] ?? services.map((s) => s['name']).join(', ')).toString();

                  final isConfirmed = status == 'confirmed';
                  final isCompleted = status == 'completed';

                  Color badgeColor = const Color(0xFF00FF00);
                  if (status == 'cancelled') {
                    badgeColor = const Color(0xFFEF4444);
                  } else if (isCompleted) {
                    badgeColor = const Color(0xFF38BDF8);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bookingId,
                              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          salonName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        if (salonAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(salonAddress, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF262626), height: 1),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFF00FF00), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '$bookingDate at $timeSlot',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              price,
                              style: const TextStyle(color: Color(0xFF00FF00), fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Services: $serviceSummary',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),

                        if (isConfirmed) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () => _onCancelBooking(b['id']),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel Appointment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
