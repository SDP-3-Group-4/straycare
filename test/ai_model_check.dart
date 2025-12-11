import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Manual parsing since dotenv depends on Flutter assets in test env sometimes
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print("FATAL: .env file not found in ${Directory.current.path}");
    return;
  }

  final lines = await envFile.readAsLines();
  String apiKey = '';

  for (var line in lines) {
    if (line.startsWith('ANVIL_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
    }
  }

  if (apiKey.isEmpty) {
    print("FATAL: ANVIL_API_KEY not found in .env");
    return;
  }

  print("Checking models with API Key: ${apiKey.substring(0, 5)}...");

  try {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    // There isn't a static listModels on GenerativeModel in 0.4.0?
    // Wait, google_generative_ai doesn't expose listModels easily in the main class?
    // Actually it usually requires a different client or it's not in the main helper.
    // Let's just try to generate content with 'gemini-1.5-flash' directly.

    print("Attempting generation with gemini-1.5-flash...");
    final response = await model.generateContent([Content.text('Hello')]);
    print("SUCCESS! gemini-1.5-flash is working. Response: ${response.text}");
  } catch (e) {
    print("FAILED with gemini-1.5-flash: $e");

    // Try gemini-pro
    try {
      print("Attempting generation with gemini-pro...");
      final modelPro = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
      final response = await modelPro.generateContent([Content.text('Hello')]);
      print("SUCCESS! gemini-pro is working.");
    } catch (e2) {
      print("FAILED with gemini-pro: $e2");
    }
  }
}
