import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_auth_service.dart';
import '../../utils/popup_utils.dart';
import '../../services/api_booking_service.dart';
import '../booking/booking_ticket_screen.dart';
import '../my_bookings/my_bookings_screen.dart';
import '../home/home_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final ApiService _apiService = ApiService();
  final ApiBookingService _bookingService = ApiBookingService();
  final ApiAuthService _authService = ApiAuthService();

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _authService.customerName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
        title: const Text('Edit Full Name', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your updated name:', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateCustomerName(newName);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  void _onLogout() async {
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Logout Account?',
      message: 'This will clear your local session and return you to the connect screen.',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirmed) {
      await _authService.logout();
      if (mounted && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  String _formatPhoneDisplay(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 10) {
      final last10 = clean.substring(clean.length - 10);
      return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.isLoggedIn;
    final customerName = _authService.customerName.isEmpty ? 'Guest Customer' : _authService.customerName;
    final customerPhone = _authService.customerPhone;
    final initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : 'U';

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
          'My Profile & Visits',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF262626)),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              tooltip: 'Logout',
              onPressed: _onLogout,
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROFILE HEADER CARD
                _buildProfileHeaderCard(customerName, customerPhone, initial, isLoggedIn),

                const SizedBox(height: 20),

                if (!isLoggedIn)
                  _buildGuestLoginBanner()
                else ...[
                  // 2. STATS OVERVIEW & SALON VISITS DATA STREAM
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getRecentBookings(),
                    builder: (context, bookingsSnapshot) {
                      final bookings = bookingsSnapshot.data ?? [];

                      return FutureBuilder<int>(
                        future: _getMembershipCount(),
                        builder: (context, membershipsSnapshot) {
                          final memberships = <Map<String, dynamic>>[];
                          final activeMemberships = memberships.where((m) => m['status'] == 'active').toList();

                          // Calculate stats
                          final totalVisits = bookings.length;
                          double totalSpent = 0;
                          final Map<String, Map<String, dynamic>> salonBreakdown = {};

                          for (var b in bookings) {
                            final p = double.tryParse(b['totalAmount']?.toString() ?? '') ?? 0;
                            totalSpent += p;

                            final sId = (b['salonId'] ?? b['salonName'] ?? 'Salon').toString();
                            final sName = (b['salonName'] ?? 'Salon').toString();
                            final sAddr = (b['salonAddress'] ?? '').toString();
                            final bDate = (b['bookingDate'] ?? b['createdAt'] ?? '').toString();

                            if (!salonBreakdown.containsKey(sId)) {
                              salonBreakdown[sId] = {
                                'salonId': sId,
                                'salonName': sName,
                                'salonAddress': sAddr,
                                'visitCount': 1,
                                'totalSpent': p,
                                'lastVisit': bDate,
                              };
                            } else {
                              salonBreakdown[sId]!['visitCount'] = (salonBreakdown[sId]!['visitCount'] as int) + 1;
                              salonBreakdown[sId]!['totalSpent'] = (salonBreakdown[sId]!['totalSpent'] as double) + p;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 4-Stats Grid
                              _buildStatsGrid(
                                totalVisits: totalVisits,
                                totalSalons: salonBreakdown.length,
                                activeVips: activeMemberships.length,
                                totalSpent: totalSpent,
                              ),

                              const SizedBox(height: 24),

                              // ACTIVE VIP PASSES SECTION
                              if (activeMemberships.isNotEmpty) ...[
                                _buildSectionHeader('Active Shop VIP Passes', Icons.workspace_premium_rounded, '${activeMemberships.length} Active'),
                                const SizedBox(height: 12),
                                ...activeMemberships.map((m) => _buildVipPassItem(m)),
                                const SizedBox(height: 24),
                              ],

                              // SALON VISITS BREAKDOWN ("ક્યા સલૂનમાં કેટલા આવ્યા")
                              _buildSectionHeader('Salons Visited & Visit Counts', Icons.storefront_rounded, '${salonBreakdown.length} Salons'),
                              const SizedBox(height: 12),

                              if (salonBreakdown.isEmpty)
                                _buildEmptyStateCard(
                                  icon: Icons.history_rounded,
                                  title: 'No Salon Visits Yet',
                                  subtitle: 'Scan a salon QR or get a queue pass to start tracking your visits here.',
                                )
                              else
                                ...salonBreakdown.values.map((salonData) => _buildSalonVisitCard(salonData, activeMemberships.toList())),

                              const SizedBox(height: 24),

                              // RECENT APPOINTMENT PASSES
                              _buildSectionHeader('Recent Queue Passes', Icons.confirmation_num_outlined, '${bookings.length} Total'),
                              const SizedBox(height: 12),

                              if (bookings.isEmpty)
                                _buildEmptyStateCard(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No Passes Booked',
                                  subtitle: 'Your active queue tickets and passes will appear here.',
                                )
                              else
                                ...bookings.take(3).map((b) => _buildRecentBookingItem(b)),

                              if (bookings.length > 3) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF00FF00), size: 16),
                                    label: Text(
                                      'View All ${bookings.length} Passes',
                                      style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 30),

                // ACCOUNT SETTINGS / FOOTER ACTIONS
                _buildAccountActionsCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PROFILE HEADER CARD ---
  Widget _buildProfileHeaderCard(String name, String phone, String initial, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF262626)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF00).withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF00), Color(0xFF008800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF00).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name & Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _showEditNameDialog,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Color(0xFF00FF00), size: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? _formatPhoneDisplay(phone) : 'Not Logged In',
                      style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF00FF00), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                isLoggedIn ? 'VERIFIED CUSTOMER' : 'GUEST',
                                style: const TextStyle(color: Color(0xFF00FF00), fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4 STATS GRID ---
  Widget _buildStatsGrid({
    required int totalVisits,
    required int totalSalons,
    required int activeVips,
    required double totalSpent,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'TOTAL VISITS',
            value: totalVisits.toString(),
            icon: Icons.repeat_rounded,
            accentColor: const Color(0xFF00FF00),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'SHOPS VISITED',
            value: totalSalons.toString(),
            icon: Icons.storefront_rounded,
            accentColor: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'VIP PASSES',
            value: activeVips.toString(),
            icon: Icons.workspace_premium_rounded,
            accentColor: Colors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'TOTAL SPENT',
            value: '₹${totalSpent.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_outlined,
            accentColor: Colors.purpleAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- SALON VISITS ITEM ("ક્યા સલૂનમાં કેટલા આવ્યા") ---
  Widget _buildSalonVisitCard(Map<String, dynamic> data, List<Map<String, dynamic>> memberships) {
    final salonName = (data['salonName'] ?? 'Salon').toString();
    final salonAddress = (data['salonAddress'] ?? 'Surat, Gujarat').toString();
    final visitCount = data['visitCount'] as int? ?? 1;
    final totalSpent = (data['totalSpent'] as double? ?? 0).toStringAsFixed(0);
    final lastVisit = (data['lastVisit'] ?? 'Recently').toString();

    // Check if user has active VIP pass for this specific salon
    final isShopVip = memberships.any((m) =>
        m['status'] == 'active' &&
        ((m['salonName'] ?? '').toString().toLowerCase() == salonName.toLowerCase() ||
         (m['salonId'] ?? '').toString() == (data['salonId'] ?? '').toString()));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isShopVip ? const Color(0xFF00FF00).withOpacity(0.4) : const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isShopVip ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isShopVip ? const Color(0xFF00FF00).withOpacity(0.3) : const Color(0xFF333333)),
                ),
                alignment: Alignment.center,
                child: Text(
                  salonName.isNotEmpty ? salonName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: isShopVip ? const Color(0xFF00FF00) : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            salonName,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isShopVip)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('VIP MEMBER', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      salonAddress,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 10),

          // Visit Stats Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162B16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded, color: Color(0xFF00FF00), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '$visitCount Visits Total',
                          style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹$totalSpent spent',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                'Last: $lastVisit',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- VIP PASS ITEM CARD ---
  Widget _buildVipPassItem(Map<String, dynamic> membership) {
    final salonName = (membership['salonName'] ?? 'Salon').toString();
    final planName = (membership['planName'] ?? 'VIP Pass').toString();
    final expiryDisplay = (membership['expiryDisplay'] ?? 'Active').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162B16), Color(0xFF0F1B0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$salonName VIP Pass',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '$planName • Valid until $expiryDisplay',
                  style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('PRIORITY', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // --- RECENT BOOKING ITEM ---
  Widget _buildRecentBookingItem(Map<String, dynamic> booking) {
    final salonName = (booking['salonName'] ?? 'Salon').toString();
    final service = (booking['service'] ?? 'Haircut').toString();
    final bookingId = (booking['bookingId'] ?? booking['id'] ?? '#SKP').toString();
    final date = (booking['bookingDate'] ?? 'Today').toString();
    final time = (booking['timeSlot'] ?? booking['time'] ?? 'Walk-in').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF00FF00), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        salonName,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      bookingId,
                      style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$service • $date at $time',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
            onPressed: () {
              final rawServices = booking['services'] as List<dynamic>?;
              final List<Map<String, dynamic>> servicesList = rawServices != null
                  ? rawServices.map((s) => Map<String, dynamic>.from(s as Map)).toList()
                  : [{'name': service, 'price': booking['totalAmount'] ?? 0}];

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingTicketScreen(
                    bookingId: bookingId,
                    salonName: salonName,
                    salonAddress: (booking['salonAddress'] ?? '').toString(),
                    salonPhone: (booking['salonPhone'] ?? '').toString(),
                    customerName: (booking['customerName'] ?? _authService.customerName).toString(),
                    customerPhone: (booking['customerPhone'] ?? _authService.customerPhone).toString(),
                    selectedServices: servicesList,
                    totalAmount: double.tryParse(booking['totalAmount']?.toString() ?? '') ?? 0,
                    displayDate: date,
                    timeSlot: time,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- SECTION HEADER ---
  Widget _buildSectionHeader(String title, IconData icon, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00FF00), size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: Text(
            badge,
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 32),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGuestLoginBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162B16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle_outlined, color: Color(0xFF00FF00), size: 36),
          const SizedBox(height: 10),
          const Text(
            'Connect with Your Mobile Number',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Login to track your salon visits, view active VIP passes, and save your favourite barber shops.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            child: const Text('Scan Counter QR to Login'),
          ),
        ],
      ),
    );
  }

  // --- ACCOUNT ACTIONS CARD ---
  Widget _buildAccountActionsCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF00FF00), size: 20),
            title: const Text('My Queue Passes & Bookings', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          const Divider(color: Color(0xFF222222), height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
            title: const Text('Edit Customer Profile Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
            onTap: _showEditNameDialog,
          ),
          if (_authService.isLoggedIn) ...[
            const Divider(color: Color(0xFF222222), height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              title: const Text('Logout Account', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
              onTap: _onLogout,
            ),
          ],
        ],
      ),
    );
  }

  Future<int> _getBookingCount() async {
    try {
      final phone = await _apiService.getUserPhone();
      if (phone != null) {
        final bookings = await _bookingService.getCustomerBookings(phone);
        return bookings.length;
      }
    } catch (e) {
      // Ignore
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> _getRecentBookings() async {
    try {
      final phone = await _apiService.getUserPhone();
      if (phone != null) {
        final bookings = await _bookingService.getCustomerBookings(phone);
        return bookings.take(3).toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  Future<int> _getMembershipCount() async {
    // TODO: Implement with API
    return 0;
  }
}
