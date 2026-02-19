import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecoscan/core/widgets/smart_result_modal.dart';
import '../../../services/gemini_service.dart';
import '../../../services/points_service.dart';

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
        controller = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
        await controller!.initialize();
        if (!mounted) return;
        setState(() => isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (controller == null) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint("Flash Error: $e");
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    controller?.setFlashMode(FlashMode.off);
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

      final pointsEarned = data['points'] ?? 0;
      ref.read(pointsServiceProvider.notifier).addPoints(pointsEarned);

      setState(() => isAnalyzing = false);

      // ⚠️ FIXED: Solid White Background & Dark Barrier
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white, // Solid white (Not transparent)
        barrierColor: Colors.black87,  // Darkens the background significantly
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),

          // Focus Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Laser Animation
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
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0),
                                  Colors.green,
                                  Colors.green.withOpacity(0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Corner Guides
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(), _corner(angle: 90)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(angle: 270), _corner(angle: 180)]),
                ],
              ),
            ),
          ),

          // Analyzing Loader
          if (isAnalyzing)
            Container(
              color: Colors.black87, // Darker background for loading
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green, strokeWidth: 5),
                    SizedBox(height: 20),
                    Text(
                      "Identifying Waste...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.black87, // Darker control panel
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Align waste within the frame",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: isFlashOn ? Colors.amber : Colors.white,
                          size: 30,
                        ),
                      ),
                      GestureDetector(
                        onTap: isAnalyzing ? null : _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gallery coming soon!")));
                        },
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                      ),
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
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.green, width: 4),
            left: BorderSide(color: Colors.green, width: 4),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
        ),
      ),
    );
  }
}