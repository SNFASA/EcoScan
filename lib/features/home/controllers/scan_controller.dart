import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  FutureOr<ScanModel?> build() async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
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
      late final Uint8List finalBytes;

      if (kIsWeb) {
        finalBytes = await image.readAsBytes();
      } else {
        finalBytes = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        ) ?? await image.readAsBytes();
      }

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

      final mimeType = image.mimeType ?? 'image/jpeg';
      final content = [Content.multi([prompt, DataPart(mimeType, finalBytes)])];

      // 🌟 SPEED UP: We ONLY wait for Gemini now. No Storage upload!
      final GenerateContentResponse response = await _model.generateContent(content);

      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(response.text ?? "{}");
      final jsonString = match?.group(0) ?? "{}";
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final scan = ScanModel(
        category: data['category'] ?? 'Unknown',
        co2Saved: (data['co2Saved'] as num?)?.toDouble() ?? 0.0,
        confidenceScore: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imageUrl: "", // 🌟 Set to empty string since we aren't saving the photo
        pointsEarned: data['points'] as int? ?? 0,
        timestamp: Timestamp.now(),
        wasteType: data['item'] ?? 'Unknown Item',
        weekId: _generateWeekId(),
      );

      // Instantly update the UI
      state = AsyncData(scan);

      // Save the points/details to Firestore silently
      ref.read(scanRepositoryProvider).saveScan(scan).catchError((e) {
        debugPrint("❌ Firestore Background Error: $e");
      });

    } catch (e, stack) {
      debugPrint("❌ ScanController Error: $e");
      state = AsyncError(e, stack);
    }
  }

  String _generateWeekId() {
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }
}