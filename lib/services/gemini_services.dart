import 'dart:io';
import 'dart:convert'; // Needed for JSON decoding
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> identifyWaste(File imageFile) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    if (apiKey.isEmpty) {
      print("⚠️ API Key is missing!");
      return {
        'itemName': 'Error',
        'binColor': 'Black',
        'funFact': 'API Key is missing in .env file!',
        'points': 0
      };
    }

    // Initialize the AI Model
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    // The Prompt
    final prompt = TextPart("""
      Identify this waste item from the image.
      Return ONLY a raw JSON object (no markdown, no ```json wrapper).
      
      Required Fields:
      - itemName: Short name (e.g., 'Plastic Bottle')
      - binColor: 'Blue' (Paper), 'Orange' (Plastic/Aluminium), 'Brown' (Glass), or 'Black' (General).
      - funFact: One short interesting fact about recycling this item.
      - points: Integer (10 for recyclable, 1 for non-recyclable).
    """);

    // Convert image to bytes
    final imageBytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String? text = response.text;

      if (text != null) {
        // Clean up the response just in case AI adds markdown
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(text);
      }
    } catch (e) {
      print("❌ AI Error: $e");
    }

    // Fallback if AI fails
    return {
      'itemName': 'Unknown Item',
      'binColor': 'Black',
      'funFact': 'Could not identify item.',
      'points': 0
    };
  }
}