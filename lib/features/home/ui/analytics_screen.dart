import 'package:flutter/material.dart';
import 'package:ecoscan/core/constants/app_colors.dart';
import 'package:ecoscan/core/widgets/impact_row.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Impact")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Waste Breakdown",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ImpactRow(label: "Plastic", value: 0.7, color: AppColors.plastic),
            ImpactRow(label: "Paper", value: 0.4, color: AppColors.paper),
            ImpactRow(label: "Glass", value: 0.2, color: AppColors.glass),
            ImpactRow(label: "General", value: 0.1, color: AppColors.general),
            const Spacer(),
            const Card(
              color: AppColors.successCard,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "By recycling correctly, you've saved the equivalent of 3 trees this month! 🌳🌳🌳",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
