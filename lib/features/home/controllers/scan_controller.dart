import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/scan_model.dart';
import '../repositories/scan_repository.dart';

final scanControllerProvider = AsyncNotifierProvider<ScanController, ScanModel?>(() {
  return ScanController();
});

class ScanController extends AsyncNotifier<ScanModel?> {
  late final GenerativeModel _model;

  @override
  FutureOr<ScanModel?> build() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Flash models provide the lowest latency
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    return null;
  }

  Future<void> processImage(XFile image) async {
    state = const AsyncLoading();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // 1. 🚀 COMPRESS: Shrink image for faster network transfer
      // This is the #1 speed fix for slow scans
      final Uint8List compressedBytes = await FlutterImageCompress.compressWithFile(
            image.path,
            minWidth: 800, 
            minHeight: 800,
            quality: 70, 
          ) ??
          await image.readAsBytes();

      final prompt = TextPart("""
        Analyze this waste item. Return ONLY a JSON object with:
        {
          "item": "name",
          "category": "Plastic, Paper, Metal, Glass, Organic, or Non-recyclable",
          "confidence": 0.95,
          "co2Saved": 0.12,
          "points": 20
        }
      """);

      final content = [Content.multi([prompt, DataPart('image/jpeg', compressedBytes)])];

      // 2. START ASYNC TASKS: Launch AI and Storage at the same time
      final geminiFuture = _model.generateContent(content);
      final storageFuture = _uploadToStorage(compressedBytes, uid);

      // 3.UI SPEED: Wait only for the AI result first
      // The user doesn't need the Storage URL to see the item name
      final GenerateContentResponse response = await geminiFuture;

      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(response.text ?? "{}");
      final jsonString = match?.group(0) ?? "{}";
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 4.BACKGROUND URL: Finalize the storage upload
      final String downloadUrl = await storageFuture;

      final scan = ScanModel(
        category: data['category'] ?? 'Unknown',
        co2Saved: (data['co2Saved'] as num?)?.toDouble() ?? 0.0,
        confidenceScore: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imageUrl: downloadUrl,
        pointsEarned: data['points'] as int? ?? 0,
        timestamp: Timestamp.now(),
        wasteType: data['item'] ?? 'Unknown Item',
        weekId: _generateWeekId(),
      );

      // 5.FINISH: State updates immediately so the modal pops up in camera_screen.dart
      state = AsyncData(scan);

      // 6.SILENT SAVE: Update database without blocking the UI
      // We don't 'await' this so the user doesn't have to wait for the DB write
      ref.read(scanRepositoryProvider).saveScan(scan).catchError((e) {
        print("❌ Firestore Background Error: $e");
      });

    } catch (e, stack) {
      print("❌ ScanController Error: $e");
      state = AsyncError(e, stack);
    }
  }

  Future<String> _uploadToStorage(Uint8List bytes, String? uid) async {
    if (uid == null) return "";
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('users/$uid/scans/$fileName');

      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("❌ Storage Error: $e");
      return "";
    }
  }

  String _generateWeekId() {
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }
}