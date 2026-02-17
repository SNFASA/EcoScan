import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import '../services/points_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH THE STATE (Not the service)
    // "ref.watch" gives us the current 'PointsState' object containing the numbers.
    final pointsState = ref.watch(pointsServiceProvider);

    // 2. Extract the numbers from the state
    final int points = pointsState.totalPoints;
    final int scans = pointsState.totalScans;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Hello, Eco Hero! 👋",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                      SizedBox(height: 5),
                      Text(
                          "You've saved 12.5kg of CO2 this week.",
                          style: TextStyle(color: Colors.white70, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(points, scans),
                  const SizedBox(height: 25),
                  const Text("Daily Goal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildGoalCard(scans),
                  const SizedBox(height: 25),
                  const Text("Quick Tips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildTipTile("Rinse your containers", "Dirty plastic cannot be recycled."),
                  _buildTipTile("Flatten cardboard", "It saves space in the blue bin."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS (UI Logic) ---

  Widget _buildStatCard(int points, int scans) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(points.toString(), "Points", Icons.stars, Colors.amber),
          _statItem(scans.toString(), "Scans", Icons.qr_code_scanner, Colors.green),
          _statItem("Gold", "Rank", Icons.emoji_events, Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildGoalCard(int currentScans) {
    double progress = (currentScans % 5) / 5.0;
    if (progress == 0 && currentScans > 0) progress = 1.0;
    if (progress > 1.0) progress = 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Daily Milestone", style: TextStyle(fontWeight: FontWeight.w600)),
              Text("${(progress * 5).toInt()}/5", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.green[50],
              color: Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5)
          ),
        ],
      ),
    );
  }

  Widget _buildTipTile(String title, String sub) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Colors.green[50], child: const Icon(Icons.lightbulb_outline, color: Colors.green)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
    );
  }
}