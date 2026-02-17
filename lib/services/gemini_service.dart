import 'dart:io';
import 'dart:convert'; // Required for jsonDecode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(File imageFile) async {
    // 1. Get the API Key safely
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    if (apiKey.isEmpty) {
      print("⚠️ ERROR: Gemini API Key is missing in .env file");
      return _fallbackResponse("API Key Missing");
    }

    try {
      // 2. Initialize the AI Model
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // Fast and cheap model
        apiKey: apiKey,
      );

      // 3. Create the Prompt
      final prompt = TextPart("""
        Analyze this image of waste/recycling.
        Return ONLY a valid JSON object. Do not use Markdown formatting (no ```json).
        
        Fields required:
        - itemName: A short, clear name (e.g., 'Plastic Water Bottle', 'Banana Peel').
        - binColor: Choose strictly from: 'Blue' (Paper), 'Orange' (Plastic/Aluminium), 'Brown' (Glass), or 'Black' (General/Food).
        - funFact: A short, interesting fact about recycling this specific item (max 1 sentence).
        - points: Integer value (10 for recyclable items, 1 for non-recyclable/general waste).
      """);

      // 4. Convert Image to Bytes for the API
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      // 5. Send to Gemini 🚀
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String? text = response.text;

      if (text != null && text.isNotEmpty) {
        // CLEANUP: Remove any markdown formatting the AI might add
        final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();

        // PARSE: Convert string to Map
        return jsonDecode(cleanJson);
      }

    } catch (e) {
      print("❌ AI Processing Error: $e");
    }

    // 6. If anything fails, return this safe fallback
    return _fallbackResponse("Could not identify item");
  }

  // Helper method for error cases
  static Map<String, dynamic> _fallbackResponse(String reason) {
    return {
      'itemName': 'Unknown Item',
      'binColor': 'Black',
      'funFact': 'We couldn\'t identify this item. Try scanning again!',
      'points': 0,
      'error': reason
    };
  }
}