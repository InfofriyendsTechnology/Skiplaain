import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../widgets/status_badge.dart';
import '../../utils/popup_utils.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  bool _isCancelling = false;

  Future<void> _cancelBooking() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await PopupUtils.showConfirmation(
      context,
      title: 'Cancel Appointment?',
      message: 'Are you sure you want to cancel this booking?',
      confirmText: 'Yes, Cancel',
      cancelText: 'Keep It',
      isDangerous: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      final bookingId = widget.bookingData['bookingId'] ?? widget.bookingData['id'];
      await _bookingService.cancelBooking(
        bookingId,
        cancelledBy: 'customer',
        reason: 'Cancelled by customer',
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        PopupUtils.showSuccessNotification(
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
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.bookingData['bookingId'] ?? widget.bookingData['id'];
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : widget.bookingData;

        final salonName = data['salonName'] ?? 'Salon';
        final salonAddress = data['salonAddress'] ?? '';
        final salonPhone = data['salonPhone'] ?? '';
        final bookingDate = data['bookingDate'] ?? '';
        final timeSlot = data['timeSlot'] ?? data['time'] ?? '';
        final status = data['status'] ?? 'confirmed';
        final price = data['price'] ?? '₹${data['totalAmount'] ?? 0}';
        final services = data['services'] as List<dynamic>? ?? [];
        final specialInstructions = data['specialInstructions'] ?? '';
        final barberName = data['barberName'] ?? 'Any Available Barber';

        final isConfirmed = status == 'confirmed';
        final isCancelled = status == 'cancelled';
        final isCompleted = status == 'completed';

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
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Appointment Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: StatusBadge(status: status),
                  ),
                  const SizedBox(height: 24),

                  // Salon Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF141414),
                          const Color(0xFF0F0F0F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF262626)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.store,
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
                                    salonName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (salonAddress.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF00FF00),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            salonAddress,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (salonPhone.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement call functionality
                                HapticFeedback.lightImpact();
                              },
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call Salon'),
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

                  // Booking Info
                  _buildSectionTitle('Appointment Details'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      bookingDate,
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
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
                                child: Divider(color: Color(0xFF262626)),
                              ),
                          ],
                        );
                      }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFF262626), thickness: 2),
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

                  // Cancel Button
                  if (isConfirmed)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancelBooking,
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined, size: 20),
                        label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Appointment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          disabledForegroundColor: Colors.red.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: _isCancelling
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
                  const SizedBox(height: 20),
                ],
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
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262626)),
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
