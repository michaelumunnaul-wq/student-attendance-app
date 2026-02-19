import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
        ],
        Text(
          value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center),
      ],
    );
  }
}
