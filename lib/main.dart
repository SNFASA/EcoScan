// start app & attach riverpod
//import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'services/gemini_service.dart'; // 1. Import your new Brain 🧠

import 'app/app.dart';
import 'services/firebase_service.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize(); // Initialize Firebase
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize the app. Please restart or try again later.',
            ),
          ),
        ),
      ),
    );
    return;
  }
  await dotenv.load(fileName: ".env"); // Load secrets
  runApp(
    const ProviderScope(
      child: EcoScanApp(),
    ),
  );
}

/**Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load secrets
  try {
    _cameras = await availableCameras();
  } catch (e) {
    _cameras = [];
  }
  runApp(const EcoScanApp());
}

class EcoScanApp extends StatelessWidget {
  const EcoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool isCameraInitialized = false;
  bool isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (_cameras.isNotEmpty) {
      controller = CameraController(_cameras[0], ResolutionPreset.medium);
      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          isCameraInitialized = true;
        });
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized || isAnalyzing) return;

    // 1. Lock UI
    setState(() { isAnalyzing = true; });

    try {
      final XFile image = await controller!.takePicture();
      File file = File(image.path);

      // 2. 🧠 CALL THE SERVICE (The Clean Way)
      final data = await GeminiService.identifyWaste(file);

      // 3. Unlock UI
      if (!mounted) return;
      setState(() { isAnalyzing = false; });

      // 4. Show the Smart UI
      _showSmartResult(data);

    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() { isAnalyzing = false; });
    }
  }

  // 🎨 HELPER: Get Color based on Malaysian Bin Standards
  Color _getBinColor(String? binColor) {
    switch (binColor?.toLowerCase()) {
      case 'blue': return Colors.blue;      // Paper
      case 'orange': return Colors.orange;  // Plastic/Aluminium
      case 'brown': return Colors.brown;    // Glass
      default: return Colors.black87;       // General/Unknown
    }
  }

  void _showSmartResult(Map<String, dynamic> data) {
    final themeColor = _getBinColor(data['binColor']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),

            // 1. Big Icon
            Icon(Icons.recycling, size: 60, color: themeColor),
            const SizedBox(height: 15),

            // 2. Title
            Text(
              data['itemName'] ?? 'Unknown Item',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // 3. The "Bin Badge"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor, width: 2),
              ),
              child: Text(
                "Use ${data['binColor']} Bin",
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            const SizedBox(height: 25),

            // 4. Fun Fact Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
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

            // 5. Points & Button
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameras.isEmpty) return const Scaffold(body: Center(child: Text("No Camera Found")));
    if (!isCameraInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Camera
          SizedBox.expand(child: CameraPreview(controller!)),

          // Overlay: Capture Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: isAnalyzing ? null : _takePicture,
              icon: isAnalyzing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.camera_alt, size: 28),
              label: Text(isAnalyzing ? "Analyzing..." : "Identify Waste"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAnalyzing ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
**/