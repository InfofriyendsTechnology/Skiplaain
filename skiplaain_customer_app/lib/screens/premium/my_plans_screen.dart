import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_subscription_service.dart';
import '../../utils/error_handler.dart';
import 'plan_selection_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  final ApiSubscriptionService _subService = ApiSubscriptionService();
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final subs = await _subService.getMySubscriptions();
      setState(() {
        _subscriptions = subs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, AppError(message: e.toString()));
      }
    }
  }

  bool _isActive(Map<String, dynamic> sub) {
    final endDate = DateTime.parse(sub['endDate']);
    return DateTime.now().isBefore(endDate);
  }

  void _onRenewPlan(Map<String, dynamic> sub) async {
    final salon = sub['salon'] ?? {};
    final salonId = salon['id']?.toString() ?? salon['salonId']?.toString() ?? '';
    final salonName = salon['salonName']?.toString() ?? salon['name']?.toString() ?? 'Salon';

    if (salonId.isEmpty) {
      ErrorHandler.showError(context, AppError(message: 'Invalid salon information'));
      return;
    }

    // Load plans for this salon directly
    List<Map<String, dynamic>> plans = [];
    try {
      plans = await _subService.getPlansForSalon(salonId);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, AppError(message: 'Failed to load plans: $e'));
      }
      return;
    }

    if (!mounted) return;

    if (plans.isEmpty) {
      ErrorHandler.showError(context, AppError(message: 'No plans available for this salon'));
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanSelectionScreen(
          salonId: salonId,
          salonName: salonName,
          plans: plans,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadSubscriptions(); // Refresh the list
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  int _daysRemaining(String endDateStr) {
    final endDate = DateTime.parse(endDateStr);
    return endDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Subscriptions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF)))
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  color: const Color(0xFF00D1FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = _subscriptions[index];
                      final isActive = _isActive(sub);
                      return _buildPlanCard(sub, isActive);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            'No Active Subscriptions',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse salons to purchase plans',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> sub, bool isActive) {
    final salon = sub['salon'] ?? {};
    final plan = sub['plan'] ?? {};
    final daysLeft = isActive ? _daysRemaining(sub['endDate']) : 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF00D1FF).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'EXPIRED',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF00D1FF) : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive && daysLeft <= 7)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$daysLeft days left',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              salon['salonName'] ?? 'Salon',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan['name'] ?? 'Plan',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade800, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem('Start Date', _formatDate(sub['startDate'])),
                const Spacer(),
                _buildInfoItem('End Date', _formatDate(sub['endDate'])),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('Price Paid', '₹${sub['amountPaid'] ?? 0}'),
            
            // Renew button: expired OR expiring within 7 days
            if (!isActive || (isActive && daysLeft <= 7)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _onRenewPlan(sub),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isActive ? 'Renew Early' : 'Renew Plan',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
