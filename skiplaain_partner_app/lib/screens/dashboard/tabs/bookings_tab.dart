import 'package:flutter/material.dart';
import '../../../services/partner_service.dart';
import '../../../services/booking_service.dart';
import '../../../widgets/status_badge.dart';
import '../appointment_details_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final BookingService _bookingService = BookingService();
  final PartnerService _partnerService = PartnerService();
  String _selectedFilter = 'All'; // 'All', 'Confirmed', 'Completed', 'Cancelled'

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final name = (booking['customerName'] ?? 'Customer').toString();
    final service = (booking['service'] ?? 'Haircut').toString();
    final price = (booking['price'] ?? '₹${booking['totalAmount'] ?? 0}').toString();
    final date = (booking['bookingDate'] ?? 'Today').toString();
    final time = (booking['timeSlot'] ?? booking['time'] ?? 'Walk-in').toString();
    final status = (booking['status'] ?? 'confirmed').toString();
    final barberName = (booking['barberName'] ?? 'Any Available Barber').toString();
    final bookingId = (booking['bookingId'] ?? booking['id'] ?? '#SKP').toString();
    final isNew = booking['viewedByPartner'] != true && status.toLowerCase() == 'confirmed';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentData: booking,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew ? const Color(0xFF00FF00) : const Color(0xFF262626),
            width: isNew ? 2 : 1,
          ),
          boxShadow: isNew
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF00).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00FF00).withOpacity(0.2),
                            const Color(0xFF00FF00).withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF00FF00).withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF00),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bookingId,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(status: status, compact: true),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF222222), height: 1),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Booked', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(service, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(price, style: const TextStyle(color: Color(0xFF00FF00), fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barber & Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF00FF00), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      barberName,
                      style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$date, $time',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerId = _partnerService.currentPartnerId;
    
    if (partnerId == null || partnerId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Partner ID not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _bookingService.streamPartnerBookings(partnerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF00)),
            );
          }

          final allBookings = snapshot.data ?? [];

          final filteredBookings = allBookings.where((b) {
            if (_selectedFilter == 'All') return true;
            final status = (b['status'] ?? 'confirmed').toString().toLowerCase();
            return status == _selectedFilter.toLowerCase();
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Confirmed'),
                      _buildFilterChip('Completed'),
                      _buildFilterChip('Cancelled'),
                    ],
                  ),
                ),
              ),

              // List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
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
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF00FF00),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No bookings yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New appointments will appear here',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(context, filteredBookings[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
