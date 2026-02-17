import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Ensure these paths match your project folder structure
import 'screens/home_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/camera_screen.dart';
import 'services/points_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try-catch added for safety if .env is missing during debug
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => PointsService(),
      child: const EcoScanApp(),
    ),
  );
}

class EcoScanApp extends StatelessWidget {
  const EcoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green[700]!,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  // List of pages to display in the stack
  final List<Widget> _pages = [
    const HomeScreen(),
    const ScoreboardScreen(),
    const CameraScreen(),
    const AnalyticsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each page when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Ranks',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_enhance_outlined),
            selectedIcon: Icon(Icons.camera_enhance),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Impact',
          ),
        ],
      ),
    );
  }
}