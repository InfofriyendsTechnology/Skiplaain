import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_subscription_service.dart';
import '../../config/app_config.dart';
import '../../utils/popup_utils.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String salonId;
  final String salonName;
  final List<Map<String, dynamic>> plans;

  const PlanSelectionScreen({
    super.key,
    required this.salonId,
    required this.salonName,
    required this.plans,
  });

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> with WidgetsBindingObserver {
  final ApiSubscriptionService _subService = ApiSubscriptionService();
  late Razorpay _razorpay;
  
  int _selectedPlanIndex = 0;
  bool _isProcessing = false;
  String? _pendingOrderId;
  bool _isPaymentInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPaymentInProgress) {
      // User returned to app after payment
      // Check if payment succeeded by checking subscription status
      _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_pendingOrderId == null) return;

    setState(() => _isProcessing = true);

    try {
      final status = await _subService.getSubscriptionStatus(widget.salonId);
      final hasActivePlan = status['hasActivePlan'] as bool? ?? false;

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isPaymentInProgress = false;
      });

      if (hasActivePlan) {
        PopupUtils.showSuccessNotification(context, 'VIP subscription activated!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isPaymentInProgress = false);

    if (_pendingOrderId == null) {
      PopupUtils.showErrorNotification(context, 'Payment verification failed: missing order ID');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _subService.verifyPayment(
        orderId: _pendingOrderId!,
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);
      
      PopupUtils.showSuccessNotification(
        context,
        'VIP subscription activated successfully!',
      );

      // Return success to caller
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      PopupUtils.showErrorNotification(context, 'Payment verification failed: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPaymentInProgress = false);
    
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      PopupUtils.showWarning(context, message: 'Payment cancelled');
    } else {
      PopupUtils.showErrorNotification(
        context,
        'Payment failed: ${response.message ?? "Unknown error"}',
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPaymentInProgress = false);
    PopupUtils.showWarning(context, message: 'External wallet: ${response.walletName}');
  }

  Future<void> _onPayNow() async {
    if (_isProcessing || _isPaymentInProgress) return;

    if (widget.plans.isEmpty || _selectedPlanIndex >= widget.plans.length) {
      PopupUtils.showErrorNotification(context, 'Please select a plan');
      return;
    }

    final plan = widget.plans[_selectedPlanIndex];
    final planId = plan['id']?.toString() ?? '';

    setState(() => _isProcessing = true);

    try {
      // Create order
      final orderData = await _subService.createOrder(
        planId: planId,
        partnerId: widget.salonId,
      );

      if (!mounted) return;

      final orderId = orderData['orderId']?.toString() ?? '';
      final amountPaise = orderData['amount'] as int? ?? 0;

      _pendingOrderId = orderId;

      setState(() {
        _isProcessing = false;
        _isPaymentInProgress = true;
      });

      // Open Razorpay checkout
      var options = {
        'key': AppConfig.razorpayKeyId,
        'amount': amountPaise,
        'currency': 'INR',
        'name': 'Skiplaain',
        'description': 'VIP Subscription - ${widget.salonName}',
        'order_id': orderId,
        'prefill': {
          'name': '',
          'contact': '',
        },
        'theme': {
          'color': '#00ff00',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      PopupUtils.showErrorNotification(context, 'Failed to initiate payment: $e');
    }
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
          onPressed: _isPaymentInProgress ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Choose VIP Plan',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Salon info
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00FF00), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.salonName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'VIP Membership Plans',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Plans
                      if (widget.plans.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF262626)),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    size: 48,
                                    color: Colors.white38,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No Plans Available',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This salon has not set up subscription plans yet.',
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF141414),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFF262626)),
                                    ),
                                  ),
                                  child: const Text('Go Back'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...widget.plans.asMap().entries.map((entry) {
                          final index = entry.key;
                          final plan = entry.value;
                          final isSelected = index == _selectedPlanIndex;

                          final name = plan['name']?.toString() ?? 'VIP Plan';
                          final pricePaise = plan['pricePaise'] as int? ?? 0;
                          final priceRupees = (pricePaise / 100).toStringAsFixed(0);
                          final durationMonths = plan['durationMonths'] as int? ?? 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => setState(() => _selectedPlanIndex = index),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00FF00).withValues(alpha: 0.08)
                                      : const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00FF00)
                                        : const Color(0xFF262626),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF00FF00)
                                              : const Color(0xFF404040),
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF00FF00)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.black,
                                              size: 14,
                                            )
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
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Valid for $durationMonths ${durationMonths == 1 ? "month" : "months"}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹$priceRupees',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF00FF00) : Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Benefits
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VIP Benefits',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            _BenefitRow(
                              icon: Icons.bolt_rounded,
                              text: 'Skip the queue with priority access',
                            ),
                            SizedBox(height: 8),
                            _BenefitRow(
                              icon: Icons.access_time_rounded,
                              text: 'Book appointments anytime',
                            ),
                            SizedBox(height: 8),
                            _BenefitRow(
                              icon: Icons.star_rounded,
                              text: 'Exclusive member perks',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment info
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Secure payment powered by Razorpay',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(
                    top: BorderSide(color: Color(0xFF262626)),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || _isPaymentInProgress || widget.plans.isEmpty)
                          ? null
                          : _onPayNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF262626),
                        disabledForegroundColor: Colors.white38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : _isPaymentInProgress
                              ? const Text(
                                  'Processing payment...',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                )
                              : const Text(
                                  'Pay Now',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00FF00), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
