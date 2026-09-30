import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Ensure you call dotenv.load() in main.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(Uint8List imageBytes) async {
    // 🌟 FIX: Securely load the API key from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    if (apiKey.isEmpty || apiKey.length < 20) {
      debugPrint("❌ ERROR: Invalid API Key! Ensure GEMINI_API_KEY is set in your .env file.");
      throw Exception('API key not found or invalid');
    }

    // 🌟 FIX: Corrected model name and forced pure JSON output
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', // 👈 Forces Gemini to return pure JSON, no markdown
      ),
    );

    final prompt = TextPart("""
Analyze this image and identify the main waste item.
Return a JSON object with these exact fields:
{
  "itemName": "Short name (e.g. Plastic Bottle)",
  "category": "Plastic, Paper, Glass, Metal, Food, or General",
  "binColor": "Blue, Orange, Brown, or Black",
  "isRecyclable": true,
  "points": 10,
  "funFact": "One short interesting fact about recycling this item."
}
""");

    try {
      debugPrint("🚀 Sending image to Gemini 1.5 Flash...");

      // Uint8List is perfectly handled here
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      debugPrint('✅ Raw Gemini response: ${response.text}');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response text from Gemini');
      }

      // 🛡️ Even with responseMimeType, keeping Regex is a great bulletproof fallback
      // in case the model wraps the JSON in markdown blocks (```json ... ```)
      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(response.text!);

      if (match != null) {
        final cleanJson = match.group(0)!;
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } else {
        throw Exception('Could not find JSON in response');
      }

    } catch (e) {
      debugPrint('❌ Gemini error: $e');

      // Graceful fallback so the UI doesn't crash
      return {
        "itemName": "Unknown Item",
        "category": "General",
        "binColor": "Black",
        "isRecyclable": false,
        "points": 0,
        "funFact": "Could not identify the item. Please try again.",
      };
    }
  }
}