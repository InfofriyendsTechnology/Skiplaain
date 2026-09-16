import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/partner_service.dart';
import '../appointment_details_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PartnerService _partnerService = PartnerService();
  bool _isOnline = true;

  Widget _buildStatCard({required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF00FF00), size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem({
    required BuildContext context,
    required Map<String, dynamic> booking,
  }) {
    final name = (booking['customerName'] ?? 'Customer').toString();
    final service = (booking['service'] ?? 'Service').toString();
    final time = (booking['timeSlot'] ?? booking['time'] ?? 'Walk-in').toString();
    final price = (booking['price'] ?? '₹${booking['totalAmount'] ?? 0}').toString();
    final status = (booking['status'] ?? 'confirmed').toString().toUpperCase();
    final barberName = (booking['barberName'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentData: {
                'customerName': name,
                'service': service,
                'time': time,
                'price': price,
                'status': status,
                'barberName': barberName,
                'bookingId': booking['id'] ?? booking['bookingId'] ?? '#SKP',
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2E1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      time.split(' ').join('\n'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          service,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        if (barberName.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                          Text(
                            barberName,
                            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price.startsWith('₹') ? price : '₹$price',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'CONFIRMED' ? const Color(0xFF162B16) : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'CONFIRMED' ? const Color(0xFF00FF00) : Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
    final currentPartnerId = _partnerService.currentUid;
    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _partnerService.streamPartnerProfile(currentPartnerId),
      builder: (context, profileSnapshot) {
        final profileData = profileSnapshot.data?.data() ?? {};
        final salonName = (profileData['salonName'] ?? profileData['businessName'] ?? 'My Salon').toString();
        final ownerName = (profileData['ownerName'] ?? 'Partner').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('bookings').snapshots(),
          builder: (context, bookingsSnapshot) {
            final allDocs = bookingsSnapshot.data?.docs ?? [];
            
            // Filter bookings for this salon
            final salonBookings = allDocs
                .map((d) => {'id': d.id, ...d.data()})
                .where((b) {
                  final sId = (b['salonId'] ?? '').toString();
                  final sName = (b['salonName'] ?? '').toString();
                  return sId == currentPartnerId || (sName.isNotEmpty && sName.toLowerCase() == salonName.toLowerCase());
                })
                .toList();

            // Calculate Today's Real Stats
            int todayRevenue = 0;
            int todayBookingsCount = 0;

            for (var b in salonBookings) {
              final bDate = (b['bookingDate'] ?? '').toString();
              // If booking is today or no date specified (today)
              if (bDate.contains(todayIso) || bDate.isEmpty || bDate.toLowerCase() == 'today') {
                todayBookingsCount++;
                final amt = int.tryParse(b['totalAmount']?.toString() ?? '') ?? 
                            int.tryParse(b['price']?.toString().replaceAll(RegExp(r'\D'), '') ?? '') ?? 0;
                todayRevenue += amt;
              }
            }

            // Real upcoming appointments (sorted by createdAt or time)
            final upcomingAppointments = salonBookings.take(5).toList();

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $ownerName',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  salonName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _isOnline ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  color: _isOnline ? const Color(0xFF00FF00) : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _isOnline,
                                onChanged: (val) {
                                  setState(() => _isOnline = val);
                                },
                                activeColor: Colors.black,
                                activeTrackColor: const Color(0xFF00FF00),
                                inactiveThumbColor: Colors.black,
                                inactiveTrackColor: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Real Stats
                      Row(
                        children: [
                          _buildStatCard(
                            title: "Today's Revenue",
                            value: "₹$todayRevenue",
                            icon: Icons.currency_rupee_rounded,
                          ),
                          const SizedBox(width: 14),
                          _buildStatCard(
                            title: "Today's Bookings",
                            value: "$todayBookingsCount",
                            icon: Icons.calendar_month_rounded,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Upcoming Appointments Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Appointments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${salonBookings.length} Total',
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Real Upcoming Appointments List or Clean Empty State
                      if (upcomingAppointments.isNotEmpty)
                        ...upcomingAppointments.map((b) => _buildAppointmentItem(context: context, booking: b))
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.calendar_today_rounded, color: Colors.white24, size: 36),
                              SizedBox(height: 12),
                              Text(
                                'No Upcoming Appointments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Real-time appointments will appear here when customers book via Skiplaain app.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
