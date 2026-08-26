import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../appointment_details_screen.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = All, 1 = VIP Members, 2 = Repeat Clients (2+)

  String get _currentPartnerId => _auth.currentUser?.uid ?? '';
  String get _currentPartnerPhone => _auth.currentUser?.phoneNumber ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerDetailModal(BuildContext context, Map<String, dynamic> client, List<Map<String, dynamic>> allBookings) {
    final clientPhone = (client['phone'] ?? '').toString();
    final clientName = (client['name'] ?? 'Client').toString();
    final visitCount = client['visitCount'] as int? ?? 1;
    final totalSpent = (client['totalSpent'] as double? ?? 0).toStringAsFixed(0);
    final isVip = client['isVip'] as bool? ?? false;
    final vipPlan = (client['vipPlan'] ?? '').toString();
    final vipExpiry = (client['vipExpiry'] ?? '').toString();

    final clientBookings = allBookings.where((b) {
      final bPhone = (b['customerPhone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final cCleanPhone = clientPhone.replaceAll(RegExp(r'\D'), '');
      return bPhone.isNotEmpty && (bPhone.contains(cCleanPhone) || cCleanPhone.contains(bPhone));
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF262626), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),

            // Customer Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isVip ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E1E1E),
                    border: Border.all(color: isVip ? const Color(0xFF00FF00) : const Color(0xFF333333)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: isVip ? const Color(0xFF00FF00) : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              clientName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVip) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF00),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('VIP MEMBER', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(clientPhone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Summary Stats Pills
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('$visitCount Visits', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      const Text('Total Visits', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFF333333)),
                  Column(
                    children: [
                      Text('₹$totalSpent', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      const Text('Total Spent', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFF333333)),
                  Column(
                    children: [
                      Text(isVip ? 'VIP PASS' : 'Regular', style: TextStyle(color: isVip ? const Color(0xFF00FF00) : Colors.white70, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Membership', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            if (isVip) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF162B16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$vipPlan active until $vipExpiry',
                        style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Visit & Queue History',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: clientBookings.isEmpty
                  ? const Center(child: Text('No past appointments recorded', style: TextStyle(color: Colors.white38, fontSize: 12)))
                  : ListView.builder(
                      itemCount: clientBookings.length,
                      itemBuilder: (context, idx) {
                        final b = clientBookings[idx];
                        final sName = (b['service'] ?? 'Haircut').toString();
                        final date = (b['bookingDate'] ?? 'Today').toString();
                        final time = (b['timeSlot'] ?? b['time'] ?? 'Walk-in').toString();
                        final price = (b['price'] ?? '₹${b['totalAmount'] ?? 0}').toString();
                        final bId = (b['bookingId'] ?? b['id'] ?? '#SKP').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('$date • $time ($bId)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                              Text(price, style: const TextStyle(color: Color(0xFF00FF00), fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Customers & Visits',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, bookingsSnapshot) {
          final allBookingsDocs = bookingsSnapshot.data?.docs ?? [];
          final List<Map<String, dynamic>> allBookings = allBookingsDocs.map((d) => {'id': d.id, ...d.data()}).toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('memberships').snapshots(),
            builder: (context, membershipsSnapshot) {
              final allMembershipsDocs = membershipsSnapshot.data?.docs ?? [];
              final List<Map<String, dynamic>> allMemberships = allMembershipsDocs.map((d) => {'id': d.id, ...d.data()}).toList();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection('customers').snapshots(),
                builder: (context, customersSnapshot) {
                  final allCustomerDocs = customersSnapshot.data?.docs ?? [];
                  final List<Map<String, dynamic>> cloudCustomers = allCustomerDocs.map((d) => {'id': d.id, ...d.data()}).toList();

                  // Aggregate client statistics for this salon
                  final Map<String, Map<String, dynamic>> clientMap = {};

                  // 1. Ingest customers from customers collection
                  for (var c in cloudCustomers) {
                    final phone = (c['phone'] ?? c['id'] ?? '').toString();
                    final name = (c['name'] ?? 'Client').toString();
                    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                    if (cleanPhone.isNotEmpty) {
                      clientMap[cleanPhone] = {
                        'phone': phone,
                        'name': name,
                        'visitCount': 0,
                        'totalSpent': 0.0,
                        'lastVisit': 'Recently',
                        'isVip': false,
                        'vipPlan': '',
                        'vipExpiry': '',
                      };
                    }
                  }

                  // 2. Ingest bookings to update visit count & total spent
                  for (var b in allBookings) {
                    final rawPhone = (b['customerPhone'] ?? '').toString();
                    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
                    final name = (b['customerName'] ?? 'Client').toString();
                    final price = double.tryParse(b['totalAmount']?.toString() ?? '') ?? 0;
                    final bDate = (b['bookingDate'] ?? 'Today').toString();

                    if (cleanPhone.isNotEmpty) {
                      if (!clientMap.containsKey(cleanPhone)) {
                        clientMap[cleanPhone] = {
                          'phone': rawPhone.isNotEmpty ? rawPhone : cleanPhone,
                          'name': name,
                          'visitCount': 1,
                          'totalSpent': price,
                          'lastVisit': bDate,
                          'isVip': false,
                          'vipPlan': '',
                          'vipExpiry': '',
                        };
                      } else {
                        clientMap[cleanPhone]!['visitCount'] = (clientMap[cleanPhone]!['visitCount'] as int) + 1;
                        clientMap[cleanPhone]!['totalSpent'] = (clientMap[cleanPhone]!['totalSpent'] as double) + price;
                        clientMap[cleanPhone]!['lastVisit'] = bDate;
                        if ((clientMap[cleanPhone]!['name'] == 'Client' || clientMap[cleanPhone]!['name'] == '') && name.isNotEmpty) {
                          clientMap[cleanPhone]!['name'] = name;
                        }
                      }
                    }
                  }

                  // 3. Ingest VIP memberships
                  for (var m in allMemberships) {
                    final rawPhone = (m['customerPhone'] ?? '').toString();
                    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
                    final isAct = (m['status'] ?? 'active') == 'active';
                    final plan = (m['planName'] ?? 'VIP Pass').toString();
                    final exp = (m['expiryDisplay'] ?? 'Active').toString();

                    if (cleanPhone.isNotEmpty && isAct && clientMap.containsKey(cleanPhone)) {
                      clientMap[cleanPhone]!['isVip'] = true;
                      clientMap[cleanPhone]!['vipPlan'] = plan;
                      clientMap[cleanPhone]!['vipExpiry'] = exp;
                    }
                  }

                  final List<Map<String, dynamic>> clientsList = clientMap.values.toList();

                  // Compute Counters
                  final totalClients = clientsList.length;
                  final totalVisits = allBookings.length;
                  final vipCount = clientsList.where((c) => c['isVip'] == true).length;
                  final repeatCount = clientsList.where((c) => (c['visitCount'] as int? ?? 0) >= 2).length;

                  // Apply search and filter
                  List<Map<String, dynamic>> filteredList = clientsList.where((c) {
                    final name = (c['name'] ?? '').toString().toLowerCase();
                    final phone = (c['phone'] ?? '').toString().toLowerCase();
                    final q = _searchQuery.toLowerCase();
                    final matchesSearch = q.isEmpty || name.contains(q) || phone.contains(q);

                    if (!matchesSearch) return false;

                    if (_selectedFilter == 1) return c['isVip'] == true;
                    if (_selectedFilter == 2) return (c['visitCount'] as int? ?? 0) >= 2;

                    return true;
                  }).toList();

                  // Sort by visit count descending
                  filteredList.sort((a, b) => (b['visitCount'] as int? ?? 0).compareTo(a['visitCount'] as int? ?? 0));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 4 TOP STATS GRID
                        Row(
                          children: [
                            _buildStatBox('TOTAL CLIENTS', totalClients.toString(), Icons.people_alt_rounded, const Color(0xFF00FF00)),
                            const SizedBox(width: 10),
                            _buildStatBox('TOTAL VISITS', totalVisits.toString(), Icons.repeat_rounded, Colors.blueAccent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStatBox('VIP MEMBERS', vipCount.toString(), Icons.workspace_premium_rounded, Colors.amber),
                            const SizedBox(width: 10),
                            _buildStatBox('REPEAT CLIENTS (2+)', repeatCount.toString(), Icons.verified_user_rounded, Colors.purpleAccent),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // SEARCH BAR
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

                        // FILTER CHIPS
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

                        // CUSTOMERS DIRECTORY LIST
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
                                Text('Customers will appear here when they scan your salon QR or book a token pass.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          )
                        else
                          ...filteredList.map((client) => _buildClientCard(client, allBookings)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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
                color: color.withOpacity(0.12),
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

  Widget _buildClientCard(Map<String, dynamic> client, List<Map<String, dynamic>> allBookings) {
    final name = (client['name'] ?? 'Client').toString();
    final phone = (client['phone'] ?? '').toString();
    final visitCount = client['visitCount'] as int? ?? 1;
    final totalSpent = (client['totalSpent'] as double? ?? 0).toStringAsFixed(0);
    final lastVisit = (client['lastVisit'] ?? 'Recently').toString();
    final isVip = client['isVip'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isVip ? const Color(0xFF00FF00).withOpacity(0.4) : const Color(0xFF262626)),
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
                  color: isVip ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E1E1E),
                  border: Border.all(color: isVip ? const Color(0xFF00FF00).withOpacity(0.4) : const Color(0xFF333333)),
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
                            child: const Text('VIP PASS', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
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
                          '$visitCount Visits Total',
                          style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('₹$totalSpent Spent', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () => _showCustomerDetailModal(context, client, allBookings),
                child: const Row(
                  children: [
                    Text('History', style: TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00FF00), size: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
