import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart'; // 🔴 Added this
import '../services/gemini_service.dart';
import '../services/points_service.dart'; // 🔴 Added this

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
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
      print("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    // 1. Basic Safety Checks
    if (controller == null || !controller!.value.isInitialized || isAnalyzing) return;

    setState(() { isAnalyzing = true; });

    try {
      // 2. Capture the image
      final XFile image = await controller!.takePicture();
      File file = File(image.path);

      // 3. 🧠 CALL THE AI SERVICE
      final data = await GeminiService.identifyWaste(file);

      if (!mounted) return;

      // 4. Update the Global Points State 🏆
      final pointsEarned = data['points'] ?? 0;
      Provider.of<PointsService>(context, listen: false).addPoints(pointsEarned);

      setState(() { isAnalyzing = false; });

      // 5. Show the Results Popup
      _showSmartResult(data);

    } catch (e) {
      print("Error in scan process: $e");
      if (!mounted) return;
      setState(() { isAnalyzing = false; });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // ... (Keep the _getBinColor and _showSmartResult functions exactly as they were) ...
  Color _getBinColor(String? binColor) {
    switch (binColor?.toLowerCase()) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'brown': return Colors.brown;
      default: return Colors.black87;
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
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Icon(Icons.recycling, size: 60, color: themeColor),
            const SizedBox(height: 15),
            Text(
              data['itemName'] ?? 'Unknown Item',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
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
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
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
    if (!isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(controller!)),
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