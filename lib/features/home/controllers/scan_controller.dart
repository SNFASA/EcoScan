import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import '../models/scan_model.dart';
import '../repositories/scan_repository.dart';

// The Modern Notifier Provider
final scanControllerProvider = AsyncNotifierProvider<ScanController, ScanModel?>(() {
  return ScanController();
});

class ScanController extends AsyncNotifier<ScanModel?> {
  
  // Replace with your actual Gemini API Key
  final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'YOUR_GEMINI_API_KEY',
  );

  @override
  FutureOr<ScanModel?> build() {
    return null; // Initial state is null (no scan performed yet)
  }

  Future<void> processImage(XFile image) async {
    state = const AsyncLoading();

    try {
      final bytes = await image.readAsBytes();
      
      final prompt = TextPart("""
        Analyze this waste item. Return ONLY a JSON object with:
        {
          "item": "name",
          "category": "plastic/paper/metal/glass/organic/non-recyclable",
          "confidence": 0.95,
          "co2Saved": 0.12,
          "points": 20
        }
      """);

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', bytes)])
      ];

      final response = await _model.generateContent(content);
      final jsonString = response.text?.replaceAll('```json', '').replaceAll('```', '').trim();
      
      if (jsonString != null) {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        
        final scan = ScanModel(
          category: data['category'],
          co2Saved: (data['co2Saved'] as num).toDouble(),
          confidenceScore: (data['confidence'] as num).toDouble(),
          imageUrl: "", // Add Storage upload logic here later
          pointsEarned: data['points'] as int,
          timestamp: Timestamp.now(), // FIXED: Using Timestamp.now()
          wasteType: data['item'],
          weekId: _generateWeekId(),
        );

        // Save to Firestore via Repository
        await ref.read(scanRepositoryProvider).saveScan(scan);
        
        state = AsyncData(scan);
      }
    } catch (e, stack) {
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