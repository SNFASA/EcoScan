import 'package:flutter/material.dart';

class ImpactRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const ImpactRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
