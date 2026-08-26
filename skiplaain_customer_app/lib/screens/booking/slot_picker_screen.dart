import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_confirmation_screen.dart';

class SlotPickerScreen extends StatefulWidget {
  final Map<String, dynamic> salon;
  final List<Map<String, dynamic>> selectedServices;
  final double totalAmount;
  final int totalDurationMinutes;
  final String? customerPhone;

  const SlotPickerScreen({
    super.key,
    required this.salon,
    required this.selectedServices,
    required this.totalAmount,
    required this.totalDurationMinutes,
    this.customerPhone,
  });

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = '10:00 AM';
  Map<String, dynamic>? _selectedBarber; // null = Any Available Barber

  int _selectedMonthIndex = 0;
  List<DateTime> _monthList = [];
  int _allowedHorizonDays = 14;
  String _membershipPlan = 'Standard';
  bool _isLoadingMembership = true;

  final List<String> _morningSlots = ['09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM'];
  final List<String> _afternoonSlots = ['12:00 PM', '12:30 PM', '01:00 PM', '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM'];
  final List<String> _eveningSlots = ['04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM', '06:00 PM', '06:30 PM', '07:00 PM', '07:30 PM'];

  String get _salonId => (widget.salon['id'] ?? widget.salon['uid'] ?? 'partner_test').toString();

  @override
  void initState() {
    super.initState();
    _fetchCustomerMembership();
  }

  void _fetchCustomerMembership() async {
    int horizonDays = 14;
    String planName = 'Standard';

    try {
      final phone = widget.customerPhone;
      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
        final query = await FirebaseFirestore.instance
            .collection('memberships')
            .where('customerPhone', isEqualTo: phone)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final mData = query.docs.first.data();
          final durationMonths = (mData['durationMonths'] ?? 1) as int;
          planName = (mData['planName'] ?? 'VIP Pass').toString();

          if (durationMonths >= 12) {
            horizonDays = 365;
          } else if (durationMonths >= 6) {
            horizonDays = 180;
          } else if (durationMonths >= 3) {
            horizonDays = 90;
          } else {
            horizonDays = 30;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _allowedHorizonDays = horizonDays;
      _membershipPlan = planName;
      _monthList = _generateAllowedMonths(horizonDays);
      _selectedMonthIndex = 0;
      _isLoadingMembership = false;
    });
  }

  List<DateTime> _generateAllowedMonths(int horizonDays) {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: horizonDays));
    final List<DateTime> months = [];

    DateTime current = DateTime(now.year, now.month, 1);
    while (current.isBefore(endDate) || (current.year == endDate.year && current.month == endDate.month)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months.isEmpty ? [DateTime(now.year, now.month, 1)] : months;
  }

  List<DateTime> _getDatesForSelectedMonth(DateTime monthStart) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final maxAllowedDate = today.add(Duration(days: _allowedHorizonDays));

    final List<DateTime> dates = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      if ((date.isAfter(today) || date.isAtSameMomentAs(today)) && (date.isBefore(maxAllowedDate) || date.isAtSameMomentAs(maxAllowedDate))) {
        dates.add(date);
      }
    }
    return dates;
  }

  void _onProceedToConfirmation({required bool isDateBookable}) {
    if (!isDateBookable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an available date when salon staff is on duty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final displayDate = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    final barberName = _selectedBarber != null ? (_selectedBarber!['name'] ?? 'Barber').toString() : 'Any Available Barber';
    final barberId = _selectedBarber != null ? (_selectedBarber!['id'] ?? 'barber').toString() : 'any';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          salon: widget.salon,
          selectedServices: widget.selectedServices,
          totalAmount: widget.totalAmount,
          totalDurationMinutes: widget.totalDurationMinutes,
          bookingDate: formattedDate,
          displayDate: displayDate,
          timeSlot: _selectedSlot,
          barberId: barberId,
          barberName: barberName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthStart = _monthList.isNotEmpty ? _monthList[_selectedMonthIndex] : DateTime.now();
    final currentMonthDates = _getDatesForSelectedMonth(currentMonthStart);

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
          'Select Appointment Slot',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('partners').doc(_salonId).snapshots(),
        builder: (context, salonSnapshot) {
          final salonData = salonSnapshot.data?.data() ?? widget.salon;
          final rawBarbers = salonData['barbers'] as List<dynamic>?;
          final List<Map<String, dynamic>> barbers = (rawBarbers != null && rawBarbers.isNotEmpty)
              ? rawBarbers.map((b) => Map<String, dynamic>.from(b as Map)).toList()
              : [];

          // 1. Determine Weekday and ISO date of Selected Date
          final selectedWeekday = DateFormat('E').format(_selectedDate); // e.g. Mon, Tue
          final selectedWeekdayFull = DateFormat('EEEE').format(_selectedDate); // e.g. Monday
          final selectedDateIso = DateFormat('yyyy-MM-dd').format(_selectedDate);

          // 2. Check Salon Weekly Off
          final salonWeeklyOff = (salonData['weeklyOff'] ?? '').toString().toLowerCase();
          final isSalonWeeklyOff = salonWeeklyOff.contains(selectedWeekdayFull.toLowerCase()) || salonWeeklyOff.contains(selectedWeekday.toLowerCase());

          // 3. Evaluate Date-Specific Availability for Each Barber
          int availableBarbersCount = 0;
          for (var b in barbers) {
            final rawWorkingDays = b['workingDays'] as List<dynamic>?;
            final workingDays = rawWorkingDays != null
                ? rawWorkingDays.map((e) => e.toString()).toList()
                : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final isStaffWorkingToday = workingDays.contains(selectedWeekday);
            final isGloballyAvailable = (b['isAvailable'] ?? true) as bool;

            final rawLeaveDates = b['leaveDates'] as List<dynamic>?;
            final leaveDates = rawLeaveDates != null ? rawLeaveDates.map((e) => e.toString()).toList() : <String>[];
            final isTakingLeaveOnThisDate = leaveDates.contains(selectedDateIso);

            if (!isSalonWeeklyOff && isGloballyAvailable && isStaffWorkingToday && !isTakingLeaveOnThisDate) {
              availableBarbersCount++;
            }
          }

          // If salon has no registered barbers yet, consider open as long as not salon weekly off
          final isDateBookable = barbers.isEmpty ? !isSalonWeeklyOff : (!isSalonWeeklyOff && availableBarbersCount > 0);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SALON & VIP PASS BANNER
                          _buildSalonSummaryCard(),

                          const SizedBox(height: 20),

                          // 2. DYNAMIC MULTI-MONTH CALENDAR SELECTOR
                          _buildCalendarSection(currentMonthDates),

                          const SizedBox(height: 24),

                          // 3. BARBER / STYLIST SELECTION (DATE-SPECIFIC)
                          _buildBarberSelectorSection(
                            barbers: barbers,
                            selectedWeekday: selectedWeekday,
                            selectedWeekdayFull: selectedWeekdayFull,
                            isSalonWeeklyOff: isSalonWeeklyOff,
                            availableCount: availableBarbersCount,
                          ),

                          const SizedBox(height: 24),

                          // 4. TIME SLOTS SELECTION
                          if (isDateBookable)
                            _buildTimeSlotsSection()
                          else
                            _buildClosedDateNotice(selectedWeekdayFull),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // BOTTOM CONFIRMATION BAR
                  _buildBottomBar(isDateBookable: isDateBookable),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalonSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF00FF00), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.salon['salonName'] ?? widget.salon['businessName'] ?? 'Selected Salon',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.salon['address'] ?? widget.salon['location'] ?? 'Salon Location',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 12),

          // Services & Duration row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.content_cut_rounded, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.selectedServices.length} Services Selected',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '~${widget.totalDurationMinutes} Mins Total',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MULTI-MONTH CALENDAR ---
  Widget _buildCalendarSection(List<DateTime> dates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF00FF00), size: 18),
                SizedBox(width: 8),
                Text(
                  'Choose Date',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
              ),
              child: Text(
                '$_allowedHorizonDays Days Horizon',
                style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Month Selector Chips
        if (_monthList.length > 1)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _monthList.length,
              itemBuilder: (context, idx) {
                final m = _monthList[idx];
                final isSelected = _selectedMonthIndex == idx;
                final monthName = DateFormat('MMMM yyyy').format(m);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMonthIndex = idx;
                        final available = _getDatesForSelectedMonth(m);
                        if (available.isNotEmpty) {
                          _selectedDate = available.first;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                        ),
                      ),
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Horizontal Date Strip for Selected Month
        if (dates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: const Center(
              child: Text(
                'No dates available in this month for your pass horizon.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, idx) {
                final date = dates[idx];
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final dayNum = DateFormat('dd').format(date);
                final dayName = DateFormat('E').format(date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNum,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- BARBER / STYLIST SELECTION (DATE-SPECIFIC AVAILABILITY) ---
  Widget _buildBarberSelectorSection({
    required List<Map<String, dynamic>> barbers,
    required String selectedWeekday,
    required String selectedWeekdayFull,
    required bool isSalonWeeklyOff,
    required int availableCount,
  }) {
    final selectedDateStr = DateFormat('dd MMM').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.person_pin_rounded, color: Color(0xFF00FF00), size: 18),
                SizedBox(width: 8),
                Text(
                  'Select Specialist / Barber',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (barbers.isNotEmpty)
              Text(
                '$availableCount of ${barbers.length} On Duty',
                style: TextStyle(
                  color: availableCount > 0 ? const Color(0xFF00FF00) : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Showing staff availability for $selectedWeekdayFull, $selectedDateStr:',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 12),

        // Salon Weekly Off Alert
        if (isSalonWeeklyOff)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Salon is closed on $selectedWeekdayFull (Weekly Off). Please select another date.',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else if (barbers.isNotEmpty && availableCount == 0)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF332200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFFF9900), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All barbers are off on $selectedWeekdayFull ($selectedDateStr). Please pick another date.',
                    style: const TextStyle(color: Color(0xFFFF9900), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

        // 1. "Any Available Barber" Option
        Opacity(
          opacity: (isSalonWeeklyOff || (barbers.isNotEmpty && availableCount == 0)) ? 0.4 : 1.0,
          child: InkWell(
            onTap: (isSalonWeeklyOff || (barbers.isNotEmpty && availableCount == 0))
                ? null
                : () => setState(() => _selectedBarber = null),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _selectedBarber == null ? const Color(0xFF162B16) : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedBarber == null ? const Color(0xFF00FF00) : const Color(0xFF262626),
                  width: _selectedBarber == null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedBarber == null ? const Color(0xFF00FF00) : const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.bolt_rounded,
                      color: _selectedBarber == null ? Colors.black : Colors.white70,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Any Available Barber',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fastest Queue • First available expert will attend to you',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedBarber == null && !isSalonWeeklyOff && (barbers.isEmpty || availableCount > 0))
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF00), size: 20),
                ],
              ),
            ),
          ),
        ),

        // 2. Individual Barbers List (with Date-Specific Schedule Check)
        ...barbers.map((b) {
          final isSelected = _selectedBarber != null && _selectedBarber!['id'] == b['id'];
          final name = (b['name'] ?? 'Barber').toString();

          final rawWorkingDays = b['workingDays'] as List<dynamic>?;
          final workingDays = rawWorkingDays != null
              ? rawWorkingDays.map((e) => e.toString()).toList()
              : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final isStaffWorkingToday = workingDays.contains(selectedWeekday);
          final isGloballyAvailable = (b['isAvailable'] ?? true) as bool;

          final rawLeaveDates = b['leaveDates'] as List<dynamic>?;
          final leaveDates = rawLeaveDates != null ? rawLeaveDates.map((e) => e.toString()).toList() : <String>[];
          final isTakingLeaveOnThisDate = leaveDates.contains(selectedDateIso);

          final bool isAvailableForDate = !isSalonWeeklyOff && isGloballyAvailable && isStaffWorkingToday && !isTakingLeaveOnThisDate;

          String statusLabel = 'ON DUTY';
          Color statusBg = const Color(0xFF162B16);
          Color statusColor = const Color(0xFF00FF00);

          if (isSalonWeeklyOff) {
            statusLabel = 'CLOSED';
            statusBg = Colors.red.withOpacity(0.2);
            statusColor = Colors.red;
          } else if (!isGloballyAvailable) {
            statusLabel = 'ON LEAVE';
            statusBg = Colors.red.withOpacity(0.2);
            statusColor = Colors.red;
          } else if (isTakingLeaveOnThisDate) {
            statusLabel = 'ON LEAVE (${DateFormat('dd MMM').format(_selectedDate).toUpperCase()})';
            statusBg = const Color(0xFF331616);
            statusColor = const Color(0xFFEF4444);
          } else if (!isStaffWorkingToday) {
            statusLabel = 'OFF ON ${selectedWeekday.toUpperCase()}';
            statusBg = const Color(0xFF222222);
            statusColor = Colors.white38;
          }

          return Opacity(
            opacity: isAvailableForDate ? 1.0 : 0.45,
            child: InkWell(
              onTap: isAvailableForDate ? () => setState(() => _selectedBarber = b) : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF162B16) : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailableForDate ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E1E1E),
                        border: Border.all(color: isAvailableForDate ? const Color(0xFF00FF00) : const Color(0xFF333333)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'B',
                        style: TextStyle(
                          color: isAvailableForDate ? const Color(0xFF00FF00) : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected && isAvailableForDate)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF00), size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- CLOSED NOTICE WHEN 0 STAFF OR SALON CLOSED ---
  Widget _buildClosedDateNotice(String weekdayFull) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, color: Colors.white38, size: 36),
          const SizedBox(height: 10),
          Text(
            'Appointments Not Available on $weekdayFull',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please tap another date above on the calendar to see available slots and barbers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- TIME SLOTS ---
  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.access_time_rounded, color: Color(0xFF00FF00), size: 18),
            SizedBox(width: 8),
            Text(
              'Select Time Slot',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildSlotGroup('MORNING', _morningSlots, Icons.wb_sunny_outlined),
        const SizedBox(height: 14),
        _buildSlotGroup('AFTERNOON', _afternoonSlots, Icons.wb_sunny_rounded),
        const SizedBox(height: 14),
        _buildSlotGroup('EVENING', _eveningSlots, Icons.nightlight_round),
      ],
    );
  }

  Widget _buildSlotGroup(String groupTitle, List<String> slots, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white38, size: 13),
            const SizedBox(width: 6),
            Text(
              groupTitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF262626),
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- BOTTOM BAR ---
  Widget _buildBottomBar({required bool isDateBookable}) {
    final barberDisplayName = _selectedBarber != null ? (_selectedBarber!['name'] ?? 'Barber').toString() : 'Any Available Barber';
    final dateDisplay = DateFormat('dd MMM').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF262626))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dateDisplay at $_selectedSlot',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                isDateBookable ? 'Barber: $barberDisplayName' : 'Staff not available on this date',
                style: TextStyle(
                  color: isDateBookable ? const Color(0xFF00FF00) : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: isDateBookable ? () => _onProceedToConfirmation(isDateBookable: true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDateBookable ? const Color(0xFF00FF00) : const Color(0xFF262626),
              foregroundColor: isDateBookable ? Colors.black : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            child: Row(
              children: [
                Text(isDateBookable ? 'Review & Book' : 'Date Unavailable'),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
