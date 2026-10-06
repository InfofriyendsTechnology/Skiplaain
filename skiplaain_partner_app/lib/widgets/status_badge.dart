import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(compact ? 10 : 16),
        border: Border.all(
          color: config.color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 12 : 14,
            color: config.color,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return _StatusConfig(
          color: const Color(0xFF757575), // Gray
          label: 'Completed',
          icon: Icons.check_circle,
        );
      case 'cancelled':
        return _StatusConfig(
          color: const Color(0xFFF44336), // Red
          label: 'Cancelled',
          icon: Icons.cancel,
        );
      case 'confirmed':
      default:
        return _StatusConfig(
          color: const Color(0xFF00FF00), // Neon Green
          label: 'Confirmed',
          icon: Icons.schedule,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  final IconData icon;

  _StatusConfig({
    required this.color,
    required this.label,
    required this.icon,
  });
}
