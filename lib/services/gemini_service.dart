import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(File imageFile) async {
    // 1. Get Key securely
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    if (apiKey.isEmpty) {
      throw Exception("API Key not found in .env file");
    }

    // 2. Setup Model with JSON Enforcement
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', // <--- THE MAGIC LINE 🪄
      ),
    );

    // 3. The Prompt (Tuned for Malaysia)
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

      // 4. Send to Google
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      print("AI Response: ${response.text}"); // Debugging

      // 5. Parse the result
      if (response.text == null) throw Exception("No response from AI");

      // Clean cleanup in case Gemini adds ```json ... ```
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(cleanJson);

    } catch (e) {
      print("Error in GeminiService: $e");
      // Return a default "Error" object so the app doesn't crash
      return {
        "itemName": "Unknown Item",
        "binColor": "Black",
        "isRecyclable": false,
        "funFact": "Could not identify. Please try again.",
        "points": 0
      };
    }
  }
}