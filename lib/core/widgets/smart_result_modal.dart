import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart'; // Adjust path for colors

class SmartResultModal extends StatelessWidget {
  final Map<String, dynamic> data;
  const SmartResultModal({super.key, required this.data});

  Color _getBinColor(String? binColor) {
    switch (binColor?.toLowerCase()) {
      case 'blue': return AppColors.paper;
      case 'orange': return AppColors.plastic;
      case 'brown': return AppColors.glass;
      default: return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getBinColor(data['binColor']);

    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          Icon(Icons.recycling, size: 60, color: themeColor),
          const SizedBox(height: 15),
          Text(
            data['itemName'] ?? 'Unknown Item',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor, width: 2),
            ),
            child: Text(
              "Use ${data['binColor']} Bin",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb, size: 18, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text("Did you know?", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 5),
                Text(data['funFact'] ?? 'Recycling saves energy!', style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text("+${data['points']} EcoPoints!", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Scan Next Item", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
