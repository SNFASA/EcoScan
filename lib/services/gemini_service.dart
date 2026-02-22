import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(Uint8List imageBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty || apiKey.length < 20) { // Quick check to ensure it's a real key
      debugPrint("❌ ERROR: Invalid API Key!");
      throw Exception('API key not found or invalid');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = TextPart("""
Analyze this image and identify the main waste item.
Return a RAW JSON object with these exact fields:
{
  "itemName": "Short name (e.g. Plastic Bottle)",
  "category": "Plastic, Paper, Glass, Metal, Food, or General",
  "binColor": "Blue, Orange, Brown, or Black",
  "isRecyclable": true or false,
  "points": 10,
  "funFact": "One short interesting fact about recycling this item."
}
""");

    try {
      debugPrint("🚀 Sending image to Gemini 1.5 Flash...");

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      debugPrint('✅ Raw Gemini response: ${response.text}');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response text from Gemini');
      }

      // 🛡️ Bulletproof Regex to grab only the JSON
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