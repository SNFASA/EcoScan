import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'scoreboard_screen.dart';
import 'camera_screen.dart';
import 'analytics_screen.dart';
import 'profiles_screen.dart';
import 'history_screen.dart';

// Controller
import '../controllers/user_controller.dart';
import 'package:ecoscan/features/auth/logic/auth_provider.dart'; // Make sure authProvider is imported

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) async {
    // Logout index = 5
    if (index == 6) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(authProvider.notifier).logout();

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onSwitchTab: _onItemTapped),
      const ScoreboardScreen(),
      const CameraScreen(),
      const AnalyticsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Colors.white,
              indicatorColor: Colors.green.withAlpha(51), // ~0.2 opacity
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.emoji_events_rounded), label: 'Ranks'),
                NavigationDestination(icon: Icon(Icons.camera_enhance_rounded), label: 'Scan'),
                NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Impact'),
                NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
                NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: Colors.green),
              indicatorColor: Colors.green.withAlpha(25), // ~0.1 opacity
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Icon(Icons.eco, color: Colors.green, size: 40),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.emoji_events_rounded), label: Text('Ranks')),
                NavigationRailDestination(icon: Icon(Icons.camera_enhance_rounded), label: Text('Scan')),
                NavigationRailDestination(icon: Icon(Icons.insights_rounded), label: Text('Impact')),
                NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Profile')),
              ],
            ),
          if (isDesktop) const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends ConsumerWidget {
  final Function(int) onSwitchTab;

  const DashboardTab({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userAsync = ref.watch(userControllerProvider(uid));

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return userAsync.when(
      data: (user) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F9F5),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderSection(
                      user.ecoPoints,
                      user.totalScans,
                      width,
                      user.rankTier,
                    ),
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildActionGrid(context, isDesktop),
                          const SizedBox(height: 25),
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(child: _buildSection("Daily Impact", _buildDailyGoalCard(user.totalScans))),
                                const SizedBox(width: 25),
                                Expanded(child: _buildSection("Did You Know?", _buildTipCard())),
                              ],
                            )
                          else ...[
                            _buildSection("Daily Impact", _buildDailyGoalCard(user.totalScans)),
                            const SizedBox(height: 25),
                            _buildSection("Did You Know?", _buildTipCard()),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        content,
      ],
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildHeaderSection(int points, int scans, double screenWidth, String rank) {
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
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withAlpha(25))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withAlpha(13))),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 60, left: 25, right: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome Back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                            SizedBox(height: 5),
                            Text("Eco Warrior! 🌿", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                BoxShadow(color: Colors.green.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(points.toString(), "Eco Points", Icons.stars_rounded, Colors.amber),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _statItem(scans.toString(), "Items", Icons.recycling_rounded, Colors.green),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _statItem(rank, "Rank", Icons.emoji_events_rounded, Colors.orange),
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

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        Expanded(child: _actionButton(Icons.qr_code_scanner, "Scan Now", Colors.blue, () => onSwitchTab(2))),
        const SizedBox(width: 15),
        Expanded(child: _actionButton(Icons.history_rounded, "History", Colors.orange, () => onSwitchTab(4))),
        const SizedBox(width: 15),
        Expanded(child: _actionButton(Icons.map_rounded, "Centers", Colors.teal, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maps coming soon!")));
        })),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(25)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(int currentScans) {
    double progress = (currentScans % 5) / 5.0;
    if (progress == 0 && currentScans > 0) progress = 1.0;
    if (progress > 1.0) progress = 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green[50]!, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.withAlpha(25)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: progress, backgroundColor: Colors.green.withAlpha(51), color: Colors.green, strokeWidth: 6),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Daily Recycling Goal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text("Scan 5 items today to get a bonus!", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Recycle Smart!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 5),
                Text("Rinsing plastic bottles increases recycling efficiency by 20%.", style: TextStyle(color: Colors.brown[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
