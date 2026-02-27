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
      final Uint8List bytes = await image.readAsBytes();
      final uid = FirebaseAuth.instance.currentUser?.uid;

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

      final content = [Content.multi([prompt, DataPart('image/jpeg', bytes)])];

      // 🚀 SPEED FIX: Run Gemini AND Firebase Storage Upload at the exact same time
      final geminiFuture = _model.generateContent(content);
      final storageFuture = _uploadToStorage(bytes, uid);

      // Wait for both to finish before continuing
      final results = await Future.wait([geminiFuture, storageFuture]);

      // Extract the results
      final GenerateContentResponse response = results[0] as GenerateContentResponse;
      final String downloadUrl = results[1] as String;

      // Safe Regex Parsing
      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(response.text ?? "{}");
      final jsonString = match?.group(0) ?? "{}";

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Create the ScanModel
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

      // Save to Firestore via Repository
      await ref.read(scanRepositoryProvider).saveScan(scan);

      state = AsyncData(scan);

    } catch (e, stack) {
      print("❌ ScanController Error: $e");
      state = AsyncError(e, stack);
    }
  }

  // Helper method to keep the main logic clean
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
      print("❌ Storage Upload Error: $e");
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