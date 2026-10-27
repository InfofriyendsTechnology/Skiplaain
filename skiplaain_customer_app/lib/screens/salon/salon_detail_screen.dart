import 'package:flutter/material.dart';
import '../../services/api_subscription_service.dart';
import '../../utils/popup_utils.dart';
import '../booking/booking_confirmation_screen.dart';
import '../premium/plan_selection_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const SalonDetailScreen({super.key, required this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final ApiSubscriptionService _subService = ApiSubscriptionService();
  final Set<int> _selectedIndices = {};

  // Loaded from API
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic> _subscriptionStatus = {'hasActivePlan': false, 'plansEnabled': false};
  bool _isLoadingSubscription = true;

  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final results = await Future.wait([
        _subService.getPlansForSalon(_salonId),
        _subService.getSubscriptionStatus(_salonId),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<Map<String, dynamic>>;
          _subscriptionStatus = results[1] as Map<String, dynamic>;
          _selectedPlanIndex = _plans.isNotEmpty ? 0 : 0;
          _isLoadingSubscription = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSubscription = false);
    }
  }

  String get _salonId => (widget.salon['id'] ?? 'salon_id').toString();
  String get _salonName => (widget.salon['salonName'] ?? 'Salon').toString();

  List<Map<String, dynamic>> get _services {
    final raw = widget.salon['services'] as List<dynamic>?;
    if (raw == null || raw.isEmpty) {
      return [
        {'name': 'Classic Haircut & Styling', 'price': 150, 'duration': 30, 'durationUnit': 'mins'},
        {'name': 'Beard Shaping & Lineup', 'price': 100, 'duration': 20, 'durationUnit': 'mins'},
        {'name': 'Deep Cleansing Hair Spa', 'price': 400, 'duration': 45, 'durationUnit': 'mins'},
        {'name': 'Charcoal Tan Removal Facial', 'price': 500, 'duration': 40, 'durationUnit': 'mins'},
      ];
    }
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  double get _totalAmount {
    double sum = 0;
    for (var index in _selectedIndices) {
      if (index < _services.length) {
        final price = double.tryParse(_services[index]['price'].toString()) ?? 0;
        sum += price;
      }
    }
    return sum;
  }

  int get _totalDuration {
    int duration = 0;
    for (var index in _selectedIndices) {
      if (index < _services.length) {
        final dur = int.tryParse(_services[index]['duration'].toString()) ?? 30;
        duration += dur;
      }
    }
    return duration;
  }

  void _onBookSlot() async {
    if (_selectedIndices.isEmpty) {
      PopupUtils.showWarning(
        context,
        message: 'Please select at least 1 service to book',
      );
      return;
    }

    // Check subscription status
    final plansEnabled = _subscriptionStatus['plansEnabled'] == true;
    final hasActivePlan = _subscriptionStatus['hasActivePlan'] == true;

    if (plansEnabled && !hasActivePlan) {
      // Subscription required - open plan selection
      await _openPlanSelection();
      return;
    }

    // Continue to booking
    final selectedServiceList = _selectedIndices.map((i) => _services[i]).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          salon: widget.salon,
          selectedServices: selectedServiceList,
          totalAmount: _totalAmount,
          totalDurationMinutes: _totalDuration,
          bookingDate: 'Today',
          displayDate: 'Today',
          timeSlot: 'Next Available (Walk-in)',
        ),
      ),
    );
  }

  Future<void> _openPlanSelection() async {
    if (_plans.isEmpty) {
      PopupUtils.showErrorNotification(context, 'No plans available for this salon');
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanSelectionScreen(
          salonId: _salonId,
          salonName: _salonName,
          plans: _plans,
        ),
      ),
    );

    // If subscription was purchased, reload status and continue
    if (result == true) {
      await _loadSubscriptionData();
      if (mounted) {
        _onBookSlot(); // Retry booking
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = (widget.salon['address'] ?? widget.salon['location'] ?? 'Surat, Gujarat').toString();
    final category = (widget.salon['category'] ?? 'Unisex').toString();
    final openingTime = (widget.salon['openingTime'] ?? '09:00 AM').toString();
    final closingTime = (widget.salon['closingTime'] ?? '09:00 PM').toString();
    final weeklyOff = (widget.salon['weeklyOff'] ?? 'None').toString();
    final rating = (widget.salon['rating'] ?? 5.0).toDouble();

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
        title: Row(
          children: [
            Expanded(
              child: Text(
                _salonName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link_rounded, color: Color(0xFF00FF00), size: 12),
                  SizedBox(width: 3),
                  Text('CONNECTED', style: TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                                        _salonName.isNotEmpty ? _salonName[0].toUpperCase() : 'S',
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
                                                  _salonName,
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

                          // HIGH-END SHOP-SPECIFIC VIP MEMBERSHIP PASS CARD
                          if (!plansEnabled)
                            const SizedBox.shrink()
                          else if (_isLoadingSubscription)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: Color(0xFF00FF00), strokeWidth: 2),
                            ))
                          else if (!isVip)
                            _buildUnsubscribedVipCard()
                          else
                            _buildActiveVipCard(_subscriptionStatus),

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
                                '${_services.length} Available',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Services List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _services.length,
                            itemBuilder: (context, index) {
                              final service = _services[index];
                              final isSelected = _selectedIndices.contains(index);
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
                                          _selectedIndices.remove(index);
                                        } else {
                                          _selectedIndices.add(index);
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
                              '${_selectedIndices.length} items selected',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_totalAmount.toStringAsFixed(0)}',
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
                              onPressed: _selectedIndices.isNotEmpty ? _onBookSlot : null,
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
                                  const Text('Book slot'),
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

  Widget _buildUnsubscribedVipCard() {
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
                  '$_salonName VIP Pass',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Benefits List
          _buildBenefitRow(Icons.bolt_rounded, 'Priority Line Skip at this salon'),
          _buildBenefitRow(Icons.stars_rounded, 'VIP Regular Customer status'),
          _buildBenefitRow(Icons.money_off_csred_rounded, 'Zero platform / convenience fees'),

          const SizedBox(height: 16),

          // Plan Tiers from API
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
                  Text('No subscription plans available for this salon.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          else
          Row(
            children: List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlanIndex == index;
              final durationMonths = plan['durationMonths'] as int? ?? (plan['duration'] as int? ?? 1);
              final pricePaise = plan['pricePaise'] as int? ?? ((plan['price'] as num?)?.toInt() ?? 0);
              final priceRupees = (pricePaise / 100).toStringAsFixed(0);
              final perMonth = durationMonths > 0 ? '₹${(pricePaise / 100 / durationMonths).toStringAsFixed(0)}/mo' : '';

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

          if (_plans.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _openPlanSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              child: Builder(builder: (_) {
                final plan = _plans[_selectedPlanIndex];
                final pricePaise = plan['pricePaise'] as int? ?? ((plan['price'] as num?)?.toInt() ?? 0);
                final priceRupees = (pricePaise / 100).toStringAsFixed(0);
                final durationMonths = plan['durationMonths'] as int? ?? (plan['duration'] as int? ?? 1);
                return Text('Join VIP for ₹$priceRupees ($durationMonths Months)');
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVipCard(Map<String, dynamic> membership) {
    final planName = (membership['planName'] ?? membership['name'] ?? 'VIP Pass').toString();
    // expiresAt comes from /subscriptions/status response
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
                    '$_salonName VIP Pass',
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
}
