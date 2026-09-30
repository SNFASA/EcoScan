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

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // Refined Header Section
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Recent Activity",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "${scans.length} total scans",
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            if (scans.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: scans.length,
                                itemBuilder: (context, index) => _buildHistoryItem(context, scans[index]),
                              ),
                            
                            const SizedBox(height: 40),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No scans recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Text("Start scanning to save the planet!", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ScanModel scan) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(scan.timestamp.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showScanDetails(context, scan),
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: const Icon(Icons.recycling_rounded, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scan.wasteType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "+${scan.pointsEarned} pts", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    Text(
                      scan.category, 
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScanDetails(BuildContext context, ScanModel scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Text(scan.wasteType.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: scan.imageUrl.isNotEmpty 
                ? Image.network(scan.imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 250, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
            ),
            const SizedBox(height: 30),
            _detailRow(Icons.category_outlined, "Category", scan.category),
            _detailRow(Icons.eco_outlined, "CO₂ Saved", "${scan.co2Saved} kg"),
            _detailRow(Icons.verified_outlined, "Confidence", "${(scan.confidenceScore * 100).toInt()}%"),
            _detailRow(Icons.stars_rounded, "Eco Points", "+${scan.pointsEarned}"),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(int points, int scans, double screenWidth, String rank, int count) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
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
                    const Text("Eco Tracking", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text("Scan History", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Current Rank: $rank",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          child: Container(
            width: screenWidth > 600 ? 400 : 340,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15), 
                  blurRadius: 20, 
                  offset: const Offset(0, 10)
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.bolt_rounded, color: Colors.green),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Progress", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      "$count Items Scanned", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ],
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