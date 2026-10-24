import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_salon_service.dart';
import '../../services/api_auth_service.dart';
import '../../services/api_subscription_service.dart';
import '../../utils/popup_utils.dart';
import '../auth/customer_onboarding_screen.dart';
import '../booking/booking_confirmation_screen.dart';
import '../my_bookings/my_bookings_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../profile/customer_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiSalonService _salonService = ApiSalonService();
  final ApiAuthService _authService = ApiAuthService();
  final ApiSubscriptionService _subService = ApiSubscriptionService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  int _activeTab = 0; // 0 = QR Scan, 1 = Search Shop
  String _searchQuery = '';
  String _selectedCity = 'Surat';
  bool _isFlashOn = false;
  bool _isSearching = false;

  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  final Set<int> _selectedServiceIndices = {};
  int _selectedPlanIndex = 0;
  bool _isProcessingMembership = false;

  // Subscription state — loaded from API when salon is connected
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic> _subscriptionStatus = {'hasActivePlan': false, 'plansEnabled': false};
  bool _isLoadingSubscription = false;
  String _loadedSubscriptionForSalonId = '';

  List<Map<String, dynamic>> _salons = [];
  List<Map<String, dynamic>> _filteredSalons = [];
  bool _isLoadingSalons = true;
  final List<String> _searchHistory = [];

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
    _loadSalons();
  }

  void _checkSession() async {
    await _authService.initSession();
    if (mounted) {
      setState(() {});
      // If already connected to a salon, load its subscription data
      final salon = _authService.connectedSalon;
      if (salon != null) {
        final salonId = (salon['id'] ?? '').toString();
        if (salonId.isNotEmpty) _loadSubscriptionData(salonId);
      }
    }
  }

  Future<void> _loadSubscriptionData(String salonId) async {
    if (salonId.isEmpty || salonId == _loadedSubscriptionForSalonId) return;
    if (!mounted) return;
    setState(() => _isLoadingSubscription = true);
    try {
      final results = await Future.wait([
        _subService.getPlansForSalon(salonId),
        _subService.getSubscriptionStatus(salonId),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<Map<String, dynamic>>;
          _subscriptionStatus = results[1] as Map<String, dynamic>;
          _selectedPlanIndex = 0;
          _isLoadingSubscription = false;
          _loadedSubscriptionForSalonId = salonId;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSubscription = false);
    }
  }
  
  Future<void> _loadSalons() async {
    if (!mounted) return;
    
    setState(() => _isLoadingSalons = true);
    
    try {
      final salons = await _salonService.getAllSalons();
      if (mounted) {
        setState(() {
          _salons = salons;
          _filteredSalons = salons;
          _isLoadingSalons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSalons = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchQuery = '';
          _filteredSalons = _salons;
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isSearching = true);
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      
      try {
        final results = await _salonService.searchSalons(query.trim(), city: _selectedCity);
        
        if (mounted) {
          setState(() {
            _searchQuery = query.trim().toLowerCase();
            _filteredSalons = results;
            _isSearching = false;
            
            if (query.trim().length > 2 && !_searchHistory.contains(query.trim())) {
              _searchHistory.insert(0, query.trim());
              if (_searchHistory.length > 5) _searchHistory.removeLast();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _filteredSalons = _salons;
            _isSearching = false;
          });
        }
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _filteredSalons = _salons;
        _isSearching = false;
      });
    }
  }

  void _applySearchHistory(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScanQR() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const QRScannerScreen(),
        ),
      );

      if (result != null && result is String) {
        // Parse QR code result - expecting salon ID or skiplaain://salon/<id> URL
        String salonId = result;
        
        if (result.startsWith('skiplaain://salon/')) {
          salonId = result.substring('skiplaain://salon/'.length);
        } else if (result.startsWith('http://') || result.startsWith('https://')) {
          // Handle URL format if needed
          final uri = Uri.tryParse(result);
          if (uri != null && uri.pathSegments.isNotEmpty) {
            salonId = uri.pathSegments.last;
          }
        }

        // Load salon details
        final salon = await _salonService.getSalonById(salonId);
        if (salon != null && mounted) {
          _onSalonSelected(salon);
        } else if (mounted) {
          PopupUtils.showErrorNotification(context, 'Salon not found or not available');
        }
      }
    } catch (e) {
      if (mounted) {
        PopupUtils.showErrorNotification(context, 'Failed to scan QR: $e');
      }
    }
  }

  void _onSalonSelected(Map<String, dynamic> salon) async {
    if (_authService.isLoggedIn && _authService.customerName.isNotEmpty) {
      await _authService.connectSalon(salon);
      final salonId = (salon['id'] ?? '').toString();
      if (mounted) {
        setState(() {
          _selectedServiceIndices.clear();
          _loadedSubscriptionForSalonId = ''; // force reload for new salon
        });
        if (salonId.isNotEmpty) _loadSubscriptionData(salonId);
      }
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
    final saved = _authService.savedSalons;
    final currentId = (_authService.connectedSalon?['id'] ?? '').toString();

    PopupUtils.showCustomModal(
      context,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Connected Shops',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Switch between your regular salons or connect a new one',
              style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 13),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _authService.disconnectSalon();
                  _selectedServiceIndices.clear();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162B16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00FF00), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan / Connect Another Shop',
                        style: TextStyle(color: Color(0xFF00FF00), fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.add_rounded, color: Color(0xFF00FF00), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Saved Salons',
              style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: saved.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No saved salons yet', style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: saved.length,
                      itemBuilder: (ctx, index) {
                        final s = saved[index];
                        final sId = (s['id'] ?? '').toString();
                        final sName = (s['salonName'] ?? 'Salon').toString();
                        final sAddr = (s['address'] ?? s['location'] ?? 'Surat').toString();
                        final isCurrent = sId == currentId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF1E1E1E) : const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF00FF00) : const Color(0xFF262626),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                sName.isNotEmpty ? sName[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(sName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF00),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('ACTIVE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(sAddr, style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12)),
                            ),
                            trailing: isCurrent
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF00), size: 20)
                                : const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF666666), size: 16),
                            onTap: () async {
                              await _authService.switchActiveSalon(s);
                              final switchedId = (s['id'] ?? '').toString();
                              if (mounted) {
                                Navigator.of(context).pop();
                                setState(() {
                                  _selectedServiceIndices.clear();
                                  _loadedSubscriptionForSalonId = '';
                                });
                                if (switchedId.isNotEmpty) _loadSubscriptionData(switchedId);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLogout() async {
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Logout Account?',
      message: 'This will clear your local session cache and log you out.',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirmed) {
      await _authService.logout();
      if (mounted) {
        setState(() {
          _selectedServiceIndices.clear();
        });
      }
    }
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
    final salonName = (salon['salonName'] ?? 'Salon').toString();
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
                  border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.4)),
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
                border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.5), width: 1.2),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Builder(
              builder: (context) {
                final isVip = _subscriptionStatus['hasActivePlan'] == true;
                final plansEnabled = _subscriptionStatus['plansEnabled'] != false;

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
                                        color: const Color(0xFF00FF00).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.25)),
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
                          if (!plansEnabled)
                            const SizedBox.shrink()
                          else if (_isLoadingSubscription)
                            const Center(child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(color: Color(0xFF00FF00), strokeWidth: 2),
                            ))
                          else if (!isVip)
                            _buildUnsubscribedVipCard(salonId, salonName)
                          else
                            _buildActiveVipCard(salonName, _subscriptionStatus),

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
      ),
    );
  }

  Widget _buildUnsubscribedVipCard(String salonId, String salonName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111A11),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.15),
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

          if (_plans.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No subscription plans available yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: List.generate(_plans.length, (index) {
                final plan = _plans[index];
                final isSelected = _selectedPlanIndex == index;
                final durationMonths = plan['durationMonths'] as int? ?? (plan['duration'] as int? ?? 1);
                final pricePaise = plan['pricePaise'] as int? ?? ((plan['price'] as num?)?.toInt() ?? 0);
                final priceRupees = (pricePaise / 100).toStringAsFixed(0);
                final perMonth = durationMonths > 0
                    ? '₹${(pricePaise / 100 / durationMonths).toStringAsFixed(0)}/mo'
                    : '';

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < _plans.length - 1 ? 8 : 0),
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
                              '$durationMonths Mo',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹$priceRupees',
                              style: TextStyle(
                                color: isSelected ? Colors.black : const Color(0xFF00FF00),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              perMonth,
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
                    : Builder(builder: (_) {
                        final plan = _plans[_selectedPlanIndex];
                        final pricePaise = plan['pricePaise'] as int? ?? ((plan['price'] as num?)?.toInt() ?? 0);
                        final priceRupees = (pricePaise / 100).toStringAsFixed(0);
                        final durationMonths = plan['durationMonths'] as int? ?? (plan['duration'] as int? ?? 1);
                        return Text('Join VIP for ₹$priceRupees ($durationMonths Months)');
                      }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveVipCard(String salonName, Map<String, dynamic> membership) {
    final planName = (membership['planName'] ?? membership['name'] ?? 'VIP Pass').toString();
    final expiresAtRaw = membership['expiresAt']?.toString() ?? '';
    String expiryDisplay = 'Active';
    if (expiresAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(expiresAtRaw);
        expiryDisplay = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        expiryDisplay = expiresAtRaw;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162B16), Color(0xFF0D180D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF00).withValues(alpha: 0.08),
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
    if (!mounted) return;
    if (_plans.isEmpty || _selectedPlanIndex >= _plans.length) return;

    final plan = _plans[_selectedPlanIndex];
    final planId = plan['id']?.toString() ?? '';
    final pricePaise = plan['pricePaise'] as int? ?? ((plan['price'] as num?)?.toInt() ?? 0);
    final priceRupees = (pricePaise / 100).toStringAsFixed(0);
    final durationMonths = plan['durationMonths'] as int? ?? (plan['duration'] as int? ?? 1);
    final planName = plan['name']?.toString() ?? 'VIP Plan';

    setState(() => _isProcessingMembership = true);

    try {
      // Step 1: Create Razorpay order
      final orderData = await _subService.createOrder(
        planId: planId,
        partnerId: salonId,
      );

      if (!mounted) return;
      setState(() => _isProcessingMembership = false);

      final orderId = orderData['orderId']?.toString() ?? '';

      // Step 2: Show payment confirmation dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00FF00), width: 1),
          ),
          title: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan: $planName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text('Amount: ₹$priceRupees', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Duration: $durationMonths month(s)', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF262626)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF00FF00), size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Test mode: tap "Pay Now" to simulate payment',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
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
                Navigator.of(ctx).pop();
                await _simulatePaymentVerification(orderId, planName, durationMonths, salonId, salonName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingMembership = false);
        PopupUtils.showErrorNotification(context, 'Failed to initiate payment: $e');
      }
    }
  }

  Future<void> _simulatePaymentVerification(
    String orderId, String planName, int durationMonths, String salonId, String salonName) async {
    if (!mounted) return;
    setState(() => _isProcessingMembership = true);
    try {
      final verifyResult = await _subService.verifyPayment(
        orderId: orderId,
        paymentId: 'pay_test_${DateTime.now().millisecondsSinceEpoch}',
        signature: 'test_signature_skiplaain',
      );

      if (!mounted) return;
      setState(() => _isProcessingMembership = false);

      final membership = verifyResult['membership'] as Map<String, dynamic>? ?? {};
      final expiresAt = membership['expiresAt']?.toString() ?? '';
      String expiryDisplay = 'Active';
      if (expiresAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(expiresAt);
          expiryDisplay = '${dt.day}/${dt.month}/${dt.year}';
        } catch (_) {}
      }

      // Refresh subscription status
      setState(() => _loadedSubscriptionForSalonId = '');
      await _loadSubscriptionData(salonId);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
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
                  color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00FF00), width: 2),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '$planName Activated!',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'VIP access at $salonName\nValid until $expiryDisplay',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Using VIP Pass', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingMembership = false);
        PopupUtils.showErrorNotification(
          context,
          'Payment simulation: $e\n(Real Razorpay integration requires live keys)',
        );
      }
    }
  }

  // This dialog is now shown inline in _buyMembership method above
  Widget _buildMembershipSuccessDialog({
    required String salonName,
    required Map<String, dynamic> data,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00).withValues(alpha: 0.15),
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
              onPressed: () => Navigator.of(context).pop(),
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
            child: _isLoadingSalons
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
                : Builder(
                    builder: (context) {
                      final salons = _salons;

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
                                      color: _authService.isLoggedIn ? const Color(0xFF00FF00).withValues(alpha: 0.5) : const Color(0xFF262626),
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
    
    PopupUtils.showCustomModal(
      context,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final filteredCities = _popularCities.where((c) {
            if (cityFilter.isEmpty) return true;
            return c.toLowerCase().contains(cityFilter.toLowerCase());
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Your City',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  onChanged: (val) => setModalState(() => cityFilter = val.trim()),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA0A0A0), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      borderSide: const BorderSide(color: Color(0xFF00FF00), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () {
                    if (mounted) {
                      setState(() => _selectedCity = 'Surat');
                    }
                    Navigator.of(modalContext).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162B16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.my_location_rounded, color: Color(0xFF00FF00), size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Use Current Location',
                          style: TextStyle(color: Color(0xFF00FF00), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Available Cities',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      final isSelected = _selectedCity == city;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Icon(
                            Icons.location_city_rounded,
                            color: isSelected ? const Color(0xFF00FF00) : Color(0xFF666666),
                            size: 20,
                          ),
                          title: Text(
                            city,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00FF00) : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: Color(0xFF00FF00), size: 20)
                              : null,
                          onTap: () {
                            if (mounted) {
                              setState(() => _selectedCity = city);
                            }
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
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() => _activeTab = index);
          }
        },
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
                      color: const Color(0xFF00FF00).withValues(alpha: 0.25),
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
          onTap: _onScanQR,
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
              onTap: () {
                if (mounted) {
                  setState(() => _isFlashOn = !_isFlashOn);
                }
              },
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
    return Column(
      children: [
        const SizedBox(height: 6),
        // Search Input with Professional Design
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _searchQuery.isNotEmpty ? const Color(0xFF00FF00).withValues(alpha: 0.3) : const Color(0xFF262626),
            ),
            boxShadow: _searchQuery.isNotEmpty
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF00).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search salons in $_selectedCity...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                        ),
                      ),
                    )
                  : const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),

        // Search Results Counter
        if (_searchQuery.isNotEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${_filteredSalons.length} salon${_filteredSalons.length != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  Text(
                    'in $_selectedCity',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // Search History (when no search query)
        if (_searchQuery.isEmpty && _searchHistory.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Recent Searches',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        if (mounted) {
                          setState(() => _searchHistory.clear());
                        }
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _searchHistory.map((query) {
                    return InkWell(
                      onTap: () => _applySearchHistory(query),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search, color: Colors.white38, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              query,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Empty State
        if (_searchQuery.isEmpty && _searchHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Colors.white38, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover Salons in $_selectedCity',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by name, location, or category',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),

        // No Results State
        if (_searchQuery.isNotEmpty && _filteredSalons.isEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: const Icon(Icons.search_off_rounded, color: Colors.white38, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Salons Found',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'No matches for "$_searchQuery" in $_selectedCity',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF00FF00)),
                  label: const Text(
                    'Clear Search',
                    style: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        // Search Results with Animated Entry
        if (_searchQuery.isNotEmpty && _filteredSalons.isNotEmpty && !_isSearching)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _filteredSalons.length,
              itemBuilder: (context, index) {
                final salon = _filteredSalons[index];
                return _buildSalonCard(salon, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSalonCard(Map<String, dynamic> salon, int index) {
    final name = (salon['salonName'] ?? 'Salon').toString();
    final address = (salon['address'] ?? salon['location'] ?? _selectedCity).toString();
    final category = (salon['category'] ?? 'Unisex').toString();
    final rating = (salon['rating'] ?? 4.5).toString();
    
    // Highlight search match
    final nameMatch = name.toLowerCase().contains(_searchQuery);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: nameMatch ? const Color(0xFF00FF00).withValues(alpha: 0.3) : const Color(0xFF242424),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onSalonSelected(salon),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Salon Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00FF00).withValues(alpha: 0.2),
                          const Color(0xFF00FF00).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Salon Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (nameMatch)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MATCH',
                                  style: TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white38, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF00FF00),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
