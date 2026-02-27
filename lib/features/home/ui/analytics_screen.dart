import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import 'globalDashboard_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  /// 🌟 Navigation & Tracking Logic
  Future<void> _navigateToGlobalStats(BuildContext context) async {
    // 1. Log the event to Google Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'view_global_stats',
      parameters: {
        'from_screen': 'personal_analytics',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 2. Perform Navigation
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GlobalDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userAsync = ref.watch(userControllerProvider(firebaseUser?.uid ?? ''));
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("User Error: $e")),
        data: (user) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER SECTION
                  _buildHeaderSection(context, user, screenWidth),
                  
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterToggle(ref),
                        const SizedBox(height: 25),
                        const Text(
                          "Waste Breakdown",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        analyticsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => Text("Load Error: $err"),
                          data: (data) => _buildChartList(data),
                        ),

                        const SizedBox(height: 30),
                        _buildMilestoneCard(user.co2Offset, user.nextMilestoneCo2),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, UserModel user, double screenWidth) {
    int trees = (user.co2Offset / 21).floor();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Green Background
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
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withValues(alpha: 0.1))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withValues(alpha: 0.05))),
              
              // 🌟 NEW: Global Navigation Icon
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  onPressed: () => _navigateToGlobalStats(context),
                  icon: const Icon(Icons.public_rounded, color: Colors.white, size: 28),
                ),
              ),

              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text("Your Impact", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text("Total CO2 Offset", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text("${user.co2Offset.toStringAsFixed(1)} kg", 
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Card
        Positioned(
          bottom: -50,
          child: Container(
            width: screenWidth > 600 ? 500 : 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: const Text("🌳", style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Equivalent to", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("$trees Trees Planted", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      const Text("Keep recycling!", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildFilterToggle(WidgetRef ref) {
    final currentFilter = ref.watch(analyticsProvider.notifier).currentFilter;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AnalyticsFilter.values.map((filter) {
        final isSelected = currentFilter == filter;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(filter.name.toUpperCase()),
            selected: isSelected,
            onSelected: (_) => ref.read(analyticsProvider.notifier).changeFilter(filter),
            selectedColor: Colors.green,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartList(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    if (data.isEmpty || total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text("No recycling data found for this period.", 
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
      );
    }
    
    return Column(
      children: data.entries.map((e) {
        return _buildImpactBar(
          e.key, 
          e.value / total, 
          _getCategoryColor(e.key), 
          _getCategoryIcon(e.key),
        );
      }).toList(),
    );
  }

  Widget _buildMilestoneCard(double current, double target) {
    double progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Next Milestone", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  "Save ${target.toInt()}kg CO2",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                color: Colors.white,
                backgroundColor: Colors.white24,
                strokeWidth: 6,
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBar(String label, double percentage, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 15),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Text("${(percentage * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              color: color,
              backgroundColor: Colors.grey[200],
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'plastic': return Colors.orange;
      case 'paper': return Colors.blue;
      case 'glass': return Colors.teal;
      case 'metal': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'plastic': return Icons.local_drink;
      case 'paper': return Icons.newspaper;
      case 'glass': return Icons.wine_bar;
      case 'metal': return Icons.precision_manufacturing;
      default: return Icons.delete_outline;
    }
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}