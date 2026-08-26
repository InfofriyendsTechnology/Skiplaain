import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../appointment_details_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentData: {
                'customerName': name,
                'service': service,
                'time': '$date, $time',
                'price': price,
                'status': status,
                'barberName': barberName,
                'bookingId': bookingId,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262626)),
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00FF00).withOpacity(0.12),
                        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          bookingId,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'confirmed'
                        ? const Color(0xFF00FF00).withOpacity(0.15)
                        : (status.toLowerCase() == 'completed' ? Colors.blue.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: status.toLowerCase() == 'confirmed' ? const Color(0xFF00FF00).withOpacity(0.4) : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status.toLowerCase() == 'confirmed' ? const Color(0xFF00FF00) : (status.toLowerCase() == 'completed' ? Colors.blue : Colors.red),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF222222), height: 1),
            const SizedBox(height: 12),

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Live Queue & Bookings',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final List<Map<String, dynamic>> allBookings = docs.map((d) => {'id': d.id, ...d.data()}).toList();

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
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
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
                    ? Container(
                        margin: const EdgeInsets.all(18),
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_outlined, color: Colors.white24, size: 40),
                            SizedBox(height: 12),
                            Text('No Bookings Found', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Appointments booked by customers will appear here in real-time.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
