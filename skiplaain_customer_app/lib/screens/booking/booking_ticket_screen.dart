import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../my_bookings/my_bookings_screen.dart';

class BookingTicketScreen extends StatelessWidget {
  final String bookingId;
  final String salonName;
  final String salonAddress;
  final String salonPhone;
  final String customerName;
  final String customerPhone;
  final List<Map<String, dynamic>> selectedServices;
  final double totalAmount;
  final String displayDate;
  final String timeSlot;
  final String? barberName;

  const BookingTicketScreen({
    super.key,
    required this.bookingId,
    required this.salonName,
    required this.salonAddress,
    required this.salonPhone,
    required this.customerName,
    required this.customerPhone,
    required this.selectedServices,
    required this.totalAmount,
    required this.displayDate,
    required this.timeSlot,
    this.barberName,
  });

  @override
  Widget build(BuildContext context) {
    final assignedBarber = barberName ?? 'Any Available Barber';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Animated Token Check Badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00FF00), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF00).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt, color: Color(0xFF00FF00), size: 34),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Queue Token Generated',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Show this pass at the salon counter for instant line skip',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Digital Pass Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pass Header
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF162B16), Color(0xFF0F1A0F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'FAST-TRACK PASS',
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bookingId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF00).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
                                ),
                                child: Text(
                                  timeSlot.toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Salon Details
                              Text(
                                salonName,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      salonAddress,
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              const Divider(color: Color(0xFF262626), height: 1),
                              const SizedBox(height: 16),

                              // Details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTicketDetail('DATE', displayDate),
                                  _buildTicketDetail('TIME SLOT', timeSlot),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTicketDetail('BARBER / STYLIST', assignedBarber),
                                  _buildTicketDetail('QUEUE PASS', 'READY TO WALK-IN'),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTicketDetail('CUSTOMER', customerName),
                                  _buildTicketDetail('PHONE', customerPhone),
                                ],
                              ),

                              const SizedBox(height: 18),
                              const Divider(color: Color(0xFF262626), height: 1),
                              const SizedBox(height: 16),

                              // Services List
                              const Text(
                                'SERVICES FOR THIS VISIT',
                                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 8),
                              ...selectedServices.map((s) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
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

                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFF262626), height: 1),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Payable at Salon',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(0)}',
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

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF262626)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: const Text('View All Passes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetail(String title, String value) {
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
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
