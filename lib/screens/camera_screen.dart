import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import '../services/gemini_service.dart';
import '../services/points_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? controller;
  List<CameraDescription>? _cameras;
  bool isCameraInitialized = false;
  bool isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        controller = CameraController(_cameras![0], ResolutionPreset.medium);
        await controller!.initialize();
        if (!mounted) return;
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized || isAnalyzing) return;

    setState(() { isAnalyzing = true; });

    try {
      final XFile image = await controller!.takePicture();
      File file = File(image.path);

      // 🧠 AI Analysis
      final data = await GeminiService.identifyWaste(file);

      if (!mounted) return;

      // 🏆 RIVERPOD UPDATE:
      // We use .notifier to access the functions (addPoints)
      final pointsEarned = data['points'] ?? 0;
      ref.read(pointsServiceProvider.notifier).addPoints(pointsEarned);

      setState(() { isAnalyzing = false; });
      _showSmartResult(data);

    } catch (e) {
      debugPrint("Error: $e");
      if (!mounted) return;
      setState(() { isAnalyzing = false; });
    }
  }

  // --- UI LOGIC ---

  Color _getBinColor(String? binColor) {
    switch (binColor?.toLowerCase()) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'brown': return Colors.brown;
      case 'black': return Colors.grey[800]!;
      default: return Colors.green;
    }
  }

  void _showSmartResult(Map<String, dynamic> data) {
    final themeColor = _getBinColor(data['binColor']);
    final funFact = data['funFact'] ?? "Recycling saves energy!";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),

            // Icon
            Icon(Icons.recycling, size: 60, color: themeColor),
            const SizedBox(height: 15),

            // Item Name
            Text(data['itemName'] ?? 'Unknown Item',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // Bin Tag
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
            const SizedBox(height: 20),

            // Fun Fact
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(funFact, style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic))),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Points
            Text("+${data['points']} EcoPoints!", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 20),

            // Button
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
    if (!isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(controller!)),
          // Overlay UI
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
          // Back Button (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  // Switch back to Home Tab (Index 0)
                  // Since we are using IndexedStack in main.dart, we can't easily switch tabs from here
                  // without a GlobalKey or passing a callback.
                  // For now, this just acts as a dummy close if you pushed this screen.
                  // But in your tab setup, you just click the bottom nav.
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}