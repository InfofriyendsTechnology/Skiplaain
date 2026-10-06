import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../widgets/status_badge.dart';
import '../../utils/popup_utils.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentData,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  Future<void> _markAsViewed() async {
    final bookingId = widget.appointmentData['bookingId'] ?? widget.appointmentData['id'];
    if (bookingId != null) {
      try {
        await _bookingService.markBookingViewed(bookingId);
      } catch (_) {}
    }
  }

  Future<void> _completeAppointment() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Mark as Complete?',
      message: 'Confirm that service is finished and payment has been collected',
      confirmText: 'Complete',
      cancelText: 'Cancel',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final bookingId = widget.appointmentData['bookingId'] ?? widget.appointmentData['id'];
      await _bookingService.completeBooking(bookingId);

      if (mounted) {
        HapticFeedback.heavyImpact();
        final amount = widget.appointmentData['price'] ?? '₹0';
        PopupUtils.showSuccessNotification(
          context,
          'Appointment completed! $amount earned',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        PopupUtils.showErrorNotification(
          context,
          'Failed to complete appointment',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelAppointment() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Cancel Appointment?',
      message: 'Customer will be notified about the cancellation',
      confirmText: 'Yes, Cancel',
      cancelText: 'Keep It',
      isDangerous: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final bookingId = widget.appointmentData['bookingId'] ?? widget.appointmentData['id'];
      await _bookingService.cancelBooking(
        bookingId,
        cancelledBy: 'partner',
        reason: 'Cancelled by partner',
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        PopupUtils.showInfoNotification(
          context,
          'Appointment cancelled',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        PopupUtils.showErrorNotification(
          context,
          'Failed to cancel appointment',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.appointmentData['bookingId'] ?? widget.appointmentData['id'];
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : widget.appointmentData;

        final customerName = data['customerName'] ?? 'Unknown Customer';
        final customerPhone = data['customerPhone'] ?? '';
        final service = data['service'] ?? 'Unknown Service';
        final timeSlot = data['timeSlot'] ?? data['time'] ?? 'Unknown Time';
        final bookingDate = data['bookingDate'] ?? '';
        final price = data['price'] ?? '₹0';
        final status = data['status'] ?? 'confirmed';
        final barberName = data['barberName'] ?? 'Any Available Barber';
        final services = data['services'] as List<dynamic>? ?? [];
        final specialInstructions = data['specialInstructions'] ?? '';

        final isCompleted = status == 'completed';
        final isCancelled = status == 'cancelled';
        final canTakeAction = !isCompleted && !isCancelled;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Appointment Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge (Top)
                    Center(
                      child: StatusBadge(status: status),
                    ),
                    const SizedBox(height: 24),

                    // Customer Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF141414),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00FF00), Color(0xFF00CC00)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FF00).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          color: Color(0xFF00FF00),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          customerPhone,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (customerPhone.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Implement call functionality
                                  HapticFeedback.lightImpact();
                                },
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text('Call Customer'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00FF00),
                                  side: const BorderSide(
                                    color: Color(0xFF00FF00),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Booking Information
                    _buildSectionTitle('Booking Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date',
                        bookingDate,
                      ),
                      _buildInfoRow(
                        Icons.access_time,
                        'Time Slot',
                        timeSlot,
                      ),
                      _buildInfoRow(
                        Icons.person_pin_circle,
                        'Assigned To',
                        barberName,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Services
                    _buildSectionTitle('Services'),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      if (services.isNotEmpty)
                        ...services.asMap().entries.map((entry) {
                          final service = entry.value;
                          final isLast = entry.key == services.length - 1;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service['name'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${service['price'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLast)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(color: Color(0xFF2A2A2A)),
                                ),
                            ],
                          );
                        }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFF2A2A2A), thickness: 2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    if (specialInstructions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Special Instructions'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        Text(
                          specialInstructions,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 32),

                    // Action Buttons
                    if (canTakeAction)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing ? null : _cancelAppointment,
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                disabledForegroundColor: Colors.red.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: _isProcessing
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.red,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _completeAppointment,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle, size: 20),
                              label: Text(_isProcessing ? 'Processing...' : 'Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF00),
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: const Color(0xFF00FF00).withOpacity(0.3),
                                disabledForegroundColor: Colors.black.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 4,
                                shadowColor: const Color(0xFF00FF00).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
