import 'package:flutter/material.dart';

/// Placeholder map view — mapbox_gl removed due to Flutter 3.24 incompatibility.
/// The MapboxService REST API (geocoding/search) still works via http.
class SalonMapView extends StatelessWidget {
  final List<Map<String, dynamic>> salons;
  final Function(Map<String, dynamic> salon)? onSalonTap;

  const SalonMapView({
    super.key,
    required this.salons,
    this.onSalonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Color(0xFF00FF00), size: 32),
            const SizedBox(height: 8),
            Text(
              '${salons.length} salons nearby',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
