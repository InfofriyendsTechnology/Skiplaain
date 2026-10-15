import 'package:flutter/material.dart';
import '../../../services/api_partner_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiPartnerService _apiPartnerService = ApiPartnerService();
  
  bool _isOnline = true;
  bool _isLoading = true;
  Map<String, dynamic>? _partnerData;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final profile = await _apiPartnerService.getPartnerProfile();
      
      if (mounted) {
        setState(() {
          _partnerData = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF00)),
      );
    }

    final salonName = _partnerData?['salonName'] ?? 'My Salon';
    final ownerName = _partnerData?['ownerName'] ?? 'Partner';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF00FF00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                
                // Stats Cards
                Row(
                  children: [
                    _buildStatCard(
                      title: "Today's Revenue",
                      value: "₹0",
                      icon: Icons.currency_rupee_rounded,
                    ),
                    const SizedBox(width: 14),
                    _buildStatCard(
                      title: "Today's Bookings",
                      value: "0",
                      icon: Icons.calendar_month_rounded,
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Upcoming Appointments
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Appointments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '0 Total',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Empty State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Colors.white24, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No Upcoming Appointments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Real-time appointments will appear here when customers book via Skiplaain app.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
