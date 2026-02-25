import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/history_controller.dart';
import '../controllers/user_controller.dart';
import '../models/scan_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scanHistoryProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userAsync = ref.watch(userControllerProvider(uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (err, _) => Center(child: Text("User Data Error: $err")),
        data: (user) => historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
          error: (err, _) => Center(child: Text("History Error: $err")),
          data: (scans) {
            final todayCount = ref.read(scanHistoryProvider.notifier).getTodayScanCount(scans);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Updated Header Section with proper parameters
                      _buildHeaderSection(
                        user.ecoPoints, 
                        user.totalScans, 
                        MediaQuery.of(context).size.width, 
                        user.rankTier, 
                        todayCount
                      ),
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Scanning History",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            
                            // The Real-time List
                            if (scans.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: Text("No scans recorded yet.", style: TextStyle(color: Colors.grey))),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: scans.length,
                                itemBuilder: (context, index) => _buildHistoryItem(context, scans[index]),
                              ),
                            
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ScanModel scan) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(scan.timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScanDetails(context, scan),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.history_edu_rounded, color: Colors.green),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan.wasteType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Text("+${scan.pointsEarned} pts", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanDetails(BuildContext context, ScanModel scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(scan.wasteType.toUpperCase(), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: scan.imageUrl.isNotEmpty 
                ? Image.network(scan.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.image)),
            ),
            const SizedBox(height: 20),
            _popupRow("Category", scan.category),
            _popupRow("CO2 Saved", "${scan.co2Saved} kg"),
            _popupRow("Confidence", "${(scan.confidenceScore * 100).toInt()}%"),
          ],
        ),
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(int points, int scans, double screenWidth, String rank, int count) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 🟩 The Green Gradient Header
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withAlpha(25))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withAlpha(13))),

              Padding(
                padding: const EdgeInsets.only(top: 80, left: 30, right: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "History", 
                      style: TextStyle(color: Colors.white70, fontSize: 16)
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Your journey to a greener Earth 🌿", 
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Level: $rank",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ☁️ The Overlapping Floating Card (Stats)
        Positioned(
          bottom: -50,
          child: Container(
            width: screenWidth > 600 ? 500 : 340,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2), 
                  blurRadius: 20, 
                  offset: const Offset(0, 10)
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  "Today's Scans: $count", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}