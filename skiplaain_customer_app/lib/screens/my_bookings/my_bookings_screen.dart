import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/status_badge.dart';
import '../../utils/popup_utils.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final CustomerAuthService _authService = CustomerAuthService();

  void _onCancelBooking(String bookingId) async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Cancel Appointment?',
      message: 'Are you sure you want to cancel this booking?',
      confirmText: 'Yes, Cancel',
      cancelText: 'Keep It',
      isDangerous: true,
    );

    if (confirmed) {
      try {
        await _bookingService.cancelBooking(
          bookingId,
          cancelledBy: 'customer',
          reason: 'Cancelled by customer',
        );
        if (mounted) {
          HapticFeedback.lightImpact();
          PopupUtils.showSuccessNotification(
            context,
            'Appointment cancelled',
          );
        }
      } catch (e) {
        if (mounted) {
          PopupUtils.showErrorNotification(
            context,
            'Failed to cancel appointment',
          );
        }
      }
    }
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

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingDetailScreen(
                            bookingData: b,
                          ),
                        ),
                      );
                    },
                    child: Container(
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
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              StatusBadge(status: status, compact: true),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            salonName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (salonAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              salonAddress,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF262626), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF00FF00),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$bookingDate at $timeSlot',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Services: $serviceSummary',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.3),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
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
