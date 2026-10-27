import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_partner_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  final ApiPartnerService _partnerService = ApiPartnerService();
  final _storage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('http://localhost:61026/partner/earnings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _earningsData = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load earnings');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMoney(int paise) {
    final rupees = paise / 100;
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(rupees);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF00)),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEarnings,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF00)),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (_earningsData == null) {
      return const Center(
        child: Text('No earnings data', style: TextStyle(color: Colors.white70)),
      );
    }

    final pendingPaise = _earningsData!['pendingPaise'] ?? 0;
    final includedNotPaidPaise = _earningsData!['includedNotPaidPaise'] ?? 0;
    final lifetimeEarnedPaise = _earningsData!['lifetimeEarnedPaise'] ?? 0;
    final paidTotalPaise = _earningsData!['paidTotalPaise'] ?? 0;
    final nextPayoutDate = _earningsData!['nextPayoutDate'];
    final ledger = _earningsData!['ledgerRows'] as List? ?? [];
    final payoutHistory = _earningsData!['payouts'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadEarnings,
      color: const Color(0xFF00FF00),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCard('Pending Balance', pendingPaise, Colors.orange),
            const SizedBox(height: 12),
            _buildSummaryCard('Included Not Paid', includedNotPaidPaise, Colors.blue),
            const SizedBox(height: 12),
            _buildSummaryCard('Lifetime Earned', lifetimeEarnedPaise, const Color(0xFF00FF00)),
            const SizedBox(height: 12),
            _buildSummaryCard('Total Paid Out', paidTotalPaise, Colors.green),
            
            const SizedBox(height: 24),
            
            // Next Payout Date
            if (nextPayoutDate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF00FF00), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Next Payout: ${_formatDate(nextPayoutDate)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Commission Ledger
            const Text(
              'Commission Ledger',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ledger.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Text('No transactions yet', style: TextStyle(color: Colors.white54)),
              )
            else
              ...ledger.map((item) => _buildLedgerItem(item)),

            const SizedBox(height: 24),

            // Payout History
            const Text(
              'Payout History',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (payoutHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Text('No payouts yet', style: TextStyle(color: Colors.white54)),
              )
            else
              ...payoutHistory.map((payout) => _buildPayoutItem(payout)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int paise, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            _formatMoney(paise),
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(Map<String, dynamic> item) {
    final customerName = item['customerName'] ?? 'Customer';
    final planName = item['planName'] ?? 'Plan';
    final commissionPaise = item['commissionPaise'] ?? 0;
    final earnedAt = item['earnedAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customerName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(planName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                if (earnedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(_formatDate(earnedAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ],
            ),
          ),
          Text(
            _formatMoney(commissionPaise),
            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(Map<String, dynamic> payout) {
    final totalPaise = payout['totalPaise'] ?? 0;
    final status = payout['status'] ?? 'pending';
    final createdAt = payout['createdAt'];
    final paidAt = payout['paidAt'];
    final paymentReference = payout['paymentReference'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMoney(totalPaise),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'paid' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'paid' ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Generated: ${_formatDate(createdAt)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          if (paidAt != null) ...[
            const SizedBox(height: 4),
            Text('Paid: ${_formatDate(paidAt)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
          ],
          if (paymentReference != null) ...[
            const SizedBox(height: 4),
            Text('Ref: $paymentReference', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
