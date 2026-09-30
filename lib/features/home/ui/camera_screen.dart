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

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? controller;
  List<CameraDescription>? _cameras;
  bool isCameraInitialized = false;
  bool isAnalyzing = false;
  bool isFlashOn = false;
  String? _cameraError;

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
        controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await controller!.initialize();
        if (!mounted) return;
        setState(() => isCameraInitialized = true);
      } else if (mounted) {
        setState(() => _cameraError = 'No camera was found on this device.');
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
      if (mounted) {
        setState(() {
          _cameraError =
              'EcoScan could not access the camera. Allow camera permission and try again.';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (controller == null) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
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

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized || isAnalyzing) {
      return;
    }
    setState(() => isAnalyzing = true);

    try {
      final XFile image = await controller!.takePicture();
      final imageBytes = await image.readAsBytes();
      if (imageBytes.lengthInBytes > 10 * 1024 * 1024) {
        throw const WasteAnalysisException(
          'That image is too large. Please move closer and try again.',
        );
      }

      final data = await GeminiService.identifyWaste(
        imageBytes: imageBytes,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      if (!mounted) return;

      final pointsEarned = (data['points'] as num?)?.toInt() ?? 0;
      final category = data['category']?.toString() ?? 'General';
      ref
          .read(pointsServiceProvider.notifier)
          .recordScan(points: pointsEarned, category: category);

      setState(() => isAnalyzing = false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        barrierColor: Colors.black87,
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
        SnackBar(
          content: Text(
            e is WasteAnalysisException
                ? e.message
                : 'The scan failed. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.no_photography_outlined,
                    color: Colors.white,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _cameraError = null);
                      _setupCamera();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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

          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
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
                                  Colors.green.withValues(alpha: 0),
                                  Colors.green,
                                  Colors.green.withValues(alpha: 0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
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

          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_corner(), _corner(angle: 90)],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_corner(angle: 270), _corner(angle: 180)],
                  ),
                ],
              ),
            ),
          ),

          if (isAnalyzing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Identifying Waste...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.black87,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Gallery coming soon!"),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 30,
                        ),
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
