import 'package:flutter/foundation.dart'; // 🌟 Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecoscan/core/widgets/smart_result_modal.dart';

import '../controllers/scan_controller.dart';
import '../models/scan_model.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? controller;
  List<CameraDescription>? _cameras;
  bool isCameraInitialized = false;
  bool isAnalyzing = false;
  bool isFlashOn = false;

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {

        // 🌟 SMART CAMERA SELECTION: Try to grab the back camera for mobile web
        CameraDescription? selectedCamera;
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.back) {
            selectedCamera = camera;
            break;
          }
        }
        // Fallback to the first available camera (usually laptop webcam)
        selectedCamera ??= _cameras!.first;

        controller = CameraController(selectedCamera, ResolutionPreset.medium, enableAudio: false);
        await controller!.initialize();

        if (!mounted) return;
        setState(() => isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleFlash() async {
    // Note: Flash mode is often unsupported on Web browsers, so we add a check
    if (controller == null || !controller!.value.isInitialized || kIsWeb) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("Flash Error: $e");
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    controller?.dispose();
    super.dispose();
  }

  // 📸 Works for both Native and Web now!
  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized || isAnalyzing) return;
    setState(() => isAnalyzing = true);

    try {
      final XFile image = await controller!.takePicture();
      await _processWithBackend(image);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _pickFromGallery() async {
    if (isAnalyzing) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => isAnalyzing = true);
        await _processWithBackend(image);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processWithBackend(XFile image) async {
    try {
      await ref.read(scanControllerProvider.notifier).processImage(image);

      if (!mounted) return;
      setState(() => isAnalyzing = false);

      final scanState = ref.read(scanControllerProvider);

      if (scanState.hasError) {
        _handleError(scanState.error);
        return;
      }

      if (scanState.hasValue && scanState.value != null) {
        final ScanModel scan = scanState.value!;

        final modalData = {
          "itemName": scan.wasteType,
          "category": scan.category,
          "binColor": _getBinColor(scan.category),
          "isRecyclable": scan.pointsEarned > 0,
          "points": scan.pointsEarned,
          "funFact": "Confidence: ${(scan.confidenceScore * 100).toInt()}% • CO2 Saved: ${scan.co2Saved}kg",
        };

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          barrierColor: Colors.black87,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          builder: (context) => SmartResultModal(data: modalData),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  String _getBinColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("paper")) return "Blue";
    if (cat.contains("plastic") || cat.contains("metal")) return "Orange";
    if (cat.contains("glass")) return "Brown";
    return "Black";
  }

  void _handleError(dynamic e) {
    debugPrint("Error in scan process: $e");
    if (!mounted) return;
    setState(() => isAnalyzing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || controller == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 📷 1. The Live Camera Feed (Now works on Web!)
          CameraPreview(controller!),

          // 🎨 2. The Overlay Fix
          if (!kIsWeb) ...[
            // Native Devices get the cool "Hole Punch" effect
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                  Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
                ],
              ),
            ),
          ] else ...[
            // Web browsers get a safe, semi-transparent border that doesn't break HTML video
            Container(color: Colors.black.withOpacity(0.3)),
            Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],

          // 🟢 3. The Scanning Laser Animation
          if (!isAnalyzing)
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: _scanController.value * 280,
                          left: 0, right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.green.withValues(alpha: 0), Colors.green, Colors.green.withValues(alpha: 0)]),
                              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // 📐 4. The Corner Brackets
          Center(
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(), _corner(angle: 90)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(angle: 270), _corner(angle: 180)]),
                ],
              ),
            ),
          ),

          // ⏳ 5. Loading State
          if (isAnalyzing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green, strokeWidth: 5),
                    SizedBox(height: 20),
                    Text("Identifying Waste & Saving...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // 🔘 6. Bottom Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Align waste within the frame", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Hide flash on web since it's rarely supported
                      if (!kIsWeb)
                        IconButton(onPressed: _toggleFlash, icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: isFlashOn ? Colors.amber : Colors.white, size: 30))
                      else
                        const SizedBox(width: 48), // Spacer to keep shutter button centered

                      GestureDetector(
                        onTap: isAnalyzing ? null : _takePicture,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: Colors.transparent),
                          child: Center(child: Container(width: 65, height: 65, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                        ),
                      ),
                      IconButton(onPressed: _pickFromGallery, icon: const Icon(Icons.photo_library, color: Colors.white, size: 30)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({double angle = 0}) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(angle / 360),
      child: Container(
        width: 30, height: 30,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.green, width: 4), left: BorderSide(color: Colors.green, width: 4)),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
        ),
      ),
    );
  }
}