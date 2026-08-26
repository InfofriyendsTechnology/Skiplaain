import 'package:flutter/material.dart';
import '../../services/salon_service.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../auth/customer_onboarding_screen.dart';
import '../booking/booking_confirmation_screen.dart';
import '../my_bookings/my_bookings_screen.dart';
import '../profile/customer_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SalonService _salonService = SalonService();
  final CustomerAuthService _authService = CustomerAuthService();
  final BookingService _bookingService = BookingService();

  final TextEditingController _searchController = TextEditingController();

  int _activeTab = 0; // 0 = QR Scan, 1 = Search Shop
  String _searchQuery = '';
  String _selectedCity = 'Surat';
  bool _isFlashOn = false;

  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  final Set<int> _selectedServiceIndices = {};
  int _selectedPlanIndex = 2; // 0 = 3M (₹33), 1 = 6M (₹66), 2 = 12M (₹99)
  bool _isProcessingMembership = false;

  final List<Map<String, dynamic>> _plans = [
    {'name': '3 Months VIP', 'duration': 3, 'price': 33, 'perMonth': '₹11/mo', 'badge': 'STARTER'},
    {'name': '6 Months VIP', 'duration': 6, 'price': 66, 'perMonth': '₹11/mo', 'badge': 'POPULAR'},
    {'name': '12 Months VIP', 'duration': 12, 'price': 99, 'perMonth': '₹8.25/mo', 'badge': 'BEST VALUE'},
  ];

  final List<String> _popularCities = [
    'Surat',
    'Ahmedabad',
    'Vadodara',
    'Rajkot',
    'Navsari',
    'Valsad',
    'Bhavnagar',
    'Gandhinagar',
    'Mumbai',
    'Pune',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _checkSession();
  }

  void _checkSession() async {
    if (!_authService.isInitialized) {
      await _authService.initSession();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSalonSelected(Map<String, dynamic> salon) {
    if (_authService.isLoggedIn && _authService.customerName.isNotEmpty) {
      setState(() {
        _authService.connectSalon(salon);
        _selectedServiceIndices.clear();
      });
    } else {
      // Open dedicated 3-step onboarding: Phone -> OTP -> Name -> Salon Hub
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerOnboardingScreen(salon: salon),
        ),
      );
    }
  }

  // --- MULTI-SHOP SWITCHER MODAL ---
  void _openMyShopsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final saved = _authService.savedSalons;
        final currentId = (_authService.connectedSalon?['id'] ?? '').toString();

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF262626), width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Connected Shops',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Switch between your regular salons or connect a new one',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _authService.disconnectSalon();
                    _selectedServiceIndices.clear();
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162B16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00FF00), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan / Connect Another Shop',
                          style: TextStyle(color: Color(0xFF00FF00), fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Icon(Icons.add_rounded, color: Color(0xFF00FF00), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Saved Salons',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: saved.isEmpty
                    ? const Center(
                        child: Text('No saved salons yet', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      )
                    : ListView.builder(
                        itemCount: saved.length,
                        itemBuilder: (context, index) {
                          final s = saved[index];
                          final sId = (s['id'] ?? '').toString();
                          final sName = (s['salonName'] ?? s['businessName'] ?? 'Salon').toString();
                          final sAddr = (s['address'] ?? s['location'] ?? 'Surat').toString();
                          final isCurrent = sId == currentId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFF1E1E1E) : const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent ? const Color(0xFF00FF00) : const Color(0xFF262626),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF00).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  sName.isNotEmpty ? sName[0].toUpperCase() : 'S',
                                  style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(sName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00FF00),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('ACTIVE', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                                    ),
                                ],
                              ),
                              subtitle: Text(sAddr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              trailing: isCurrent
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF00), size: 18)
                                  : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
                              onTap: () {
                                _authService.switchActiveSalon(s);
                                Navigator.of(ctx).pop();
                                setState(() {
                                  _selectedServiceIndices.clear();
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
        title: const Text('Logout Account?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'This will clear your local session cache and log you out.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authService.logout();
              setState(() {
                _selectedServiceIndices.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authService.isConnectedToSalon) {
      return _buildConnectedSalonDashboard();
    }
    return _buildScanAndSearchLanding();
  }

  // --- CONNECTED SALON HUB DASHBOARD ---
  Widget _buildConnectedSalonDashboard() {
    final salon = _authService.connectedSalon!;
    final salonId = (salon['id'] ?? 'salon_id').toString();
    final salonName = (salon['salonName'] ?? salon['businessName'] ?? 'Salon').toString();
    final address = (salon['address'] ?? salon['location'] ?? 'Surat, Gujarat').toString();
    final category = (salon['category'] ?? 'Unisex').toString();
    final openingTime = (salon['openingTime'] ?? '09:00 AM').toString();
    final closingTime = (salon['closingTime'] ?? '09:00 PM').toString();
    final weeklyOff = (salon['weeklyOff'] ?? 'None').toString();
    final rating = (salon['rating'] ?? 5.0).toDouble();

    final rawServices = salon['services'] as List<dynamic>?;
    final List<Map<String, dynamic>> services = (rawServices != null && rawServices.isNotEmpty)
        ? rawServices.map((item) => Map<String, dynamic>.from(item as Map)).toList()
        : [
            {'name': 'Classic Haircut & Styling', 'price': 150, 'duration': 30, 'durationUnit': 'mins'},
            {'name': 'Beard Shaping & Lineup', 'price': 100, 'duration': 20, 'durationUnit': 'mins'},
            {'name': 'Deep Cleansing Hair Spa', 'price': 400, 'duration': 45, 'durationUnit': 'mins'},
            {'name': 'Charcoal Tan Removal Facial', 'price': 500, 'duration': 40, 'durationUnit': 'mins'},
          ];

    double totalAmount = 0;
    int totalDuration = 0;
    for (var index in _selectedServiceIndices) {
      if (index < services.length) {
        final p = double.tryParse(services[index]['price'].toString()) ?? 0;
        final d = int.tryParse(services[index]['duration'].toString()) ?? 30;
        totalAmount += p;
        totalDuration += d;
      }
    }

    final savedCount = _authService.savedSalons.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/images/full_logo.png', height: 26, fit: BoxFit.contain),
            const SizedBox(width: 10),
            InkWell(
              onTap: _openMyShopsModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: Color(0xFF00FF00), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Shops ($savedCount)',
                      style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00FF00), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 16),
            ),
            tooltip: 'My Passes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF162B16),
                border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.5), width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                _authService.customerName.isNotEmpty ? _authService.customerName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Color(0xFF00FF00), fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
            tooltip: 'My Profile & Visits',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF141414),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF262626))),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 16),
            ),
            onSelected: (val) {
              if (val == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                );
              }
              if (val == 'myshops') _openMyShopsModal();
              if (val == 'logout') _onLogout();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Color(0xFF00FF00), size: 18),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Profile & Visits', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(_authService.customerName.isNotEmpty ? _authService.customerName : 'View visits & VIP', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'myshops',
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00FF00), size: 18),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Connected Shops', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('$savedCount shops saved', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 10),
                    Text('Logout Account', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: _bookingService.streamSalonMembership(salonId, _authService.customerPhone),
            builder: (context, membershipSnapshot) {
              final activeMembership = membershipSnapshot.data;
              final isVip = activeMembership != null && (activeMembership['status'] == 'active');

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shop Overview Card
                          Container(
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
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00FF00).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.25)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        salonName.isNotEmpty ? salonName[0].toUpperCase() : 'S',
                                        style: const TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 22,
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
                                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    rating.toStringAsFixed(1),
                                                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w800),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '$category • $address',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFF262626), height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, color: Colors.white38, size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Hours: $openingTime - $closingTime (Off: $weeklyOff)',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // VIP Card
                          if (!isVip)
                            _buildUnsubscribedVipCard(salonId, salonName)
                          else
                            _buildActiveVipCard(salonName, activeMembership),

                          const SizedBox(height: 22),

                          // Service Checklist Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Services for Queue',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${services.length} Available',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Services List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              final service = services[index];
                              final isSelected = _selectedServiceIndices.contains(index);
                              final name = service['name'] ?? 'Service';
                              final price = service['price'] ?? 0;
                              final duration = service['duration'] ?? 30;
                              final unit = service['durationUnit'] ?? 'mins';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF162B16) : const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                                    width: isSelected ? 1.4 : 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedServiceIndices.remove(index);
                                        } else {
                                          _selectedServiceIndices.add(index);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF00FF00) : Colors.white38,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, color: Colors.black, size: 15)
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '$duration $unit duration',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹$price',
                                            style: const TextStyle(
                                              color: Color(0xFF00FF00),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Sticky Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF141414),
                      border: Border(top: BorderSide(color: Color(0xFF262626))),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedServiceIndices.length} items selected',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _selectedServiceIndices.isNotEmpty
                                  ? () {
                                      final selectedList = _selectedServiceIndices.map((i) => services[i]).toList();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BookingConfirmationScreen(
                                            salon: salon,
                                            selectedServices: selectedList,
                                            totalAmount: totalAmount,
                                            totalDurationMinutes: totalDuration,
                                            bookingDate: 'Today',
                                            displayDate: 'Today',
                                            timeSlot: 'Next Available (Walk-in)',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF00),
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: const Color(0xFF262626),
                                disabledForegroundColor: Colors.white38,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(isVip ? 'Get VIP Priority Token' : 'Get Live Queue Token'),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUnsubscribedVipCard(String salonId, String salonName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111A11),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$salonName VIP Pass',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildBenefitRow(Icons.bolt_rounded, 'Priority Line Skip at this salon'),
          _buildBenefitRow(Icons.stars_rounded, 'VIP Regular Customer status'),
          _buildBenefitRow(Icons.money_off_csred_rounded, 'Zero platform / convenience fees'),

          const SizedBox(height: 16),

          Row(
            children: List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlanIndex == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPlanIndex = index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${plan['duration']} Months',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${plan['price']}',
                            style: TextStyle(
                              color: isSelected ? Colors.black : const Color(0xFF00FF00),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            plan['perMonth'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isProcessingMembership ? null : () => _buyMembership(salonId, salonName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              child: _isProcessingMembership
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text('Join VIP for ₹${_plans[_selectedPlanIndex]['price']} (${_plans[_selectedPlanIndex]['duration']} Months)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVipCard(String salonName, Map<String, dynamic> membership) {
    final planName = (membership['planName'] ?? 'VIP Pass').toString();
    final expiryDisplay = (membership['expiryDisplay'] ?? 'Active').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162B16), Color(0xFF0D180D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF00).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '$salonName VIP Pass',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE VIP',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF262626), height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MEMBERSHIP PLAN', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(planName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('VALID UNTIL', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(expiryDisplay, style: const TextStyle(color: Color(0xFF00FF00), fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF00FF00), size: 16),
                SizedBox(width: 8),
                Text(
                  'Priority Line Skip is active for all your visits here.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _buyMembership(String salonId, String salonName) async {
    final plan = _plans[_selectedPlanIndex];
    setState(() => _isProcessingMembership = true);

    try {
      final membershipData = await _bookingService.saveShopMembership(
        salonId: salonId,
        salonName: salonName,
        customerPhone: _authService.customerPhone,
        customerName: _authService.customerName,
        planName: plan['name'] as String,
        price: plan['price'] as int,
        durationMonths: plan['duration'] as int,
      );

      _authService.activateSalonMembership(
        salonId,
        plan['name'] as String,
        plan['price'] as int,
        plan['duration'] as int,
      );

      if (!mounted) return;
      setState(() => _isProcessingMembership = false);

      _showMembershipSuccessDialog(salonName, membershipData);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingMembership = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate VIP pass: $e')),
        );
      }
    }
  }

  void _showMembershipSuccessDialog(String salonName, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF00FF00), width: 1.2),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FF00), width: 2),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'VIP Pass Activated!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'You are now an active VIP member of $salonName',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plan', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(data['planName'] ?? 'VIP Pass', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valid Until', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(data['expiryDisplay'] ?? 'Active', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Line Skip Priority', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('UNLOCKED', style: TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                child: const Text('Start Using VIP Pass'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- SCAN & SEARCH LANDING (ONLY WHEN NOT CONNECTED) ---
  Widget _buildScanAndSearchLanding() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _salonService.streamSalons(),
              builder: (context, snapshot) {
                final salons = snapshot.data ?? [];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/full_logo.png',
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _openCitySelectorModal,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF262626)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFF00FF00), size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        _selectedCity,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _authService.isLoggedIn ? const Color(0xFF00FF00).withOpacity(0.5) : const Color(0xFF262626),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: _authService.isLoggedIn && _authService.customerName.isNotEmpty
                                      ? Text(
                                          _authService.customerName[0].toUpperCase(),
                                          style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w900, fontSize: 14),
                                        )
                                      : const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'Scan QR', Icons.qr_code_scanner_rounded),
                            _buildTabItem(1, 'Search Shop', Icons.search_rounded),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            if (_activeTab == 0) _buildQrScannerTab(salons),
                            if (_activeTab == 1) _buildSearchTab(salons),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openCitySelectorModal() {
    String cityFilter = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final filteredCities = _popularCities.where((c) {
              if (cityFilter.isEmpty) return true;
              return c.toLowerCase().contains(cityFilter.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF262626), width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Your City',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    onChanged: (val) => setModalState(() => cityFilter = val.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search city...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () {
                      setState(() => _selectedCity = 'Surat');
                      Navigator.of(modalContext).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162B16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.my_location_rounded, color: Color(0xFF00FF00), size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Use Current Location',
                            style: TextStyle(color: Color(0xFF00FF00), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Available Cities',
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final isSelected = _selectedCity == city;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            leading: Icon(
                              Icons.location_city_rounded,
                              color: isSelected ? const Color(0xFF00FF00) : Colors.white38,
                              size: 18,
                            ),
                            title: Text(
                              city,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF00FF00) : Colors.white,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded, color: Color(0xFF00FF00), size: 18)
                                : null,
                            onTap: () {
                              setState(() => _selectedCity = city);
                              Navigator.of(modalContext).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF00).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.black : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScannerTab(List<Map<String, dynamic>> salons) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Scan Counter QR',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Point your camera at the salon counter QR to connect',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 28),

        InkWell(
          onTap: () {
            if (salons.isNotEmpty) {
              _onSalonSelected(salons.first);
            }
          },
          borderRadius: BorderRadius.circular(32),
          child: Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF222222), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF00).withOpacity(0.06),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF00FF00).withOpacity(0.2),
                        size: 110,
                      ),
                    ),
                  ),
                  Positioned(top: 24, left: 24, child: _buildCornerBracket(top: true, left: true)),
                  Positioned(top: 24, right: 24, child: _buildCornerBracket(top: true, left: false)),
                  Positioned(bottom: 24, left: 24, child: _buildCornerBracket(top: false, left: true)),
                  Positioned(bottom: 24, right: 24, child: _buildCornerBracket(top: false, left: false)),
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: 30 + (_scanLineAnim.value * 200),
                        left: 36,
                        right: 36,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Color(0xFF00FF00), Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF00).withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => setState(() => _isFlashOn = !_isFlashOn),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isFlashOn ? const Color(0xFF162B16) : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isFlashOn ? const Color(0xFF00FF00) : const Color(0xFF262626)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? const Color(0xFF00FF00) : Colors.white60,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFlashOn ? 'Flash On' : 'Flashlight',
                      style: TextStyle(color: _isFlashOn ? const Color(0xFF00FF00) : Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    const double size = 22;
    const double thickness = 3.5;
    const color = Color(0xFF00FF00);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildSearchTab(List<Map<String, dynamic>> salons) {
    final filtered = salons.where((s) {
      if (_searchQuery.isEmpty) return false;
      final name = (s['salonName'] ?? s['businessName'] ?? '').toString().toLowerCase();
      final addr = (s['address'] ?? s['location'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || addr.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search in $_selectedCity...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF141414),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF262626)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF262626)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Colors.white38, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'Search Salons in $_selectedCity',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Type your salon or barber shop name above',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'No salons found in $_selectedCity matching your search.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          ...filtered.map((salon) {
            final name = (salon['salonName'] ?? salon['businessName'] ?? 'Salon').toString();
            final addr = (salon['address'] ?? salon['location'] ?? _selectedCity).toString();
            final category = (salon['category'] ?? 'Unisex').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF242424)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$category • $addr', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00FF00), size: 14),
                onTap: () => _onSalonSelected(salon),
              ),
            );
          }),
      ],
    );
  }
}
