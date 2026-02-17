import 'package:flutter/material.dart';

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
            const Text("Waste Breakdown", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            // Mocking a simple bar chart
            _impactRow("Plastic", 0.7, Colors.orange),
            _impactRow("Paper", 0.4, Colors.blue),
            _impactRow("Glass", 0.2, Colors.brown),
            _impactRow("General", 0.1, Colors.grey),
            const Spacer(),
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "By recycling correctly, you've saved the equivalent of 3 trees this month! 🌳🌳🌳",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _impactRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 12, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }
}