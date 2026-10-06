import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/partner_service.dart';
import '../../services/booking_service.dart';
import '../../utils/popup_utils.dart';
import 'tabs/home_tab.dart';
import 'tabs/bookings_tab.dart';
import 'tabs/customers_tab.dart';
import 'tabs/profile_tab.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  int _previousBookingCount = 0;
  final BookingService _bookingService = BookingService();
  final PartnerService _partnerService = PartnerService();

  @override
  void initState() {
    super.initState();
    _listenToNewBookings();
  }

  void _listenToNewBookings() {
    final partnerId = _partnerService.currentPartnerId;
    if (partnerId == null || partnerId.isEmpty) return;

    _bookingService.streamPartnerBookings(partnerId).listen((bookings) {
      if (!mounted) return;

      final confirmedBookings = bookings.where((b) => 
        b['status'] == 'confirmed' && b['viewedByPartner'] != true
      ).toList();

      final currentCount = confirmedBookings.length;

      if (currentCount > _previousBookingCount && _previousBookingCount > 0) {
        // New booking arrived!
        final newBooking = confirmedBookings.first;
        final customerName = newBooking['customerName'] ?? 'Customer';
        
        HapticFeedback.mediumImpact();
        PopupUtils.showSuccessNotification(
          context,
          '🎉 New booking from $customerName!',
        );
      }

      _previousBookingCount = currentCount;
    });
  }

  final List<Widget> _tabs = [
    const HomeTab(),
    const BookingsTab(),
    const CustomersTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
          ),
        ),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.black,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF00FF00),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.home),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.calendar_month_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.calendar_month),
                ),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.people_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.people),
                ),
                label: 'Customers',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.person_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.person),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
