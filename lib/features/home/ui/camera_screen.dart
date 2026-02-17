import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:ecoscan/core/widgets/smart_result_modal.dart';
import '../../../services/gemini_service.dart';
import '../../../services/points_service.dart';

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
        setState(() => isCameraInitialized = true);
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
    setState(() => isAnalyzing = true);

    try {
      final XFile image = await controller!.takePicture();
      File file = File(image.path);

      final data = await GeminiService.identifyWaste(file);

      if (!mounted) return;

      Provider.of<PointsService>(context, listen: false).addPoints(data['points'] ?? 0);
      setState(() => isAnalyzing = false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) => SmartResultModal(data: data),
      );
    } catch (e) {
      debugPrint("Error in scan process: $e");
      if (!mounted) return;
      setState(() => isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt, size: 28),
              label: Text(isAnalyzing ? "Analyzing..." : "Identify Waste"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAnalyzing ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
