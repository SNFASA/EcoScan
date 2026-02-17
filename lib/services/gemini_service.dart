import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(File imageFile) async {
    // Get API key securely
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key not found in .env file');
    }

    // Configure Gemini model with enforced JSON response
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    // Prompt tuned for waste classification (Malaysia context)
    final prompt = TextPart("""
Analyze this image and identify the waste item.
Return a RAW JSON object with these exact fields:
{
  "itemName": "Short name (e.g. Plastic Bottle)",
  "category": "Plastic, Paper, Glass, Metal, Food, or General",
  "binColor": "Blue (Paper), Orange (Plastic/Metal), Brown (Glass), or Black (General)",
  "isRecyclable": true or false,
  "points": 10 if recyclable, 2 if not,
  "funFact": "One short interesting fact about recycling this item."
}
Do not use Markdown. Return only the JSON.
""");

    try {
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      debugPrint('Gemini response: $response');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response text from Gemini');
      }

      // Clean up in case Gemini wraps JSON in ```json fences
      final cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('Gemini error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Safe fallback so the app never crashes
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
