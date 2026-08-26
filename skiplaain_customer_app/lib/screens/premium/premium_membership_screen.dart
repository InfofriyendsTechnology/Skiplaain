import 'package:flutter/material.dart';

class PremiumMembershipScreen extends StatefulWidget {
  const PremiumMembershipScreen({super.key});

  @override
  State<PremiumMembershipScreen> createState() => _PremiumMembershipScreenState();
}

class _PremiumMembershipScreenState extends State<PremiumMembershipScreen> {
  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Annual (Default Best Value)
  bool _isSubscribed = false;

  void _onSubscribe() {
    setState(() => _isSubscribed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00FF00),
        content: Text(
          'Skiplaain Premium Activated! Enjoy ₹0 Platform Charges & Priority Queue Skip!',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Skiplaain Premium',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF162B16), Color(0xFF0F1A0F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'SKIPLAIN VIP CLUB',
                                  style: TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          if (_isSubscribed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF00),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Zero Platform Charges & Priority Queue Skip',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Unlock VIP salon privileges, ₹0 booking fees, and 10% savings on every haircut & grooming appointment.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Benefits List
                const Text(
                  'Premium Member Benefits',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),

                _buildBenefitItem(
                  icon: Icons.money_off_rounded,
                  title: 'Zero Platform / Convenience Charges',
                  subtitle: 'Save ₹19 - ₹29 booking charge on every salon appointment.',
                ),
                _buildBenefitItem(
                  icon: Icons.flash_on_rounded,
                  title: 'Priority Fast-Track Queue Skip',
                  subtitle: 'Jump ahead in line with VIP priority slot confirmation.',
                ),
                _buildBenefitItem(
                  icon: Icons.percent_rounded,
                  title: '10% Flat Salon Cashback',
                  subtitle: 'Direct discount on all grooming, haircuts, and spa treatments.',
                ),
                _buildBenefitItem(
                  icon: Icons.cancel_outlined,
                  title: 'Free Instant Cancellation',
                  subtitle: 'Zero cancellation fee if your plan changes anytime.',
                ),

                const SizedBox(height: 24),

                // Pricing Plans
                const Text(
                  'Select Your Plan',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                // Annual Plan (Recommended)
                _buildPlanCard(
                  index: 1,
                  title: 'Annual VIP Pass',
                  price: '₹299',
                  period: 'per year (₹25/mo)',
                  badge: 'SAVE 75%',
                  isPopular: true,
                ),
                const SizedBox(height: 10),

                // Monthly Plan
                _buildPlanCard(
                  index: 0,
                  title: 'Monthly VIP Pass',
                  price: '₹99',
                  period: 'per month',
                  badge: 'FLEXIBLE',
                  isPopular: false,
                ),

                const SizedBox(height: 28),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF00),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    child: Text(_isSubscribed ? 'Manage VIP Membership' : 'Activate Skiplaain Premium'),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Cancel anytime with 1-click • Instant Activation',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00FF00), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String badge,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedPlanIndex = index),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF162B16) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00FF00) : Colors.white38,
                  width: 1.5,
                ),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 14) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPopular ? const Color(0xFF00FF00).withOpacity(0.2) : const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isPopular ? const Color(0xFF00FF00) : Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    period,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
