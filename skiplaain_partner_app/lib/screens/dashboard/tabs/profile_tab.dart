import 'package:flutter/material.dart';
import '../../../services/partner_service.dart';
import '../../login_screen.dart';
import '../settings/manage_services_screen.dart';
import '../settings/manage_barbers_screen.dart';
import '../settings/business_hours_screen.dart';
import '../settings/salon_details_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF00FF00), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Text(
              'Profile & Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Profile Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/bird_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Yash Styles Salon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '+91 85535 35342',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildListTile(Icons.design_services, 'Manage Services', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageServicesScreen()),
            );
          }),
          _buildListTile(Icons.people_alt_rounded, 'Manage Barbers & Staff', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageBarbersScreen()),
            );
          }),
          _buildListTile(Icons.access_time_filled, 'Business Hours', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BusinessHoursScreen()),
            );
          }),
          _buildListTile(Icons.location_on, 'Salon Details & Location', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalonDetailsScreen()),
            );
          }),
          _buildListTile(Icons.account_balance_wallet, 'Bank Details', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')));
          }),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF141414),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF262626)),
                      ),
                      title: const Text('Logout Partner Account?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to log out of your salon dashboard?', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await PartnerService().clearPartnerSession();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF262626)),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
