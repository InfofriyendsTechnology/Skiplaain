import 'package:flutter/material.dart';
import '../../../services/partner_service.dart';
import '../../../services/booking_service.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final PartnerService _partnerService = PartnerService();
  final BookingService _bookingService = BookingService();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = All, 1 = VIP Members, 2 = Repeat Clients (2+)
  
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    
    try {
      final partnerId = _partnerService.currentPartnerId;
      if (partnerId != null) {
        final customers = await _bookingService.getPartnerCustomers(partnerId);
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalClients = _customers.length;
    final vipCount = _customers.where((c) => c['isVip'] == true).length;
    final repeatCount = _customers.where((c) => (c['totalBookings'] as int? ?? 0) >= 2).length;

    // Apply search and filter
    List<Map<String, dynamic>> filteredList = _customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q) || phone.contains(q);

      if (!matchesSearch) return false;

      if (_selectedFilter == 1) return c['isVip'] == true;
      if (_selectedFilter == 2) return (c['totalBookings'] as int? ?? 0) >= 2;

      return true;
    }).toList();

    // Sort by booking count descending
    filteredList.sort((a, b) => (b['totalBookings'] as int? ?? 0).compareTo(a['totalBookings'] as int? ?? 0));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Customers',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FF00)),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              color: const Color(0xFF00FF00),
              backgroundColor: const Color(0xFF141414),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    Row(
                      children: [
                        _buildStatBox('TOTAL CLIENTS', totalClients.toString(), Icons.people_alt_rounded, const Color(0xFF00FF00)),
                        const SizedBox(width: 10),
                        _buildStatBox('VIP MEMBERS', vipCount.toString(), Icons.workspace_premium_rounded, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox('REPEAT CLIENTS', repeatCount.toString(), Icons.verified_user_rounded, Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search customer name or phone...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00FF00), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),

                    const SizedBox(height: 14),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(0, 'All ($totalClients)'),
                          const SizedBox(width: 8),
                          _buildFilterChip(1, 'VIP Members ($vipCount)'),
                          const SizedBox(width: 8),
                          _buildFilterChip(2, 'Repeat Clients ($repeatCount)'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Customers List
                    if (filteredList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline_rounded, color: Colors.white24, size: 36),
                            SizedBox(height: 10),
                            Text('No Customers Found', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Customers will appear here when they book appointments.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      )
                    else
                      ...filteredList.map((customer) => _buildCustomerCard(customer)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(title, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = (customer['name'] ?? 'Customer').toString();
    final phone = (customer['phone'] ?? '').toString();
    final totalBookings = customer['totalBookings'] as int? ?? 0;
    final lastVisit = (customer['lastVisit'] ?? 'Recently').toString();
    final isVip = customer['isVip'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isVip ? const Color(0xFF00FF00).withValues(alpha: 0.4) : const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVip ? const Color(0xFF00FF00).withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                  border: Border.all(color: isVip ? const Color(0xFF00FF00).withValues(alpha: 0.4) : const Color(0xFF333333)),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: isVip ? const Color(0xFF00FF00) : Colors.white,
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
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('VIP', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(phone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 10),

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
                          '$totalBookings Visits',
                          style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Last: $lastVisit', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
