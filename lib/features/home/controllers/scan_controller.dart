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
import '../models/user_model.dart';
import '../models/badges_model.dart';
import 'package:ecoscan/services/badge_email_service.dart';


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
            ) ??
            await image.readAsBytes();
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
      final content = [
        Content.multi([prompt, DataPart(mimeType, finalBytes)])
      ];

      final GenerateContentResponse response =
          await _model.generateContent(content);

      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(response.text ?? "{}");
      final jsonString = match?.group(0) ?? "{}";
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 1. Create the scan object
      final scan = ScanModel(
        category: data['category'] ?? 'Unknown',
        co2Saved: (data['co2Saved'] as num?)?.toDouble() ?? 0.0,
        confidenceScore: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imageUrl: "", 
        pointsEarned: data['points'] as int? ?? 0,
        timestamp: Timestamp.now(),
        wasteType: data['item'] ?? 'Unknown Item',
        weekId: _generateWeekId(),
      );

      // 2. Instantly update the UI
      state = AsyncData(scan);

      // 3. Save to Firestore and trigger badge check
      // We do this inside the try block where 'scan' is defined
      ref.read(scanRepositoryProvider).saveScan(scan).then((_) {
        debugPrint("✅ Scan saved successfully. Checking badges...");
        onScanComplete(scan); 
      }).catchError((e) {
        debugPrint("❌ Firestore Background Error: $e");
      });

    } catch (e, stack) {
      debugPrint("❌ ScanController Error: $e");
      state = AsyncError(e, stack);
    }
    // 🌟 MOVED LOGIC: The code that was here causing the 'scan' error 
    // is now safely inside the try block above.
  }

  String _generateWeekId() {
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }
  // Example scan completion logic
Future<void> onScanComplete(ScanModel newScan) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 1. Fetch latest user data and all available badges
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    
    // Pass uid to fromMap as required by your UserModel
    final user = UserModel.fromMap(uid, userDoc.data()!);
    
    final badgeDocs = await FirebaseFirestore.instance.collection('badges').get();
    final allBadges = badgeDocs.docs.map((d) => BadgesModel.fromMap(d.data())).toList();

    // 2. Trigger badge check using the imported service
    BadgeEmailService.checkAndSendBadge(user, allBadges);
  }
}